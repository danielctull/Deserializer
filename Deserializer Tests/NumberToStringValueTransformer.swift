
import Foundation

class NumberToStringValueTransformer: ValueTransformer {

	override class func transformedValueClass() -> AnyClass {
		return NSString.self
	}

	override class func allowsReverseTransformation() -> Bool {
		return false
	}

	override func transformedValue(_ value: Any?) -> Any? {

		guard let value = value as? NSNumber else {
			return nil
		}

		return value.description
	}
}
