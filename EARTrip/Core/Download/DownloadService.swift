import Foundation
import Observation

enum DownloadState: Equatable, Sendable {
    case notDownloaded
    case downloading(progress: Double)
    case ready(localDirectory: URL?)
    case failed(message: String)

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}

@MainActor
@Observable
final class DownloadService {
    private(set) var states: [UUID: DownloadState] = [:]
    private let fileManager: FileManager
    private let session: URLSession

    init(fileManager: FileManager = .default, session: URLSession = .shared) {
        self.fileManager = fileManager
        self.session = session
    }

    func state(for course: Course) -> DownloadState {
        states[course.id] ?? .notDownloaded
    }

    func prepareMockCourse(_ course: Course) async {
        states[course.id] = .downloading(progress: 0.12)
        try? await Task.sleep(for: .milliseconds(250))
        states[course.id] = .downloading(progress: 0.58)
        try? await Task.sleep(for: .milliseconds(250))
        states[course.id] = .ready(localDirectory: nil)
    }

    func download(from remoteURL: URL, for course: Course, filename: String) async throws -> URL {
        states[course.id] = .downloading(progress: 0)
        do {
            let (temporaryURL, response) = try await session.download(from: remoteURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let destination = try courseDirectory(course.id).appendingPathComponent(filename)
            if fileManager.fileExists(atPath: destination.path()) { try fileManager.removeItem(at: destination) }
            try fileManager.moveItem(at: temporaryURL, to: destination)
            states[course.id] = .ready(localDirectory: destination.deletingLastPathComponent())
            return destination
        } catch {
            states[course.id] = .failed(message: error.localizedDescription)
            throw error
        }
    }

    private func courseDirectory(_ id: UUID) throws -> URL {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OfflineCourses", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}

