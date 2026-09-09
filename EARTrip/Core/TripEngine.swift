import Foundation
import Observation

/// Coordinates a trip's lifecycle. Device adapters execute effects; this type owns state transitions.
@MainActor
@Observable
final class TripEngine {
    private(set) var session: TripSession?
    private(set) var playbackError: String?
    private let locationService: any TripLocationSource
    private let audioService: any StoryAudioPlayer
    private let history: TripHistoryStore
    private let now: () -> Date
    private let triggerPolicy = StoryTriggerPolicy()
    private var armedSpotID: UUID?
    @ObservationIgnored private var playbackTask: Task<Void, Never>?
    @ObservationIgnored private var playbackRequest = UUID()

    init(locationService: any TripLocationSource, audioService: any StoryAudioPlayer,
         history: TripHistoryStore? = nil, now: @escaping () -> Date = { Date() }) {
        self.locationService = locationService
        self.audioService = audioService
        self.history = history ?? TripHistoryStore()
        self.now = now
        locationService.onLocationUpdate = { [weak self] coordinate, accuracy in
            self?.handleLocation(coordinate, accuracy: accuracy)
        }
        audioService.onPlaybackCompleted = { [weak self] storyID in
            guard self?.session?.currentSpot?.id == storyID else { return }
            self?.completeCurrentStory()
        }
    }

    var currentTime: TimeInterval { audioService.currentTime }
    var duration: TimeInterval { audioService.duration }
    var isPlaying: Bool { audioService.isPlaying }
    var routeTarget: (origin: Coordinate, spot: StorySpot)? {
        guard let origin = locationService.coordinate, let spot = session?.nextSpot,
              triggerPolicy.accepts(accuracy: locationService.horizontalAccuracy ?? .infinity) else { return nil }
        return (origin, spot)
    }
    var playbackProgress: Double {
        duration > 0 ? min(max(currentTime / duration, 0), 1) : 0
    }

    func isCurrentStory(_ story: StorySpot) -> Bool {
        session?.currentSpot?.id == story.id && session?.currentCourse.id == story.courseID
    }

    func togglePlayback(for story: StorySpot) {
        guard isCurrentStory(story) else { return }
        isPlaying ? pauseStory() : resumeStory()
    }

    func seek(to seconds: TimeInterval) {
        guard session?.currentSpot != nil, session?.state != .loadingStory, seconds.isFinite else { return }
        audioService.seek(to: seconds)
    }

    func skipForward() { seek(to: currentTime + 15) }
    func skipBackward() { seek(to: currentTime - 15) }

    func prepare(course: Course) {
        cancelPlayback()
        locationService.stopUpdating()
        audioService.stop()
        playbackError = nil
        var newSession = TripSession(currentCourse: course)
        newSession.nextSpot = orderedSpots(in: course).first
        newSession.state = .preparing
        session = newSession
        armedSpotID = newSession.nextSpot?.id
    }

    func start() {
        guard var session, session.currentSpot == nil,
              session.state == .preparing || session.state == .paused else { return }
        if session.startedAt == nil { session.startedAt = now() }
        session.state = .walking
        self.session = session
        guard session.nextSpot != nil else { finishTrip(); return }
        locationService.startUpdating()
        if let coordinate = locationService.coordinate {
            handleLocation(coordinate, accuracy: locationService.horizontalAccuracy ?? .infinity)
        }
    }

    func pauseStory() {
        guard session?.state == .storyPlaying else { return }
        audioService.pause()
        session?.state = .paused
    }

    func pauseTrip() {
        guard session?.state == .walking else { return }
        session?.state = .paused
    }

    func resumeTrip() {
        guard session?.state == .paused, session?.currentSpot == nil else { return }
        start()
    }

    func endTrip() {
        cancelPlayback()
        audioService.stop()
        locationService.stopUpdating()
        session = nil
        armedSpotID = nil
        playbackError = nil
    }

    func resumeStory() {
        guard session?.state == .paused, let story = session?.currentSpot else { return }
        if playbackError != nil {
            startStory(story)
        } else {
            audioService.play()
            session?.state = .storyPlaying
        }
    }

    func completeCurrentStory() {
        guard var session, let spot = session.currentSpot else { return }
        cancelPlayback()
        audioService.stop()
        playbackError = nil
        session.completedSpotIDs.insert(spot.id)
        session.currentSpot = nil
        let spots = orderedSpots(in: session.currentCourse)
        session.progress = Double(session.completedSpotIDs.count) / Double(max(spots.count, 1))
        session.nextSpot = spots.first { !session.completedSpotIDs.contains($0.id) }
        session.state = .walking
        armedSpotID = session.nextSpot?.id
        self.session = session
        if session.nextSpot == nil { finishTrip() }
    }

    func triggerCurrentStoryForDemo() {
        guard session?.state == .walking, let spot = session?.nextSpot else { return }
        startStory(spot)
    }

    private func finishTrip() {
        guard var session, session.state != .completed else { return }
        session.state = .completed
        session.progress = 1
        session.completedAt = now()
        self.session = session
        locationService.stopUpdating()
        history.recordCompletion(of: session)
    }

    private func handleLocation(_ coordinate: Coordinate, accuracy: Double) {
        guard var session else { return }
        session.currentLocation = coordinate
        if let next = session.nextSpot {
            session.distanceToNextSpot = coordinate.distance(to: next.coordinate)
        }
        self.session = session
        guard session.state == .walking, let next = session.nextSpot,
              let distance = session.distanceToNextSpot,
              triggerPolicy.contains(distance: distance, radius: next.triggerRadius, accuracy: accuracy),
              armedSpotID == next.id, !session.completedSpotIDs.contains(next.id) else { return }
        armedSpotID = nil
        startStory(next)
    }

    private func startStory(_ spot: StorySpot) {
        guard var session, spot.courseID == session.currentCourse.id,
              !session.completedSpotIDs.contains(spot.id) else { return }
        cancelPlayback()
        let request = playbackRequest
        session.currentSpot = spot
        session.state = .loadingStory
        self.session = session
        playbackError = nil
        playbackTask = Task { [weak self] in
            guard let self else { return }
            do {
                try Task.checkCancellation()
                try await audioService.load(spot)
                try Task.checkCancellation()
                guard playbackRequest == request, self.session?.currentSpot?.id == spot.id else { return }
                audioService.play()
                self.session?.state = .storyPlaying
            } catch {
                guard !Task.isCancelled, playbackRequest == request else { return }
                audioService.stop()
                playbackError = "이야기를 불러오지 못했어요. 다시 재생해주세요."
                self.session?.state = .paused
            }
        }
    }

    private func cancelPlayback() {
        playbackRequest = UUID()
        playbackTask?.cancel()
        playbackTask = nil
    }

    private func orderedSpots(in course: Course) -> [StorySpot] {
        course.spots.filter { $0.courseID == course.id }.sorted { $0.order < $1.order }
    }
}
