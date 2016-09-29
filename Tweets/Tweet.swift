// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Tweet.swift instead.

import CoreData

public struct TweetAttributes {
    public static let text = "text"
    public static let tweetID = "tweetID"
}

public struct TweetRelationships {
    public static let place = "place"
    public static let user = "user"
}

public struct TweetUserInfo {
    public static let uniqueKeys = "uniqueKeys"
}

@objc public
class Tweet: NSManagedObject {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "Tweet"
    }

    public class func entity(_ managedObjectContext: NSManagedObjectContext!) -> NSEntityDescription! {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext);
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext!) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init(managedObjectContext: NSManagedObjectContext!) {
        let entity = Tweet.entity(managedObjectContext)
        self.init(entity: entity!, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var text: String?

    // func validateText(value: AutoreleasingUnsafeMutablePointer<AnyObject>, error: NSErrorPointer) -> Bool {}

    @NSManaged public
    var tweetID: String?

    // func validateTweetID(value: AutoreleasingUnsafeMutablePointer<AnyObject>, error: NSErrorPointer) -> Bool {}

    // MARK: - Relationships

    @NSManaged public
    var place: Place?

    // func validatePlace(value: AutoreleasingUnsafeMutablePointer<AnyObject>, error: NSErrorPointer) -> Bool {}

    @NSManaged public
    var user: User?

    // func validateUser(value: AutoreleasingUnsafeMutablePointer<AnyObject>, error: NSErrorPointer) -> Bool {}

}

