
import XCTest
import CoreData
import Deserializer
import Tweets

class PerformanceTest: XCTestCase {
    
    func testTweets() {
		measure() {
			let expectation = self.expectation(description: "Tweets")
			Tweets.importTweets { tweets in
				XCTAssert(tweets.count == 575)
				expectation.fulfill()
			}
			self.waitForExpectations(timeout: 30) { error in
				XCTAssertNil(error)
			}
		}
	}
}
