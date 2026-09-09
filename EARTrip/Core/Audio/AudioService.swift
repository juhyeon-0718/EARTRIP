import AVFoundation
import Observation

@MainActor
@Observable
final class AudioService: StoryAudioPlayer {
    private(set) var currentStory: StorySpot?
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isPlaying = false
    var onPlaybackCompleted: ((UUID) -> Void)?
    @ObservationIgnored private var loadID = UUID()

    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var completionObserver: NSObjectProtocol?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    func load(_ story: StorySpot) async throws {
        stop()
        let requestID = loadID
        currentStory = story
        duration = story.duration
        guard let url = story.localAudioURL ?? story.audioURL else { return }
        try configureAudioSession()
        let player = AVPlayer(url: url)
        self.player = player
        observe(player)
        if let item = player.currentItem {
            let loadedDuration = try await item.asset.load(.duration)
            try Task.checkCancellation()
            guard loadID == requestID else { throw CancellationError() }
            let seconds = loadedDuration.seconds
            if seconds.isFinite { duration = seconds }
        }
    }

    func play() {
        guard currentStory != nil else { return }
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() { play() }

    func stop() {
        loadID = UUID()
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        if let completionObserver { NotificationCenter.default.removeObserver(completionObserver) }
        timeObserver = nil
        completionObserver = nil
        player?.pause()
        player = nil
        currentTime = 0
        duration = 0
        currentStory = nil
        isPlaying = false
    }

    func seek(to seconds: TimeInterval) {
        let target = min(max(seconds, 0), duration)
        currentTime = target
        player?.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    func skipForward() { seek(to: currentTime + 15) }
    func skipBackward() { seek(to: currentTime - 15) }

    /// Keeps mock/no-URL stories usable in previews and simulator flows.
    func simulateProgress(_ seconds: TimeInterval) {
        guard player == nil, isPlaying else { return }
        currentTime = min(currentTime + seconds, duration)
        if currentTime >= duration { finishPlayback() }
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetoothA2DP])
        try session.setActive(true)
    }

    private func observe(_ player: AVPlayer) {
        let observedLoadID = loadID
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self, loadID == observedLoadID, time.seconds.isFinite else { return }
                currentTime = time.seconds
            }
        }
        completionObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self, loadID == observedLoadID else { return }
                finishPlayback()
            }
        }
    }

    private func finishPlayback() {
        isPlaying = false
        currentTime = duration
        if let id = currentStory?.id { onPlaybackCompleted?(id) }
    }
}
