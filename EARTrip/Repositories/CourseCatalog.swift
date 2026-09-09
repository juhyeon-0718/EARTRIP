import Observation

/// A replaceable catalog snapshot, not a networking layer.
/// Only the composition root decides whether content comes from fixtures or a backend.
@MainActor
@Observable
final class CourseCatalog {
    let courses: [Course]
    let cities: [String]

    init(courses: [Course], cities: [String] = []) {
        self.courses = courses
        self.cities = (cities + courses.map(\.city)).reduce(into: []) { result, city in
            if !result.contains(city) { result.append(city) }
        }
    }

    func courses(in city: String) -> [Course] {
        courses.filter { $0.city == city }
    }
}
