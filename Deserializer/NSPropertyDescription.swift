
import CoreData

extension NSPropertyDescription {

	func transformedValue(serializedDictionary: SerializedDictionary, serializationInfo: SerializationInfo) -> Value {

		let serializationName = serializationInfo.serializationName[self]

		// If there is no value in the dictionary, return .None
		guard let serializedValue = (serializedDictionary as NSDictionary).value(forKeyPath: serializationName) else {
			return .none
		}

		var transformedValue: AnyObject? = serializedValue as AnyObject?
		let transformers = serializationInfo.transformers[self]
		for transformer in transformers {
			transformedValue = transformer.transformedValue(transformedValue) as AnyObject?
		}

		guard
			let value = transformedValue,
			!(value is NSNull)
		else {
			return .nil
		}

		if let array = value as? [AnyObject] {
			return .some(array)
		}

		return .one(value)
	}
}
