// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to User.swift instead.

import CoreData

public struct UserAttributes {
    public static let name = "name"
    public static let userID = "userID"
    public static let username = "username"
}

public struct UserRelationships {
    public static let tweets = "tweets"
}

public struct UserUserInfo {
    public static let uniqueKeys = "uniqueKeys"
}

@objc public
class User: NSManagedObject {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "User"
    }

    public class func entity(_ managedObjectContext: NSManagedObjectContext!) -> NSEntityDescription! {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext);
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext!) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init(managedObjectContext: NSManagedObjectContext!) {
        let entity = User.entity(managedObjectContext)
        self.init(entity: entity!, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var name: String?

    // func validateName(value: AutoreleasingUnsafeMutablePointer<AnyObject>, error: NSErrorPointer) -> Bool {}

    @NSManaged public
    var userID: String?

    // func validateUserID(value: AutoreleasingUnsafeMutablePointer<AnyObject>, error: NSErrorPointer) -> Bool {}

    @NSManaged public
    var username: String?

    // func validateUsername(value: AutoreleasingUnsafeMutablePointer<AnyObject>, error: NSErrorPointer) -> Bool {}

    // MARK: - Relationships

    @NSManaged public
    var tweets: NSSet

}

extension User {

    func addTweets(_ objects: NSSet) {
        let mutable = self.tweets.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.tweets = mutable.copy() as! NSSet
    }

    func removeTweets(_ objects: NSSet) {
        let mutable = self.tweets.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.tweets = mutable.copy() as! NSSet
    }

    func addTweetsObject(_ value: Tweet!) {
        let mutable = self.tweets.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.tweets = mutable.copy() as! NSSet
    }

    func removeTweetsObject(_ value: Tweet!) {
        let mutable = self.tweets.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.tweets = mutable.copy() as! NSSet
    }

}

