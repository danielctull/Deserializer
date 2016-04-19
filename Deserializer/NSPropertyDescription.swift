
import CoreData

extension NSPropertyDescription {

	func transformedValue(serializedDictionary serializedDictionary: SerializedDictionary, serializationInfo: SerializationInfo) -> Value{

		let serializationName = serializationInfo.serializationName[self]

		// If there is no value in the dictionary, return .None
		guard let serializedValue = (serializedDictionary as NSDictionary).valueForKeyPath(serializationName) else {
			return .None
		}

		var transformedValue: AnyObject? = serializedValue
		let transformers = serializationInfo.transformers[self]
		for transformer in transformers {
			transformedValue = transformer.transformedValue(transformedValue)
		}

		guard
			let value = transformedValue
			where !(value is NSNull)
		else {
			return .Nil
		}

		if let array = value as? [AnyObject] {
			return .Some(array)
		}

		return .One(value)
	}
}
