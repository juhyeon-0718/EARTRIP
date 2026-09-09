import Foundation
import Observation

@MainActor
@Observable
final class TripHistoryStore {
    private(set) var records: [TripRecord] = []

    func recordCompletion(of session: TripSession) {
        guard session.state == .completed, let start = session.startedAt,
              let end = session.completedAt, !records.contains(where: { $0.id == session.id }) else { return }
        let minutes = Int(max(0, end.timeIntervalSince(start)) / 60)
        records.insert(.init(id: session.id, course: session.currentCourse,
                             completedAt: end, elapsedMinutes: minutes), at: 0)
    }
}
