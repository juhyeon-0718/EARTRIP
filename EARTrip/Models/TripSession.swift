import Foundation

enum TripState: String, Codable, Sendable {
    case notStarted
    case preparing
    case walking
    case storyPlaying
    case paused
    case completed
}

struct TripSession: Sendable {
    let currentCourse: Course
    var currentSpot: StorySpot?
    var nextSpot: StorySpot?
    var completedSpotIDs: Set<UUID> = []
    var currentLocation: Coordinate?
    var distanceToNextSpot: Double?
    var progress: Double = 0
    var state: TripState = .notStarted
}

struct TripRecord: Identifiable, Sendable {
    let id: UUID
    let course: Course
    let completedAt: Date
    let elapsedMinutes: Int
}

