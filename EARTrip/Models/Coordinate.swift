import Foundation

struct Coordinate: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    func distance(to other: Coordinate) -> Double {
        let radians = Double.pi / 180
        let latitudeDelta = (other.latitude - latitude) * radians
        let longitudeDelta = (other.longitude - longitude) * radians
        let a = pow(sin(latitudeDelta / 2), 2) +
            cos(latitude * radians) * cos(other.latitude * radians) * pow(sin(longitudeDelta / 2), 2)
        return 6_371_000 * 2 * asin(sqrt(min(1, max(0, a))))
    }
}
