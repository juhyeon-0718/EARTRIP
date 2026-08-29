import SwiftUI

extension View {
    func earTripDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .course(let course): CourseDetailView(course: course)
            case .preparation(let course): TripPreparationView(course: course)
            case .live: LiveTripView()
            case .story(let story): StoryDetailView(story: story)
            case .complete(let course): TripCompleteView(course: course)
            }
        }
    }
}
