import CoreLocation

struct Coordinate: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}

