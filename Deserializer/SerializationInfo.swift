
import Foundation
import CoreData

public struct SerializationInfo {

	public init() {}
	public var uniqueAttributes = SerializationInfoStorage<NSEntityDescription,[NSAttributeDescription]>(userInfoKey: UserInfoKeys.uniqueKeys, transformer: stringToProperties)
	public var shouldDeserializeNilValues = SerializationInfoStorage<NSEntityDescription,Bool>(userInfoKey: UserInfoKeys.shouldDeserializeNilValues, transformer: stringToBool)
	public var serializationName = SerializationInfoStorage<NSPropertyDescription,String>(userInfoKey: UserInfoKeys.serializationName, transformer: stringToSerializationName)
	public var transformers = SerializationInfoStorage<NSPropertyDescription,[ValueTransformer]>(userInfoKey: UserInfoKeys.transformerNames, transformer: stringToTransformers)
	public var shouldBeUnion = SerializationInfoStorage<NSRelationshipDescription,Bool>(userInfoKey: UserInfoKeys.shouldBeUnion, transformer: stringToBool)

	private struct UserInfoKeys {
		static let uniqueKeys = "uniqueKeys"
		static let shouldDeserializeNilValues = "shouldDeserializeNilValues"
		static let serializationName = "serializationName"
		static let transformerNames = "transformerNames"
		static let shouldBeUnion = "shouldBeUnion"
	}

	private static let stringToBool: (AnyObject, String?) -> Bool = { _, string in

		guard let string = string else {
			return false
		}

		return (string as NSString).boolValue
	}

	private static let stringToProperties: (NSEntityDescription, String?) -> [NSAttributeDescription] = { entity, string in

		guard let string = string else {
			return []
		}

		let noWhiteSpaceString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		let names = noWhiteSpaceString.components(separatedBy: ",")
		let attributes = names.map { entity.attributesByName[$0] }
							  .filter { return $0 != nil } // Remove nil values
							  .map { $0! } // Force unwrap all values, as none are nil
		return attributes
	}

	private static let stringToTransformers: (NSPropertyDescription, String?) -> [ValueTransformer] = { _, string in

		guard let string = string else {
			return []
		}

		let noWhiteSpaceString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		let names = noWhiteSpaceString.components(separatedBy: ",")


		let transformers = names.map { ValueTransformer(forName: NSValueTransformerName(rawValue: $0)) } // Name to transformer
								.filter { return $0 != nil } // Remove nil values
								.map { $0! } // Force unwrap all values, as none are nil
		return transformers
	}

	private static let stringToSerializationName: (NSPropertyDescription, String?) -> String = { property, string in

		guard let string = string else {
			return property.name
		}

		return string
	}
}

// Allow for a key to be any of the types we require - NSEntityDescription, NSPropertyDescription et al
public protocol SerializationInfoStorageKey: Hashable {
	var userInfo: [AnyHashable : Any]? { get }
}
extension NSEntityDescription: SerializationInfoStorageKey {}
extension NSPropertyDescription: SerializationInfoStorageKey {}

public struct SerializationInfoStorage<Key: SerializationInfoStorageKey, Value> {

	private var values: [ Key : Value ] = [:]

	private let userInfoKey: String
	private let transformer: (Key, String?) -> Value

	fileprivate init(userInfoKey: String, transformer: @escaping (Key, String?) -> Value) {
		self.userInfoKey = userInfoKey
		self.transformer = transformer
	}

	public subscript (key: Key) -> Value {
		get {
			return valueForKey(key)
		}
		set(newValue) {
			setValue(newValue, forKey: key)
		}
	}

	public mutating func setValue(_ value: Value?, forKey key: Key) {
		values[key] = value
	}

	public func valueForKey(_ key: Key) -> Value {

		if let value = values[key] {
			return value
		}

		let string = key.userInfo?[userInfoKey] as? String
		return transformer(key, string)
	}
}
