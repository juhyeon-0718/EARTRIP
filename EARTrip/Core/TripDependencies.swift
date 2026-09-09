import Foundation

/// Hardware boundaries owned by the trip application layer.
/// Views never receive these command interfaces.
@MainActor
protocol TripLocationSource: AnyObject {
    var coordinate: Coordinate? { get }
    var horizontalAccuracy: Double? { get }
    var onLocationUpdate: ((Coordinate, Double) -> Void)? { get set }
    func startUpdating()
    func stopUpdating()
}

@MainActor
protocol StoryAudioPlayer: AnyObject {
    var currentStory: StorySpot? { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var isPlaying: Bool { get }
    /// Identity prevents delayed events from completing a different story.
    var onPlaybackCompleted: ((UUID) -> Void)? { get set }
    func load(_ story: StorySpot) async throws
    func play()
    func pause()
    func stop()
    func seek(to seconds: TimeInterval)
}
