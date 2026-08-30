import XCTest
@testable import EARTrip

@MainActor
final class LocationServiceTests: XCTestCase {
    func testDistanceToSameCoordinateIsZero() {
        let coordinate = Coordinate(latitude: 35.09679, longitude: 129.03053)
        XCTAssertEqual(LocationService.distance(from: coordinate, to: coordinate), 0, accuracy: 0.001)
    }

    func testJagalchiSpotsHaveEditableDistinctCoordinates() {
        let coordinates = Set(MockCatalog.jagalchi.spots.map(\.coordinate))
        XCTAssertEqual(coordinates.count, 5)
    }
}
