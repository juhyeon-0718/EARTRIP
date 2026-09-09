import Foundation

enum AppRoute: Hashable {
    case course(Course)
    case preparation(Course)
    case live
    case story(StorySpot, course: Course)
    case complete(Course)
}
