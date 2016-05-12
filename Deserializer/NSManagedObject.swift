
import CoreData

extension NSManagedObject {

	func set(value value: Value, attribute: NSAttributeDescription, serializationInfo: SerializationInfo) {

		switch value {

			case .None: break
			case .Some: break

			case .Nil:
				if attribute.optional && serializationInfo.shouldDeserializeNilValues[entity] {
					setValue(nil, forKey: attribute.name)
				}

			case .One(let object):
				validateAndSetValue(object, forAttribute: attribute)
		}
	}

	private func validateAndSetValue(value: AnyObject, forAttribute attribute: NSAttributeDescription) {

		// TYPE VALIDATION

		guard
			let object = value as? NSObject
			where validateType(object: object, forAttribute: attribute)
		else {
			let entityName = entity.name ?? "Unknown Entity" // Unlikely to happen
			let desiredType = attribute.attributeValueClassName ?? "Unknown Type"
			print("[Deserializer] Unacceptable type of value for attribute: entity = \(entityName); property = \(attribute.name); desired type = \(desiredType); given type = \(value.dynamicType); value = \(value)")
			return
		}

		// STANDARD VALIDATION

		guard
			validate(value: value, forAttribute: attribute)
		else {
			let entityName = entity.name ?? "Unknown Entity"
			print("[Deserializer] Failed validation of value for attribute: entity = \(entityName); property = \(attribute.name); type = \(value.dynamicType); value = \(value)")
			return
		}

		setValue(value, forKey: attribute.name)
	}

	private func validate(value value: AnyObject, forAttribute attribute: NSAttributeDescription) -> Bool {

		do {
			var v: AnyObject? = value
			try validateValue(&v, forKey: attribute.name)
			return true
		} catch {
			return false
		}
	}

	private func validateType(object object: NSObject, forAttribute attribute: NSAttributeDescription) -> Bool {

		// If there's no attributeValueClassName, the type is likely transformable.
		// Either way we can't provide any further validation.
		guard
			let attributeClassName = attribute.attributeValueClassName,
			let attributeClass = NSClassFromString(attributeClassName)
		else {
			return true
		}

		return object.isKindOfClass(attributeClass)
	}

	func set(value value: Value, relationship: NSRelationshipDescription, serializationInfo: SerializationInfo) {

		switch value {

			case .None: break

			case .Nil:
				if serializationInfo.shouldDeserializeNilValues[entity] {
					setValue(nil, forKey: relationship.name)
				}

			case .One(let object):
				if !relationship.toMany {
					setValue(object, forKey: relationship.name)
				}

			case .Some(let objects):
				if relationship.toMany {

					if serializationInfo.shouldBeUnion[relationship] {

						if relationship.ordered {
							let set = mutableOrderedSetValueForKey(relationship.name)
							set.addObjectsFromArray(objects)
						} else {
							let set = mutableSetValueForKey(relationship.name)
							set.addObjectsFromArray(objects)
						}

					} else {

						if relationship.ordered {
							setValue(NSOrderedSet(array: objects), forKey: relationship.name)
						} else {
							setValue(NSSet(array: objects), forKey: relationship.name)
						}
					}
				}
		}
	}
}
