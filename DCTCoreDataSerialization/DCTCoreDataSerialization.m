//
//  DCTCoreDataSerialization.m
//  DCTCoreDataSerialization
//
//  Created by Daniel Tull on 10/11/2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTCoreDataSerialization.h"
#import "NSManagedObject+DCTAutomatedSetup.h"

@implementation DCTCoreDataSerialization

+ (NSManagedObject *)objectFromDictionary:(NSDictionary *)dictionary
							   rootEntity:(NSEntityDescription *)entity
					 managedObjectContext:(NSManagedObjectContext *)managedObjectContext {

	Class managedObjectClass = NSClassFromString([entity managedObjectClassName]);

	if (![managedObjectClass conformsToProtocol:@protocol(DCTManagedObjectAutomatedSetup)]) return nil;
	
	return [managedObjectClass dct_objectFromDictionary:dictionary insertIntoManagedObjectContext:managedObjectContext];
}

@end
