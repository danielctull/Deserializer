
import XCTest
import CoreData
import Deserializer

func assertOptionalEqual<T: Comparable>(_ value: T?, expected: T) {
	guard let left = value else {
		XCTFail()
		return
	}
	XCTAssertEqual(left, expected)
}

class DeserializerTests: XCTestCase {

	var managedObjectContext: NSManagedObjectContext!
	var personEntity: NSEntityDescription!
	var eventEntity: NSEntityDescription!
	var personID: NSAttributeDescription {
		return personEntity.attributesByName["personID"]!
	}

    override func setUp() {
        super.setUp()
		
		let bundle = Bundle(for: type(of: self))
		guard let model = NSManagedObjectModel.mergedModel(from: [bundle]) else {
			XCTFail()
			return
		}

		let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

		do {
			try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
			managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
			managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
			personEntity = Person.entity(managedObjectContext)
			eventEntity = Event.entity(managedObjectContext)
		} catch {
			XCTFail()
		}
    }

	func testBasicObjectCreation() {
		let expectation = self.expectation(description: "testBasicObjectCreation")
		let deserializer = Deserializer(managedObjectContext: managedObjectContext)
		deserializer.deserialize(entity: personEntity, dictionary: SerializedDictionary()) { (person: Person?) in
			XCTAssertNotNil(person)
			XCTAssertNil(person?.personID)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testObjectCreationSettingAttributeWithPropertyNameWhileNotHavingSerializationNameSet() {
		let expectation = self.expectation(description: "testObjectCreationSettingAttributeWithPropertyNameWhileNotHavingSerializationNameSet")
		let deserializer = Deserializer(managedObjectContext: managedObjectContext)
		deserializer.deserialize(entity: personEntity, dictionary: [ personID.name : "1" ]) { (person: Person?) in
			defer { expectation.fulfill() }
			XCTAssertNotNil(person)
			XCTAssertNotNil(person?.personID)
			XCTAssertEqual(person?.personID, "1")
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testObjectCreationSettingAttributeWithPropertyNameWhileHavingSerializationNameSetYetProvidingThePropertyNameInTheDictionary() {
		let expectation = self.expectation(description: "testObjectCreationSettingAttributeWithPropertyNameWhileHavingSerializationNameSetYetProvidingThePropertyNameInTheDictionary")
		var serializationInfo = SerializationInfo()
		serializationInfo.serializationName[personID] = "id"
		let deserializer = Deserializer(managedObjectContext: managedObjectContext, serializationInfo: serializationInfo)
		deserializer.deserialize(entity: personEntity, dictionary: [ personID.name : "1" ]) { (person: Person?) in
			XCTAssertNotNil(person)
			XCTAssertNil(person?.personID)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testObjectCreationSettingAttributeWithSerializationNameWhileHavingSerializationNameSet() {
		let expectation = self.expectation(description: "testObjectCreationSettingAttributeWithSerializationNameWhileHavingSerializationNameSet")
		var serializationInfo = SerializationInfo()
		serializationInfo.serializationName[personID] = "id"
		let deserializer = Deserializer(managedObjectContext: managedObjectContext, serializationInfo: serializationInfo)
		deserializer.deserialize(entity: personEntity, dictionary: [ "id" : "1" ]) { (person: Person?) in
			XCTAssertNotNil(person)
			XCTAssertEqual(person?.personID, "1")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}

	}

	func testObjectCreationSettingAttributeWithSerializationNameWhileNotHavingSerializationNameSet() {
		let expectation = self.expectation(description: "testObjectCreationSettingAttributeWithSerializationNameWhileNotHavingSerializationNameSet")
		let deserializer = Deserializer(managedObjectContext: managedObjectContext)
		deserializer.deserialize(entity: personEntity, dictionary: [ "id" : "1" ]) { (person: Person?) in
			XCTAssertNotNil(person)
			XCTAssertNil(person?.personID)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testObjectCreationSettingStringAttributeWithNumber() {
		let expectation = self.expectation(description: "testObjectCreationSettingStringAttributeWithNumber")
		var serializationInfo = SerializationInfo()
		serializationInfo.serializationName[personID] = "id"
		serializationInfo.transformers[personID] = [NumberToStringValueTransformer()]
		let deserializer = Deserializer(managedObjectContext: managedObjectContext, serializationInfo: serializationInfo)
		deserializer.deserialize(entity: personEntity, dictionary: [ "id" : 1 as AnyObject ]) { (person: Person?) in
			XCTAssertNotNil(person)
			XCTAssertEqual(person?.personID, "1")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testObjectDuplication() {
		let expectation = self.expectation(description: "testObjectDuplication")
		var serializationInfo = SerializationInfo()
		serializationInfo.uniqueAttributes[personEntity] = [personID]
		let deserializer = Deserializer(managedObjectContext: managedObjectContext, serializationInfo: serializationInfo)
		let dictionary = [ personID.name : "1" ]
		deserializer.deserialize(entity: personEntity, dictionary: dictionary) { (person1: Person?) in
			deserializer.deserialize(entity: self.personEntity, dictionary: dictionary) { (person2: Person?) in
				XCTAssertNotNil(person1)
				XCTAssertNotNil(person2)
				XCTAssertEqual(person1, person2)
				expectation.fulfill()
			}
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testObjectDuplicationNotSame() {
		let expectation = self.expectation(description: "testObjectDuplicationNotSame")
		var serializationInfo = SerializationInfo()
		serializationInfo.uniqueAttributes[personEntity] = [personID]
		let deserializer = Deserializer(managedObjectContext: managedObjectContext, serializationInfo: serializationInfo)
		deserializer.deserialize(entity: personEntity, dictionary: [ personID.name : "1" ]) { (person1: Person?) in
			deserializer.deserialize(entity: self.personEntity, dictionary: [ "id" : "1" ]) { (person2: Person?) in
				XCTAssertNotNil(person1)
				XCTAssertNotNil(person2)
				XCTAssertNotEqual(person1, person2)
				expectation.fulfill()
			}
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testObjectDuplicationNotSame2() {
		let expectation = self.expectation(description: "testObjectDuplicationNotSame2")
		var serializationInfo = SerializationInfo()
		serializationInfo.uniqueAttributes[personEntity] = [personID]
		let deserializer = Deserializer(managedObjectContext: managedObjectContext, serializationInfo: serializationInfo)
		deserializer.deserialize(entity: personEntity, dictionary: [ personID.name : "1" ]) { (person1: Person?) in
			deserializer.deserialize(entity: self.personEntity, dictionary: [ self.personID.name : "2" ]) { (person2: Person?) in
				XCTAssertNotNil(person1)
				XCTAssertNotNil(person2)
				XCTAssertNotEqual(person1, person2)
				expectation.fulfill()
			}
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testObjectDuplication2() {
		let expectation = self.expectation(description: "testObjectDuplication2")
		let deserializer = Deserializer(managedObjectContext: managedObjectContext)
		deserializer.deserialize(entity: personEntity, dictionary: [ personID.name : "1" ]) { (person1: Person?) in
			deserializer.deserialize(entity: self.personEntity, dictionary: [ self.personID.name : "2" ]) { (person2: Person?) in
				XCTAssertNotNil(person1)
				XCTAssertNotNil(person2)
				XCTAssertNotEqual(person1, person2)
				expectation.fulfill()
			}
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testObjectDuplication3() {
		let expectation = self.expectation(description: "testObjectDuplication3")
		var serializationInfo = SerializationInfo()
		serializationInfo.serializationName[personID] = "id"
		serializationInfo.uniqueAttributes[personEntity] = [personID]
		let deserializer = Deserializer(managedObjectContext: managedObjectContext, serializationInfo: serializationInfo)
		deserializer.deserialize(entity: personEntity, dictionary: [ "id" : "1" ]) { (person1: Person?) in
			deserializer.deserialize(entity: self.personEntity, dictionary: [ "id" : "1" ]) { (person2: Person?) in
				XCTAssertNotNil(person1)
				XCTAssertNotNil(person2)
				XCTAssertEqual(person1, person2)
				expectation.fulfill()
			}
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testObjectKeypath() {
		let expectation = self.expectation(description: "testObjectKeypath")
		var serializationInfo = SerializationInfo()
		serializationInfo.serializationName[personID] = "id.string"
		serializationInfo.uniqueAttributes[personEntity] = [personID]
		let deserializer = Deserializer(managedObjectContext: managedObjectContext, serializationInfo: serializationInfo)
		deserializer.deserialize(entity: personEntity, dictionary: [ "id" : [ "string" : "1"]]) { (person: Person?) in
			XCTAssertNotNil(person)
			XCTAssertEqual(person?.personID, "1")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	// MARK: Relationships

	func testRelationship() {
		let expectation = self.expectation(description: "testRelationship")
		let deserializer = Deserializer(managedObjectContext: managedObjectContext)
		let dictionary = [ personID.name : "1", PersonRelationships.events : [[ EventAttributes.name : "Party!" ]] ] as [String : Any]
		deserializer.deserialize(entity: personEntity, dictionary: dictionary) { (person: Person?) in
			XCTAssertNotNil(person)
			XCTAssertEqual(person?.personID, "1")
			XCTAssertEqual(person?.events.count, 1)
			XCTAssertEqual(person?.events.first?.name, "Party!")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testRelationship2() {
		let expectation = self.expectation(description: "testRelationship2")
		let deserializer = Deserializer(managedObjectContext: managedObjectContext)
		let dictionary = [ EventAttributes.name : "Party!", EventRelationships.person : [ PersonAttributes.personID : "1" ] ] as [String : Any]
		deserializer.deserialize(entity: eventEntity, dictionary: dictionary) { (event: Event?) in
			XCTAssertNotNil(event)
			XCTAssertEqual(event?.name, "Party!")
			XCTAssertEqual(event?.person?.events.count, 1)
			XCTAssertEqual(event?.person?.personID, "1")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

	func testRelationshipDuplicate() {
		let expectation = self.expectation(description: "testRelationship2")
		var serializationInfo = SerializationInfo()
		serializationInfo.uniqueAttributes[personEntity] = [personID]
		let deserializer = Deserializer(managedObjectContext: managedObjectContext, serializationInfo: serializationInfo)
		let personDictionary = [ PersonAttributes.personID : "1" ]
		let event1Dictionary: SerializedDictionary = [ EventAttributes.name : "Party 1!", EventRelationships.person : personDictionary ]
		let event2Dictionary: SerializedDictionary = [ EventAttributes.name : "Party 2!", EventRelationships.person : personDictionary ]
		let array = [ event1Dictionary, event2Dictionary ]
		deserializer.deserialize(entity: eventEntity, array: array) { (events: [Event]) in
			XCTAssertEqual(events.count, 2)
			let event1 = events[0]
			let event2 = events[1]
			XCTAssertEqual(event1.name, "Party 1!")
			XCTAssertEqual(event2.name, "Party 2!")
			XCTAssertEqual(event1.person?.personID, "1")
			XCTAssertEqual(event2.person?.personID, "1")
			XCTAssertEqual(event1.person, event2.person)
			expectation.fulfill()
		}

		waitForExpectations(timeout: 30) { error in
			XCTAssertNil(error)
		}
	}

}
