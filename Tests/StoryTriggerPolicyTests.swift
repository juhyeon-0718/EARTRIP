import XCTest
@testable import EARTrip

final class StoryTriggerPolicyTests: XCTestCase {
    func testInvalidAccuracyNeverTriggers() {
        let policy = StoryTriggerPolicy()
        for accuracy in [-1, Double.nan, .infinity, 66] {
            XCTAssertFalse(policy.contains(distance: 0, radius: 40, accuracy: accuracy))
        }
    }
    func testBoundaryAndPaddingAreCentralized() {
        let policy = StoryTriggerPolicy()
        XCTAssertTrue(policy.contains(distance: 60, radius: 40, accuracy: 65))
        XCTAssertFalse(policy.contains(distance: 60.1, radius: 40, accuracy: 65))
        XCTAssertFalse(policy.contains(distance: 46, radius: 40, accuracy: 5))
    }
    func testDistanceIsSymmetricAndZeroAtSameCoordinate() {
        let first = Coordinate(latitude: 35, longitude: 129)
        let next = Coordinate(latitude: 35.001, longitude: 129)
        XCTAssertEqual(first.distance(to: first), 0, accuracy: 0.001)
        XCTAssertEqual(first.distance(to: next), next.distance(to: first), accuracy: 0.001)
        XCTAssertEqual(first.distance(to: next), 111.195, accuracy: 0.01)
    }
}
