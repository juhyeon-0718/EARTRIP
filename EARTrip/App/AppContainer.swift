import SwiftUI

@main
@MainActor
struct EARTripApp: App {
    @State private var locationService: LocationService
    @State private var audioService: AudioService
    @State private var downloadService = DownloadService()
    @State private var historyStore = TripHistoryStore()
    @State private var tripEngine: TripEngine

    init() {
        let location = LocationService()
        let audio = AudioService()
        _locationService = State(initialValue: location)
        _audioService = State(initialValue: audio)
        _tripEngine = State(initialValue: TripEngine(locationService: location, audioService: audio))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(locationService)
                .environment(audioService)
                .environment(downloadService)
                .environment(historyStore)
                .environment(tripEngine)
                .tint(EARColor.forest)
        }
    }
}
