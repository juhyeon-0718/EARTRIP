import Foundation

struct Course: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let city: String
    let title: String
    let subtitle: String
    let description: String
    let coverImage: String?
    let distanceKilometers: Double
    let estimatedDurationMinutes: Int
    let price: Decimal
    let startingCoordinate: Coordinate
    let spots: [StorySpot]

    func story(after story: StorySpot) -> StorySpot? {
        guard story.courseID == id, spots.contains(where: { $0.id == story.id }) else { return nil }
        return spots.filter { $0.courseID == id && $0.order > story.order }
            .min(by: { $0.order < $1.order })
    }
}

struct StorySpot: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let courseID: UUID
    let order: Int
    let title: String
    let subtitle: String
    let description: String
    let coordinate: Coordinate
    let triggerRadius: Double
    let audioURL: URL?
    let localAudioURL: URL?
    let duration: TimeInterval
    let image: String?
}
