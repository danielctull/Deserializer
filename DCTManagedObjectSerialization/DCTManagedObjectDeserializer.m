//
//  _DCTManagedObjectDeserializer.m
//  DCTManagedObjectSerialization
//
//  Created by Daniel Tull on 10.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTManagedObjectDeserializer.h"
#import "DCTManagedObjectSerialization.h"
#import "NSPropertyDescription+_DCTManagedObjectSerialization.h"
#import "NSManagedObject+DCTManagedObjectSerialization.h"

@implementation DCTManagedObjectDeserializer

- (id)initWithDictionary:(NSDictionary *)dictionary
				  entity:(NSEntityDescription *)entity
	managedObjectContext:(NSManagedObjectContext *)managedObjectContext {

	self = [self init];
	if (!self) return nil;

	_dictionary = [dictionary copy];
	_entity = entity;
	_managedObjectContext = managedObjectContext;
	
#if !__has_feature(objc_arc)
	[_entity retain];
	[_managedObjectContext retain];
#endif
	
	return self;
}

#if !__has_feature(objc_arc)
- (void)dealloc {
	
	[_dictionary release];
	[_entity release];
	[_managedObjectContext release];
	[_serializationNameToPropertyNameMapping release];
    [_errors release];
	
	[super dealloc];
}
#endif

- (id)deserializeObjectOfClass:(Class)class forKey:(NSString *)key __attribute__((nonnull(1,2)));
{
    id result = [_dictionary valueForKeyPath:key];
    
    if (result && ![result isKindOfClass:class])
    {
        [self recordError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSManagedObjectValidationError userInfo:@{
                       NSValidationObjectErrorKey : _dictionary,
                          NSValidationKeyErrorKey : key,
                        NSValidationValueErrorKey : result,
                           }]];
        
        result = nil;
    }
    
    return result;
}

- (id)deserializeProperty:(NSPropertyDescription *)property;
{
    Class class = [property deserializationClass];
    return (class ? [self deserializeObjectOfClass:class forKey:property.dct_serializationName] : nil);
}

- (NSString *)deserializeStringForKey:(NSString *)key __attribute__((nonnull(1)));
{
    return [self deserializeObjectOfClass:[NSString class] forKey:key];
}

- (NSURL *)deserializeURLForKey:(NSString *)key __attribute__((nonnull(1)));
{
    NSString *urlString = [self deserializeStringForKey:key];
    return (urlString ? [NSURL URLWithString:urlString] : nil);
}

- (BOOL)containsValueForKey:(NSString *)key __attribute__((nonnull(1)));
{
    return [_dictionary valueForKeyPath:key] != nil;
}

- (id)deserializedObject {

	NSManagedObject *managedObject = [self _existingObject];

	if (!managedObject) {
		managedObject = [[NSManagedObject alloc] initWithEntity:_entity insertIntoManagedObjectContext:_managedObjectContext];
		
#if !__has_feature(objc_arc)
		[managedObject autorelease];
#endif
	}
	
	[managedObject dct_deserialize:self];

	return managedObject;
}

- (NSManagedObject *)_existingObject {
	NSPredicate *predicate = [self _uniqueKeysPredicate];
	if (!predicate) return nil;
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:_entity.name];
	fetchRequest.predicate = predicate;
	NSArray *result = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
	return [result lastObject];
}

- (NSPredicate *)_uniqueKeysPredicate {
	NSArray *uniqueKeys = _entity.dct_serializationUniqueKeys;
	if (uniqueKeys.count == 0) return nil;
	NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:uniqueKeys.count];
	[uniqueKeys enumerateObjectsUsingBlock:^(NSString *uniqueKey, NSUInteger i, BOOL *stop) {

		NSPropertyDescription *property = [_entity.propertiesByName objectForKey:uniqueKey];

		NSAssert(property != nil, @"A unique key has been set that doesn't exist.");

		NSString *serializationName = [self _serializationNameForPropertyName:uniqueKey];
		id serializedValue = [_dictionary objectForKey:serializationName];
		id value = [property dct_valueForSerializedValue:serializedValue inManagedObjectContext:_managedObjectContext];
		if (!value) return;
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", uniqueKey, value];
		[predicates addObject:predicate];
	}];
	if (predicates.count == 0) return nil;
	return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}

#pragma mark -

- (NSString *)_serializationNameForPropertyName:(NSString *)propertyName {
	NSPropertyDescription *property = [[_entity propertiesByName] objectForKey:propertyName];
	return property.dct_serializationName;
}

- (NSString *)_propertyNameForSerializationName:(NSString *)serializationName {
	NSString *propertyName = [[self _serializationNameToPropertyNameMapping] objectForKey:serializationName];

	if (propertyName.length == 0 && [[[_entity propertiesByName] allKeys] containsObject:serializationName])
		propertyName = serializationName;

	return propertyName;
}

- (NSDictionary *)_serializationNameToPropertyNameMapping {

	if (!_serializationNameToPropertyNameMapping) {
		NSArray *properties = _entity.properties;
		NSMutableDictionary *serializationNameToPropertyNameMapping = [[NSMutableDictionary alloc] initWithCapacity:properties.count];
		[properties enumerateObjectsUsingBlock:^(NSPropertyDescription *property, NSUInteger i, BOOL *stop) {
			[serializationNameToPropertyNameMapping setObject:property.name forKey:property.dct_serializationName];
		}];
		_serializationNameToPropertyNameMapping = serializationNameToPropertyNameMapping;
	}

	return _serializationNameToPropertyNameMapping;
}

#pragma mark Error Reporting

- (void)recordError:(NSError *)error forKey:(NSString *)key;
{
    // Construct an error around the serialized state
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[error userInfo]];
    [userInfo setValue:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:[error localizedFailureReason] forKey:NSLocalizedFailureReasonErrorKey];
    [userInfo setValue:[error localizedRecoverySuggestion] forKey:NSLocalizedRecoverySuggestionErrorKey];
    
    [userInfo setObject:_dictionary forKey:NSValidationObjectErrorKey];
    [userInfo setObject:key forKey:NSValidationKeyErrorKey];
    [userInfo setValue:[_dictionary valueForKeyPath:key] forKey:NSValidationValueErrorKey];
    [userInfo setValue:error forKey:NSUnderlyingErrorKey];
    
    if (error)
    {
        error = [NSError errorWithDomain:[error domain] code:[error code] userInfo:userInfo];
    }
    else
    {
        // Fallback to generic error
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSManagedObjectValidationError userInfo:userInfo];
    }
    
    [self recordError:error];
}

- (void)recordError:(NSError *)error __attribute__((nonnull(1)));
{
    if (!_errors) _errors = [[NSMutableArray alloc] initWithCapacity:1];
    [_errors addObject:error];
}

- (NSArray *)errors;
{
    return [[_errors mutableCopy] autorelease];
}

@end
