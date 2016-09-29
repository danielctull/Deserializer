
import Foundation
import CoreData

public enum DeserializerError: Error {
	case unknown
}

public typealias SerializedDictionary = [ String : Any ]
public typealias SerializedArray = [ SerializedDictionary ]

public class Deserializer {

	public let managedObjectContext: NSManagedObjectContext
	public let serializationInfo: SerializationInfo

	public init(managedObjectContext: NSManagedObjectContext, serializationInfo: SerializationInfo = SerializationInfo()) {
		self.managedObjectContext = managedObjectContext
		self.serializationInfo = serializationInfo
	}

	public func deserialize<T>(entity: NSEntityDescription, array: SerializedArray, completion: @escaping ([T]) -> Void) {

		managedObjectContext.perform {

			let objects = self.deserialize(entity: entity, array: array)
			var typedObjects: [T] = []

			for object in objects {
				if let typedObject = object as? T {
					typedObjects.append(typedObject)
				}
			}

			do {
				try self.managedObjectContext.save()
			} catch {
				completion([])
				return
			}

			completion(typedObjects)
		}
	}

	public func deserialize<T>(entity: NSEntityDescription, dictionary: SerializedDictionary, completion: @escaping (T?) -> Void) {
		deserialize(entity: entity, array: [dictionary]) { objects in
			completion(objects.first)
		}
	}

	func deserialize(entity: NSEntityDescription, array: SerializedArray) -> [NSManagedObject] {

		var objects: [NSManagedObject] = []

		for dictionary in array {

			let predicate = entity.predicateForUniqueObject(serializedDictionary: dictionary, serializationInfo: serializationInfo)

			var object: NSManagedObject
			if let predicate = predicate {
				object = managedObjectContext.object(entity: entity, predicate: predicate)
			} else {
				object = managedObjectContext.object(entity: entity)
			}

			objects.append(object)

			for (_, attribute) in entity.attributesByName {
				let value = attribute.value(serializedDictionary: dictionary, serializationInfo: serializationInfo)
				object.set(value: value, attribute: attribute, serializationInfo: serializationInfo)
			}

			for (_, relationship) in entity.relationshipsByName {
				let value = relationship.value(serializedDictionary: dictionary, deserializer: self)
				object.set(value: value, relationship: relationship, serializationInfo: serializationInfo)
			}
		}

		return objects
	}

	func deserialize(entity: NSEntityDescription, dictionary: SerializedDictionary) -> NSManagedObject? {
		return deserialize(entity: entity, array: [dictionary]).first
	}
}
