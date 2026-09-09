import SwiftUI

@main
@MainActor
struct EARTripApp: App {
    @State private var locationService: LocationService
    @State private var downloadService = DownloadService()
    @State private var historyStore: TripHistoryStore
    @State private var tripEngine: TripEngine
    @State private var catalog = CourseCatalog(courses: MockCatalog.courses, cities: MockCatalog.cities)

    init() {
        let location = LocationService()
        let audio = AudioService()
        let history = TripHistoryStore()
        _locationService = State(initialValue: location)
        _historyStore = State(initialValue: history)
        _tripEngine = State(initialValue: TripEngine(locationService: location, audioService: audio, history: history))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(locationService)
                .environment(catalog)
                .environment(downloadService)
                .environment(historyStore)
                .environment(tripEngine)
                .tint(EARColor.forest)
        }
    }
}
