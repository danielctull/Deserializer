
import Foundation
import CoreData

extension NSRelationshipDescription {

	func value(serializedDictionary: SerializedDictionary, deserializer: Deserializer) -> Value {

		// If there is no detination entity return .None
		guard let destinationEntity = destinationEntity else {
			return .none
		}

		let value = transformedValue(serializedDictionary: serializedDictionary, serializationInfo: deserializer.serializationInfo)

		switch value {
			case .nil: return .nil
			case .none: return .none

			case .some(let objects):

				guard
					let array = objects as? SerializedArray,
					isToMany
				else {
					return .none
				}

				let objects = deserializer.deserialize(entity: destinationEntity, array: array)
				return .some(objects)

			case .one(let object):

				guard
					let dictionary = object as? SerializedDictionary,
					!isToMany,
					let object = deserializer.deserialize(entity: destinationEntity, dictionary: dictionary)
				else {
					return .none
				}

				return .one(object)
		}
	}
}
