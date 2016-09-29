
import CoreData

extension NSManagedObject {

	func set(value: Value, attribute: NSAttributeDescription, serializationInfo: SerializationInfo) {

		switch value {

			case .none: break
			case .some: break

			case .nil:
				if attribute.isOptional && serializationInfo.shouldDeserializeNilValues[entity] {
					setValue(nil, forKey: attribute.name)
				}

			case .one(let object):
				validateAndSetValue(object, forAttribute: attribute)
		}
	}

	private func validateAndSetValue(_ value: AnyObject, forAttribute attribute: NSAttributeDescription) {

		// TYPE VALIDATION

		guard
			let object = value as? NSObject,
			validateType(object: object, forAttribute: attribute)
		else {
			let entityName = entity.name ?? "Unknown Entity" // Unlikely to happen
			let desiredType = attribute.attributeValueClassName ?? "Unknown Type"
			print("[Deserializer] Unacceptable type of value for attribute: entity = \(entityName); property = \(attribute.name); desired type = \(desiredType); given type = \(type(of: value)); value = \(value)")
			return
		}

		// STANDARD VALIDATION

		guard
			validate(value: value, forAttribute: attribute)
		else {
			let entityName = entity.name ?? "Unknown Entity"
			print("[Deserializer] Failed validation of value for attribute: entity = \(entityName); property = \(attribute.name); type = \(type(of: value)); value = \(value)")
			return
		}

		setValue(value, forKey: attribute.name)
	}

	private func validate(value: AnyObject, forAttribute attribute: NSAttributeDescription) -> Bool {

		do {
			var v: AnyObject? = value
			try validateValue(&v, forKey: attribute.name)
			return true
		} catch {
			return false
		}
	}

	private func validateType(object: NSObject, forAttribute attribute: NSAttributeDescription) -> Bool {

		// If there's no attributeValueClassName, the type is likely transformable.
		// Either way we can't provide any further validation.
		guard
			let attributeClassName = attribute.attributeValueClassName,
			let attributeClass = NSClassFromString(attributeClassName)
		else {
			return true
		}

		return object.isKind(of: attributeClass)
	}

	func set(value: Value, relationship: NSRelationshipDescription, serializationInfo: SerializationInfo) {

		switch value {

			case .none: break

			case .nil:
				if serializationInfo.shouldDeserializeNilValues[entity] {
					setValue(nil, forKey: relationship.name)
				}

			case .one(let object):
				if !relationship.isToMany {
					setValue(object, forKey: relationship.name)
				}

			case .some(let objects):
				if relationship.isToMany {

					if serializationInfo.shouldBeUnion[relationship] {

						if relationship.isOrdered {
							let set = mutableOrderedSetValue(forKey: relationship.name)
							set.addObjects(from: objects)
						} else {
							let set = mutableSetValue(forKey: relationship.name)
							set.addObjects(from: objects)
						}

					} else {

						if relationship.isOrdered {
							setValue(NSOrderedSet(array: objects), forKey: relationship.name)
						} else {
							setValue(NSSet(array: objects), forKey: relationship.name)
						}
					}
				}
		}
	}
}
