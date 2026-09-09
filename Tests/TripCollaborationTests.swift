import XCTest
@testable import EARTrip

@MainActor
final class TripCollaborationTests: XCTestCase {
    func testPlaybackCommandsKeepTripAndAudioInSync() async {
        let audio = FakeStoryAudio()
        let engine = TripEngine(locationService: FakeTripLocation(), audioService: audio)
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()
        let played = expectation(description: "played")
        audio.playExpectation = played
        engine.triggerCurrentStoryForDemo()
        await fulfillment(of: [played], timeout: 1)
        audio.playExpectation = nil
        let first = MockCatalog.jagalchi.spots[0]
        engine.togglePlayback(for: first)
        XCTAssertFalse(audio.isPlaying)
        XCTAssertEqual(engine.session?.state, .paused)
        engine.togglePlayback(for: first)
        XCTAssertTrue(audio.isPlaying)
        XCTAssertEqual(engine.session?.state, .storyPlaying)
        engine.togglePlayback(for: MockCatalog.jagalchi.spots[1])
        XCTAssertTrue(audio.isPlaying, "A different detail screen must not control this story")
        engine.endTrip()
    }

    func testCompletionRecordsOncePerSessionWithoutOpeningAView() {
        let history = TripHistoryStore()
        let audio = FakeStoryAudio()
        var time = Date(timeIntervalSince1970: 1_000)
        let engine = TripEngine(locationService: FakeTripLocation(), audioService: audio,
                                history: history, now: { time })
        for _ in 0..<2 {
            engine.prepare(course: MockCatalog.jagalchi)
            engine.start()
            time = time.addingTimeInterval(125)
            for _ in MockCatalog.jagalchi.spots {
                engine.triggerCurrentStoryForDemo()
                engine.completeCurrentStory()
            }
            engine.completeCurrentStory()
            XCTAssertEqual(engine.session?.state, .completed)
        }
        XCTAssertEqual(history.records.count, 2, "Revisiting the same course is a new trip")
        XCTAssertTrue(history.records.allSatisfy { $0.elapsedMinutes == 2 })
        XCTAssertNotEqual(history.records[0].id, history.records[1].id)
    }

    func testEndingDuringLoadCannotPlayAfterCancellation() async {
        let audio = FakeStoryAudio()
        audio.suspendLoad = true
        let loaded = expectation(description: "load started")
        audio.loadExpectation = loaded
        let engine = TripEngine(locationService: FakeTripLocation(), audioService: audio)
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()
        engine.triggerCurrentStoryForDemo()
        await fulfillment(of: [loaded], timeout: 1)
        engine.endTrip()
        let mustNotPlay = expectation(description: "cancelled load never plays")
        mustNotPlay.isInverted = true
        audio.playExpectation = mustNotPlay
        audio.releaseLoad()
        await fulfillment(of: [mustNotPlay], timeout: 0.1)
        XCTAssertNil(engine.session)
        XCTAssertFalse(audio.isPlaying)
        XCTAssertEqual(audio.playCount, 0)
    }

    func testPlaybackFailureCanBeRetriedWithoutCompletingStory() async {
        let audio = FakeStoryAudio()
        audio.failLoad = true
        let engine = TripEngine(locationService: FakeTripLocation(), audioService: audio)
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()
        let stopped = expectation(description: "failed load stopped")
        audio.stopExpectation = stopped
        engine.triggerCurrentStoryForDemo()
        await fulfillment(of: [stopped], timeout: 1)
        audio.stopExpectation = nil
        XCTAssertEqual(engine.session?.state, .paused)
        XCTAssertNotNil(engine.playbackError)
        XCTAssertTrue(engine.session?.completedSpotIDs.isEmpty == true)
        audio.failLoad = false
        let played = expectation(description: "retry played")
        audio.playExpectation = played
        engine.resumeStory()
        await fulfillment(of: [played], timeout: 1)
        XCTAssertNil(engine.playbackError)
        engine.endTrip()
    }

    func testDelayedCompletionForOtherStoryIsIgnored() {
        let audio = FakeStoryAudio()
        let engine = TripEngine(locationService: FakeTripLocation(), audioService: audio)
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()
        engine.triggerCurrentStoryForDemo()
        engine.completeCurrentStory()
        engine.triggerCurrentStoryForDemo()
        audio.onPlaybackCompleted?(MockCatalog.jagalchi.spots[0].id)
        XCTAssertEqual(engine.session?.completedSpotIDs.count, 1)
        XCTAssertEqual(engine.session?.currentSpot?.order, 2)
        engine.endTrip()
    }
}
