import XCTest
@testable import EARTrip

final class CourseContentTests: XCTestCase {
    func testNextStoryStaysInSelectedCourseAndSupportsOrderGaps() {
        let courseID = UUID()
        let first = spot(courseID: courseID, order: 2)
        let next = spot(courseID: courseID, order: 7)
        let foreign = spot(courseID: UUID(), order: 3)
        let course = Course(id: courseID, city: "서울", title: "테스트 여행", subtitle: "", description: "",
                            coverImage: nil, distanceKilometers: 1, estimatedDurationMinutes: 20,
                            price: 0, startingCoordinate: first.coordinate, spots: [next, foreign, first])
        XCTAssertEqual(course.story(after: first)?.id, next.id)
        XCTAssertNil(course.story(after: next))
        XCTAssertNil(course.story(after: foreign))
        XCTAssertNil(course.coverImage)
        XCTAssertEqual(course.city, "서울")
    }

    private func spot(courseID: UUID, order: Int) -> StorySpot {
        StorySpot(id: UUID(), courseID: courseID, order: order, title: "테스트 이야기", subtitle: "",
                  description: "", coordinate: .init(latitude: 37.57, longitude: 126.98),
                  triggerRadius: 45, audioURL: nil, localAudioURL: nil, duration: 60, image: nil)
    }
}
