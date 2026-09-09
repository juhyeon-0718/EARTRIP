import CoreLocation
import Observation

@MainActor
@Observable
final class LocationService: NSObject, TripLocationSource, @preconcurrency CLLocationManagerDelegate {
    enum Mode: Sendable, Equatable { case live, mock }

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var coordinate: Coordinate?
    private(set) var horizontalAccuracy: Double?
    private(set) var lastErrorDescription: String?
    private(set) var speed: Double = 0
    private(set) var lastUpdate: Date?
    var mode: Mode
    var onLocationUpdate: ((Coordinate, Double) -> Void)?

    @ObservationIgnored private let manager: CLLocationManager

    init(mode: Mode = .live, initialCoordinate: Coordinate? = nil) {
        let manager = CLLocationManager()
        self.manager = manager
        self.mode = mode
        self.coordinate = initialCoordinate
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = true
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    func requestPermission() {
        guard mode == .live else { return }
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard mode == .live, isAuthorized else { return }
        manager.startUpdatingLocation()
    }

    func stopUpdating() { manager.stopUpdatingLocation() }

    func distance(to spot: StorySpot) -> Double? {
        guard let coordinate else { return nil }
        return Self.distance(from: coordinate, to: spot.coordinate)
    }

    func isInsideTriggerRadius(of spot: StorySpot) -> Bool {
        guard let distance = distance(to: spot) else { return false }
        return StoryTriggerPolicy().contains(distance: distance, radius: spot.triggerRadius,
                                             accuracy: horizontalAccuracy ?? .infinity)
    }

    func pushMockLocation(_ coordinate: Coordinate, accuracy: Double = 5) {
        guard mode == .mock else { return }
        publish(coordinate, accuracy: accuracy)
    }

    static func distance(from: Coordinate, to: Coordinate) -> Double {
        from.distance(to: to)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized { startUpdating() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard mode == .live, let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        guard abs(location.timestamp.timeIntervalSinceNow) < 20 else { return }
        speed = max(0, location.speed)
        publish(.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), accuracy: location.horizontalAccuracy)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastErrorDescription = error.localizedDescription
    }

    private func publish(_ coordinate: Coordinate, accuracy: Double) {
        self.coordinate = coordinate
        horizontalAccuracy = accuracy
        lastUpdate = Date()
        lastErrorDescription = nil
        onLocationUpdate?(coordinate, accuracy)
    }
}
