import Foundation
import XCTest
@testable import EARTrip

@MainActor
final class FakeTripLocation: TripLocationSource {
    var coordinate: Coordinate?
    var horizontalAccuracy: Double?
    var onLocationUpdate: ((Coordinate, Double) -> Void)?
    private(set) var isUpdating = false
    func startUpdating() { isUpdating = true }
    func stopUpdating() { isUpdating = false }
    func send(_ coordinate: Coordinate, accuracy: Double = 5) {
        self.coordinate = coordinate
        horizontalAccuracy = accuracy
        onLocationUpdate?(coordinate, accuracy)
    }
}

@MainActor
final class FakeStoryAudio: StoryAudioPlayer {
    var currentStory: StorySpot?
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 60
    var isPlaying = false
    var onPlaybackCompleted: ((UUID) -> Void)?
    var playExpectation: XCTestExpectation?
    var stopExpectation: XCTestExpectation?
    var loadExpectation: XCTestExpectation?
    var failLoad = false
    var suspendLoad = false
    private var continuation: CheckedContinuation<Void, Error>?
    private(set) var playCount = 0

    func load(_ story: StorySpot) async throws {
        currentStory = story
        loadExpectation?.fulfill()
        if suspendLoad { try await withCheckedThrowingContinuation { continuation = $0 } }
        if failLoad { throw URLError(.notConnectedToInternet) }
    }
    func releaseLoad() { continuation?.resume(); continuation = nil }
    func play() { playCount += 1; isPlaying = true; playExpectation?.fulfill() }
    func pause() { isPlaying = false }
    func stop() { isPlaying = false; currentStory = nil; currentTime = 0; stopExpectation?.fulfill() }
    func seek(to seconds: TimeInterval) { currentTime = min(max(seconds, 0), duration) }
}
