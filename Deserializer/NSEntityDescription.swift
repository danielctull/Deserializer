
import CoreData

extension NSEntityDescription {

	func predicateForUniqueObject(serializedDictionary: SerializedDictionary, serializationInfo: SerializationInfo) -> NSPredicate? {

		let uniqueAttributes = serializationInfo.uniqueAttributes[self]
		var predicates: [NSPredicate] = []

		for attribute in uniqueAttributes {

			let value = attribute.value(serializedDictionary: serializedDictionary, serializationInfo: serializationInfo)
			let predicate: NSPredicate

			switch value {
				case .nil: predicate = NSPredicate(format: "%K == nil", argumentArray: [attribute.name])
				case .none: continue
				case .one(let object): predicate = NSPredicate(format: "%K == %@", argumentArray: [attribute.name, object])
				case .some(let object): predicate = NSPredicate(format: "%K == %@", argumentArray: [attribute.name, object])
			}

			predicates.append(predicate)
		}

		guard predicates.count > 0 else {
			return nil
		}

		return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
	}
}
