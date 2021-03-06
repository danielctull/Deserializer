
import XCTest
import CoreData
import Deserializer
import Tweets

class SerializationInfoTests: XCTestCase {

	var managedObjectModel: NSManagedObjectModel!
	var managedObjectContext: NSManagedObjectContext!
	var serializationInfo: SerializationInfo!

	var tweetEntity: NSEntityDescription {
		return Tweet.entity(managedObjectContext)
	}
	var tweetID: NSAttributeDescription {
		return tweetEntity.attributesByName[TweetAttributes.tweetID]!
	}
	var tweetText: NSAttributeDescription {
		return tweetEntity.attributesByName[TweetAttributes.text]!
	}

	override func setUp() {
		super.setUp()

		ValueTransformer.setValueTransformer(URLTransformer(), forName: NSValueTransformerName(rawValue: "URLTransformer"))

		let bundle = Tweets.bundle()
		managedObjectModel = NSManagedObjectModel.mergedModel(from: [bundle])!
		let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

		managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
		serializationInfo = SerializationInfo()
	}

	// MARK: No Keys

	// uniqueKeys not set, returns []
	func testNoUniqueKeys() {
		let entity = Hashtag.entity(managedObjectContext)!
		let uniqueAttributes = serializationInfo.uniqueAttributes[entity]
		XCTAssertEqual(uniqueAttributes.count, 0)
	}

	// shouldDeserializeNilValues not set, returns false
	func testNoShouldDeserializeNilValues() {
		let entity = Hashtag.entity(managedObjectContext)!
		let shouldDeserializeNilValues = serializationInfo.shouldDeserializeNilValues[entity]
		XCTAssertFalse(shouldDeserializeNilValues)
	}

	// serializationName not set, returns property.name
	func testNoSerializationName() {
		let hashtagEntity = Hashtag.entity(managedObjectContext)!
		let hashtagName = hashtagEntity.attributesByName[HashtagAttributes.name]!
		let serializationName = serializationInfo.serializationName[hashtagName]
		XCTAssertEqual(serializationName, hashtagName.name)
	}

	// transformers not set, returns []
	func testNoTransformerNames() {
		let hashtagEntity = Hashtag.entity(managedObjectContext)!
		let hashtagName = hashtagEntity.attributesByName[HashtagAttributes.name]!
		let transformers = serializationInfo.transformers[hashtagName]
		XCTAssertEqual(transformers.count, 0)
	}

	// shouldBeUnion not set, returns false
	func testNoShouldBeUnion() {
		let placeEntity = Place.entity(managedObjectContext)!
		let placeTweets = placeEntity.relationshipsByName[PlaceRelationships.tweets]!
		let shouldBeUnion = serializationInfo.shouldBeUnion[placeTweets]
		XCTAssertFalse(shouldBeUnion)
	}

	// MARK: Setting Keys

	func testSettingUniqueKeys() {
		serializationInfo.uniqueAttributes[tweetEntity] = [tweetText]
		let uniqueAttributes = serializationInfo.uniqueAttributes[tweetEntity]
		XCTAssertEqual(uniqueAttributes, [tweetText])
	}

	func testSettingShouldDeserializeNilValues() {
		let entity = Tweet.entity(managedObjectContext)!
		serializationInfo.shouldDeserializeNilValues[entity] = true
		let shouldDeserializeNilValues = serializationInfo.shouldDeserializeNilValues[entity]
		XCTAssertTrue(shouldDeserializeNilValues)
	}

	func testSettingSerializationName() {
		let expectedSerializationName = "SerializationName"
		serializationInfo.serializationName[tweetID] = expectedSerializationName
		let serializationName = serializationInfo.serializationName[tweetID]
		XCTAssertEqual(serializationName, expectedSerializationName)
	}

	func testSettingTransformers() {
		let expectedTransformers = [NumberToStringValueTransformer()]
		let tweetText = tweetEntity.attributesByName[TweetAttributes.text]!
		serializationInfo.transformers[tweetText] = expectedTransformers
		let transformers = serializationInfo.transformers[tweetText]
		XCTAssertEqual(transformers, expectedTransformers)
	}

	func testSettingShouldBeUnion() {
		let userEntity = User.entity(managedObjectContext)!
		let userTweets = userEntity.relationshipsByName[UserRelationships.tweets]!
		serializationInfo.shouldBeUnion[userTweets] = true
		let shouldBeUnion = serializationInfo.shouldBeUnion[userTweets]
		XCTAssertTrue(shouldBeUnion)
	}

	// MARK: Model Defined Keys

    func testModelDefinedUniqueKeys() {
		let uniqueAttributes = serializationInfo.uniqueAttributes[tweetEntity]
		XCTAssertEqual(uniqueAttributes.count, 1)
		XCTAssertEqual(uniqueAttributes[0], tweetID)
    }

	func testModelDefinedSerializationName() {
		let serializationName = serializationInfo.serializationName[tweetID]
		XCTAssertEqual(serializationName, "id_str")
	}

	func testModelDefinedTransformers() {
		let placeEntity = Place.entity(managedObjectContext)!
		let placeURL = placeEntity.attributesByName[PlaceAttributes.placeURL]!
		let transformers = serializationInfo.transformers[placeURL]
		XCTAssertEqual(transformers.count, 1)
		XCTAssert(transformers[0] as? URLTransformer != nil)
	}

	// MARK: Cross-Context Ability

	func setupTwoContexts(_ completion: (NSManagedObjectContext, NSManagedObjectContext) -> Void ) {

		let bundle = Bundle(for: Tweet.self)
		let managedObjectModel1 = NSManagedObjectModel.mergedModel(from: [bundle])!
		let persistentStoreCoordinator1 = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel1)
		let managedObjectContext1 = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext1.persistentStoreCoordinator = persistentStoreCoordinator1

		let managedObjectModel2 = NSManagedObjectModel.mergedModel(from: [bundle])!
		let persistentStoreCoordinator2 = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel2)
		let managedObjectContext2 = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext2.persistentStoreCoordinator = persistentStoreCoordinator2

		completion(managedObjectContext1, managedObjectContext2)
	}

	func testUniqueKeysTwoContexts() {

		setupTwoContexts() { (managedObjectContext1, managedObjectContext2) in

			var serializationInfo = SerializationInfo()

			let tweetEntity1 = Tweet.entity(managedObjectContext1)!
			print(tweetEntity1.attributesByName)
			let tweetIDs1 = [tweetEntity1.attributesByName[TweetAttributes.tweetID]!]
			serializationInfo.uniqueAttributes[tweetEntity1] = tweetIDs1

			let tweetEntity2 = Tweet.entity(managedObjectContext2)!
			let tweetIDs2 = serializationInfo.uniqueAttributes[tweetEntity2]

			XCTAssert(tweetEntity1 !== tweetEntity2)
			XCTAssertEqual(tweetEntity1.hash, tweetEntity2.hash)
			XCTAssertEqual(tweetIDs1.map{ $0.name }, tweetIDs2.map{ $0.name })
		}
	}

	func testShouldDeserializeNilValuesTwoContexts() {

		setupTwoContexts() { (managedObjectContext1, managedObjectContext2) in

			var serializationInfo = SerializationInfo()

			let tweetEntity1 = Tweet.entity(managedObjectContext1)!
			serializationInfo.shouldDeserializeNilValues[tweetEntity1] = true

			let tweetEntity2 = Tweet.entity(managedObjectContext2)!
			let shouldDeserializeNilValues = serializationInfo.shouldDeserializeNilValues[tweetEntity2]

			XCTAssert(tweetEntity1 !== tweetEntity2)
			XCTAssertEqual(tweetEntity1.hash, tweetEntity2.hash)
			XCTAssertTrue(shouldDeserializeNilValues)
		}
	}

	func testSerializationNameTwoContexts() {

		setupTwoContexts() { (managedObjectContext1, managedObjectContext2) in

			var serializationInfo = SerializationInfo()

			let tweetEntity1 = Tweet.entity(managedObjectContext1)!
			let tweetID1 = tweetEntity1.attributesByName[TweetAttributes.tweetID]!
			serializationInfo.serializationName[tweetID1] = "NAME"

			let tweetEntity2 = Tweet.entity(managedObjectContext2)!
			let tweetID2 = tweetEntity2.attributesByName[TweetAttributes.tweetID]!
			let name = serializationInfo.serializationName[tweetID2]

			XCTAssert(tweetEntity1 !== tweetEntity2)
			XCTAssertEqual(tweetEntity1.hash, tweetEntity2.hash)
			XCTAssert(tweetID1 !== tweetID2)
			XCTAssertEqual(tweetID1.hash, tweetID2.hash)
			XCTAssertEqual(name, "NAME")
		}
	}

	func testTransformersTwoContexts() {

		setupTwoContexts() { (managedObjectContext1, managedObjectContext2) in

			var serializationInfo = SerializationInfo()
			let expectedTransformers = [NumberToStringValueTransformer()]

			let tweetEntity1 = Tweet.entity(managedObjectContext1)!
			let tweetID1 = tweetEntity1.attributesByName[TweetAttributes.tweetID]!
			serializationInfo.transformers[tweetID1] = expectedTransformers

			let tweetEntity2 = Tweet.entity(managedObjectContext2)!
			let tweetID2 = tweetEntity2.attributesByName[TweetAttributes.tweetID]!
			let transformers = serializationInfo.transformers[tweetID2]

			XCTAssert(tweetEntity1 !== tweetEntity2)
			XCTAssertEqual(tweetEntity1.hash, tweetEntity2.hash)
			XCTAssert(tweetID1 !== tweetID2)
			XCTAssertEqual(tweetID1.hash, tweetID2.hash)
			XCTAssertEqual(transformers, expectedTransformers)
		}
	}

	func testShouldBeUnionTwoContexts() {

		setupTwoContexts() { (managedObjectContext1, managedObjectContext2) in

			var serializationInfo = SerializationInfo()

			let userEntity1 = User.entity(managedObjectContext1)!
			let userTweets1 = userEntity1.relationshipsByName[UserRelationships.tweets]!
			serializationInfo.shouldBeUnion[userTweets1] = true

			let userEntity2 = User.entity(managedObjectContext2)!
			let userTweets2 = userEntity2.relationshipsByName[UserRelationships.tweets]!
			serializationInfo.shouldBeUnion[userTweets2] = true
			let shouldBeUnion = serializationInfo.shouldBeUnion[userTweets2]

			XCTAssert(userEntity1 !== userEntity2)
			XCTAssertEqual(userEntity1.hash, userEntity2.hash)
			XCTAssert(userTweets1 !== userTweets2)
			XCTAssertEqual(userTweets1.hash, userTweets2.hash)
			XCTAssertTrue(shouldBeUnion)
		}
	}
}
