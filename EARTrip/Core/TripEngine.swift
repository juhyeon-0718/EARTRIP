import Foundation
import Observation

@MainActor
@Observable
final class TripEngine {
    private(set) var session: TripSession?
    private let locationService: LocationService
    private let audioService: AudioService
    private var armedSpotID: UUID?

    init(locationService: LocationService, audioService: AudioService) {
        self.locationService = locationService
        self.audioService = audioService
        locationService.onLocationUpdate = { [weak self] coordinate, accuracy in
            self?.handleLocation(coordinate, accuracy: accuracy)
        }
        audioService.onPlaybackCompleted = { [weak self] in self?.completeCurrentStory() }
    }

    func prepare(course: Course) {
        var newSession = TripSession(currentCourse: course)
        newSession.nextSpot = course.spots.sorted(by: { $0.order < $1.order }).first
        newSession.state = .preparing
        session = newSession
        armedSpotID = newSession.nextSpot?.id
    }

    func start() {
        guard var session else { return }
        session.state = .walking
        self.session = session
        locationService.startUpdating()
        if let coordinate = locationService.coordinate {
            handleLocation(coordinate, accuracy: locationService.horizontalAccuracy ?? 5)
        }
    }

    func pauseStory() {
        audioService.pause()
        session?.state = .paused
    }

    func resumeStory() {
        audioService.resume()
        session?.state = .storyPlaying
    }

    func completeCurrentStory() {
        guard var session, let spot = session.currentSpot else { return }
        audioService.stop()
        session.completedSpotIDs.insert(spot.id)
        session.currentSpot = nil
        session.progress = Double(session.completedSpotIDs.count) / Double(max(session.currentCourse.spots.count, 1))
        session.nextSpot = session.currentCourse.spots.sorted(by: { $0.order < $1.order })
            .first(where: { !session.completedSpotIDs.contains($0.id) })
        if session.nextSpot == nil {
            session.state = .completed
            locationService.stopUpdating()
        } else {
            session.state = .walking
        }
        armedSpotID = session.nextSpot?.id
        self.session = session
    }

    func triggerCurrentStoryForDemo() {
        guard let spot = session?.nextSpot else { return }
        startStory(spot)
    }

    private func handleLocation(_ coordinate: Coordinate, accuracy: Double) {
        guard var session, session.state == .walking, let next = session.nextSpot else { return }
        session.currentLocation = coordinate
        let distance = LocationService.distance(from: coordinate, to: next.coordinate)
        session.distanceToNextSpot = distance
        self.session = session

        let acceptableAccuracy = accuracy <= 65
        let inside = distance <= next.triggerRadius + min(accuracy, 20)
        guard acceptableAccuracy, inside, armedSpotID == next.id, !session.completedSpotIDs.contains(next.id) else { return }
        armedSpotID = nil
        startStory(next)
    }

    private func startStory(_ spot: StorySpot) {
        guard var session, !session.completedSpotIDs.contains(spot.id) else { return }
        session.currentSpot = spot
        session.state = .storyPlaying
        self.session = session
        Task {
            await audioService.load(spot)
            audioService.play()
        }
    }
}
