
import CoreData

extension NSManagedObjectContext {

	func object(entity: NSEntityDescription, predicate: NSPredicate) -> NSManagedObject {

		let fetchRequest = NSFetchRequest<NSManagedObject>()
		fetchRequest.entity = entity
		fetchRequest.predicate = predicate
		fetchRequest.fetchLimit = 1

		do {
			let results = try fetch(fetchRequest)
			guard let object = results.first else {
				throw DeserializerError.unknown
			}
			return object

		} catch {
			return object(entity: entity)
		}
	}

	func object(entity: NSEntityDescription) -> NSManagedObject {
		return NSManagedObject(entity: entity, insertInto: self)
	}
}
