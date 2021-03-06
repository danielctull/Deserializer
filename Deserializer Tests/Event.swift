// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.swift instead.

import CoreData

public struct EventAttributes {
    static let name = "name"
}

public struct EventRelationships {
    static let person = "person"
}

@objc public
class Event: NSManagedObject {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "Event"
    }

    public class func entity(_ managedObjectContext: NSManagedObjectContext!) -> NSEntityDescription! {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext);
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext!) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init(managedObjectContext: NSManagedObjectContext!) {
        let entity = Event.entity(managedObjectContext)
        self.init(entity: entity!, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var name: String?

    // func validateName(value: AutoreleasingUnsafeMutablePointer<AnyObject>, error: NSErrorPointer) -> Bool {}

    // MARK: - Relationships

    @NSManaged public
    var person: Person?

    // func validatePerson(value: AutoreleasingUnsafeMutablePointer<AnyObject>, error: NSErrorPointer) -> Bool {}

}

