import CoreLocation

extension Coordinate {
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}
