import XCTest
@testable import EARTrip

@MainActor
final class TripEngineTests: XCTestCase {
    func testPausedTripDoesNotTriggerAndResumeUsesLatestLocation() {
        let location = LocationService(mode: .mock)
        let engine = TripEngine(locationService: location, audioService: AudioService())
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()
        engine.pauseTrip()
        location.pushMockLocation(MockCatalog.jagalchi.spots[0].coordinate)
        XCTAssertNil(engine.session?.currentSpot)
        XCTAssertEqual(engine.session?.state, .paused)
        engine.resumeTrip()
        XCTAssertEqual(engine.session?.state, .storyPlaying)
        engine.endTrip()
    }

    func testEndingTripPreventsPendingPlayback() async {
        let audio = AudioService()
        let engine = TripEngine(locationService: LocationService(mode: .mock), audioService: audio)
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()
        engine.triggerCurrentStoryForDemo()
        engine.endTrip()
        await Task.yield()
        XCTAssertNil(engine.session)
        XCTAssertFalse(audio.isPlaying)
    }

    func testPrepareSelectsFirstStory() {
        let location = LocationService(mode: .mock)
        let audio = AudioService()
        let engine = TripEngine(locationService: location, audioService: audio)

        engine.prepare(course: MockCatalog.jagalchi)

        XCTAssertEqual(engine.session?.state, .preparing)
        XCTAssertEqual(engine.session?.nextSpot?.order, 1)
    }

    func testStoryCannotCompleteTwice() async {
        let location = LocationService(mode: .mock)
        let audio = AudioService()
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
        let location = LocationService(mode: .mock)
        let audio = AudioService()
        let engine = TripEngine(locationService: location, audioService: audio)
        engine.prepare(course: MockCatalog.jagalchi)
        engine.start()

        location.pushMockLocation(first.coordinate)
        location.pushMockLocation(first.coordinate)
        await Task.yield()

        XCTAssertEqual(engine.session?.currentSpot?.id, first.id)
        XCTAssertEqual(engine.session?.state, .storyPlaying)
        XCTAssertTrue(engine.session?.completedSpotIDs.isEmpty == true)
    }
}
