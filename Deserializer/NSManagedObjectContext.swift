
import CoreData

extension NSManagedObjectContext {

	func object(entity: NSEntityDescription, predicate: NSPredicate) -> NSManagedObject {

		let fetchRequest = NSFetchRequest<NSManagedObject>()
		fetchRequest.entity = entity
		fetchRequest.predicate = predicate
		fetchRequest.fetchLimit = 1

		// If the fetch fails or returns no results, 
		// we create a new managed object and return 
		// that.
		guard
			let results = try? fetch(fetchRequest),
			let object = results.first
		else {
			return self.object(entity: entity)
		}

		return object
	}

	func object(entity: NSEntityDescription) -> NSManagedObject {
		return NSManagedObject(entity: entity, insertInto: self)
	}
}
