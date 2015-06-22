
import XCTest
import CoreData
import DCTManagedObjectSerialization

class PerformanceTest: XCTestCase {
    
    func testTweets() {

		self.measureBlock() {

			let bundle = NSBundle(forClass: self.dynamicType)
			guard let model = NSManagedObjectModel.mergedModelFromBundles([bundle]) else {
				XCTFail()
				return
			}

			guard let tweetsURL = bundle.URLForResource("Tweets", withExtension: "json") else {
				XCTFail()
				return
			}

			guard let data = NSData(contentsOfURL: tweetsURL) else {
				XCTFail()
				return
			}

			let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

			do {
				try persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
				let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
				managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

				let deserializer = Deserializer(managedObjectContext: managedObjectContext)

				guard let tweetsArray = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? SerializedArray else {
					XCTFail()
					return
				}

				let tweetEntity = Tweet.entityInManagedObjectContext(managedObjectContext)

//				let objects = deserializer.deserializeObjectsWithEntity(tweetEntity, fromArray: tweetsArray, existingObjectsPredicate: nil)

				deserializer.deserializeObjectsWithEntity(tweetEntity, array: tweetsArray) { objects in
					XCTAssert(objects.count == 575)
				}
//				print((objects as NSArray).componentsJoinedByString("\n\n\n"))

			} catch {
				XCTFail()
			}
		}
	}
}
