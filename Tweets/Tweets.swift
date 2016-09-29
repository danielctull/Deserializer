
import Deserializer
import Foundation
import CoreData


public class Tweets {

	public static func bundle() -> Bundle {
		return Bundle(for: self)
	}

	public static func importTweets(_ completion: @escaping ([Tweet]) -> Void) {

		let queue = DispatchQueue(label: "Tweets", attributes: [])
		queue.async {

			let bundle = self.bundle()
			guard let model = NSManagedObjectModel.mergedModel(from: [bundle]) else {
				return
			}

			guard let tweetsURL = bundle.url(forResource: "Tweets", withExtension: "json") else {
				return
			}

			guard let data = try? Data(contentsOf: tweetsURL) else {
				return
			}

			let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

			do {
				try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
				let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
				managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

				let deserializer = Deserializer(managedObjectContext: managedObjectContext)

				guard let tweetsArray = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? SerializedArray else {
					return
				}

				let tweetEntity = Tweet.entity(managedObjectContext)!
				deserializer.deserialize(entity: tweetEntity, array: tweetsArray, completion: completion)

			} catch {}
		}
	}
}
