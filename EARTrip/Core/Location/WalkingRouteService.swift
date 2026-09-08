import MapKit
import Observation

/// Requests real pedestrian routes; never substitutes straight lines for roads.
@MainActor
@Observable
final class WalkingRouteService {
    struct Leg: Identifiable {
        let id: UUID
        let route: MKRoute
    }
    private(set) var courseLegs: [Leg] = []
    private(set) var nextRoute: MKRoute?
    private(set) var message: String?
    private(set) var isLoading = false
    @ObservationIgnored private var activeDirections: MKDirections?
    @ObservationIgnored private var lastOrigin: Coordinate?
    @ObservationIgnored private var lastDestination: UUID?
    @ObservationIgnored private var lastRequest = Date.distantPast

    func loadCourse(_ course: Course) async {
        courseLegs = []
        let spots = course.spots.sorted { $0.order < $1.order }
        for (from, to) in zip(spots, spots.dropFirst()) {
            guard !Task.isCancelled else { return }
            do {
                let route = try await calculate(from: from.coordinate, to: to.coordinate)
                guard !Task.isCancelled else { return }
                courseLegs.append(Leg(id: to.id, route: route))
            } catch {
                if Task.isCancelled { return }
                message = "일부 도보 경로를 찾지 못했어요. 지도에서 주변 길을 확인해주세요."
            }
        }
    }

    func update(from origin: Coordinate, to spot: StorySpot, force: Bool = false) async {
        let destinationChanged = lastDestination != spot.id
        let moved = lastOrigin.map { LocationService.distance(from: $0, to: origin) >= 25 } ?? true
        guard force || destinationChanged || (Date().timeIntervalSince(lastRequest) >= 30 && (moved || nextRoute == nil)) else { return }
        activeDirections?.cancel()
        if destinationChanged { nextRoute = nil }
        lastOrigin = origin
        lastDestination = spot.id
        lastRequest = Date()
        let requestID = lastRequest
        isLoading = true
        let directions = makeDirections(from: origin, to: spot.coordinate)
        activeDirections = directions
        do {
            let response = try await withTaskCancellationHandler {
                try await directions.calculate()
            } onCancel: {
                directions.cancel()
            }
            guard !Task.isCancelled, lastRequest == requestID else { return }
            nextRoute = response.routes.first
            message = nextRoute == nil ? "이 위치의 도보 경로를 찾지 못했어요." : nil
        } catch {
            guard !Task.isCancelled, lastRequest == requestID else { return }
            nextRoute = nil
            message = "도보 경로를 불러올 수 없어요. 인터넷 연결과 지도 서비스 지원 지역을 확인해주세요."
        }
        if lastRequest == requestID { isLoading = false }
    }

    func clearNextRoute() {
        activeDirections?.cancel()
        lastRequest = .distantPast
        nextRoute = nil
        lastDestination = nil
        isLoading = false
    }

    private func calculate(from: Coordinate, to: Coordinate) async throws -> MKRoute {
        let directions = makeDirections(from: from, to: to)
        let response = try await withTaskCancellationHandler {
            try await directions.calculate()
        } onCancel: { directions.cancel() }
        guard let route = response.routes.first else { throw URLError(.cannotFindHost) }
        return route
    }

    private func makeDirections(from: Coordinate, to: Coordinate) -> MKDirections {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from.clLocationCoordinate2D))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to.clLocationCoordinate2D))
        request.transportType = .walking
        return MKDirections(request: request)
    }
}
