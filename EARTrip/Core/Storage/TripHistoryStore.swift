import Foundation
import Observation

@MainActor
@Observable
final class TripHistoryStore {
    private(set) var records: [TripRecord] = []

    func add(course: Course, elapsedMinutes: Int) {
        guard !records.contains(where: { $0.course.id == course.id }) else { return }
        records.insert(.init(id: UUID(), course: course, completedAt: .now, elapsedMinutes: elapsedMinutes), at: 0)
    }
}

