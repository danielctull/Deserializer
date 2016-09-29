
import CoreData

extension NSAttributeDescription {

	func value(serializedDictionary: SerializedDictionary, serializationInfo: SerializationInfo) -> Value {

		let x = transformedValue(serializedDictionary: serializedDictionary, serializationInfo: serializationInfo)

		let value: AnyObject
		switch x {
			case .nil: return .nil
			case .none: return .none
			case .one(let v): value = v
			case .some(let v): value = v as AnyObject
		}

		// If it's not valid return .None
		let validationPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: validationPredicates)
		guard validationPredicate.evaluate(with: value) else {
			return .none
		}

		return x
	}
}
