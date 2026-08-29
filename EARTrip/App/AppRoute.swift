import Foundation

enum AppRoute: Hashable {
    case course(Course)
    case preparation(Course)
    case live
    case story(StorySpot)
    case complete(Course)
}

