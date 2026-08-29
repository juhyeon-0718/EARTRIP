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

