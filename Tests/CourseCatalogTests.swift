import XCTest
@testable import EARTrip

@MainActor
final class CourseCatalogTests: XCTestCase {
    func testCatalogIsInjectedAndDoesNotInventAvailableCourses() {
        let catalog = CourseCatalog(courses: [MockCatalog.jagalchi], cities: ["서울", "부산", "부산"])
        XCTAssertEqual(catalog.cities, ["서울", "부산"])
        XCTAssertTrue(catalog.courses(in: "서울").isEmpty)
        XCTAssertEqual(catalog.courses(in: "부산").count, 1)
        XCTAssertTrue(CourseCatalog(courses: []).cities.isEmpty)
    }
}
