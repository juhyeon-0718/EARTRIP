import XCTest
@testable import EARTrip

@MainActor
final class TripEngineTests: XCTestCase {
    func testPausedTripDoesNotTriggerAndResumeUsesLatestLocation() {
        let location = FakeTripLocation()
        let engine = TripEngine(locationService: location, audioService: FakeStoryAudio())
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()
        engine.pauseTrip()
        location.send(MockCatalog.jagalchi.spots[0].coordinate)
        XCTAssertNil(engine.session?.currentSpot)
        XCTAssertEqual(engine.session?.state, .paused)
        engine.resumeTrip()
        XCTAssertEqual(engine.session?.state, .loadingStory)
        engine.endTrip()
    }

    func testEndingTripPreventsPendingPlayback() async {
        let audio = FakeStoryAudio()
        let engine = TripEngine(locationService: FakeTripLocation(), audioService: audio)
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()
        engine.triggerCurrentStoryForDemo()
        engine.endTrip()
        await Task.yield()
        XCTAssertNil(engine.session)
        XCTAssertFalse(audio.isPlaying)
    }

    func testPrepareSelectsFirstStory() {
        let location = FakeTripLocation()
        let audio = FakeStoryAudio()
        let engine = TripEngine(locationService: location, audioService: audio)

        engine.prepare(course: MockCatalog.jagalchi)

        XCTAssertEqual(engine.session?.state, .preparing)
        XCTAssertEqual(engine.session?.nextSpot?.order, 1)
    }

    func testStoryCannotCompleteTwice() async {
        let location = FakeTripLocation()
        let audio = FakeStoryAudio()
        let engine = TripEngine(locationService: location, audioService: audio)
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()
        engine.triggerCurrentStoryForDemo()
        await Task.yield()

        engine.completeCurrentStory()
        engine.completeCurrentStory()

        XCTAssertEqual(engine.session?.completedSpotIDs.count, 1)
        XCTAssertEqual(engine.session?.nextSpot?.order, 2)
    }

    func testEnteringTriggerStartsStoryOnlyOnce() async {
        let first = MockCatalog.jagalchi.spots[0]
        let location = FakeTripLocation()
        let audio = FakeStoryAudio()
        let engine = TripEngine(locationService: location, audioService: audio)
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()

        location.send(first.coordinate)
        location.send(first.coordinate)
        XCTAssertEqual(engine.session?.currentSpot?.id, first.id)
        XCTAssertEqual(engine.session?.state, .loadingStory)
        XCTAssertTrue(engine.session?.completedSpotIDs.isEmpty == true)
    }
}
