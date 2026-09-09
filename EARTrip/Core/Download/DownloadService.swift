import Foundation
import Observation

enum DownloadState: Equatable, Sendable {
    case notDownloaded
    case downloading(progress: Double)
    case ready(localDirectory: URL)
    case demoReady
    case failed(message: String)

    var isReady: Bool {
        if case .ready = self { return true }
        if case .demoReady = self { return true }
        return false
    }
}

struct DownloadResource: Sendable {
    let remoteURL: URL
    let filename: String
}

@MainActor
@Observable
final class DownloadService {
    private(set) var states: [UUID: DownloadState] = [:]
    private let fileManager: FileManager
    private let session: URLSession
    private var activeRequests: [UUID: UUID] = [:]

    init(fileManager: FileManager = .default, session: URLSession = .shared) {
        self.fileManager = fileManager
        self.session = session
    }

    func state(for course: Course) -> DownloadState {
        states[course.id] ?? .notDownloaded
    }

    func prepareMockCourse(_ course: Course) async {
        let request = UUID()
        activeRequests[course.id] = request
        states[course.id] = .downloading(progress: 0.12)
        do {
            try await Task.sleep(for: .milliseconds(250))
            guard activeRequests[course.id] == request else { return }
            states[course.id] = .downloading(progress: 0.58)
            try await Task.sleep(for: .milliseconds(250))
            guard activeRequests[course.id] == request else { return }
            states[course.id] = .demoReady
        } catch {
            if activeRequests[course.id] == request { states[course.id] = .notDownloaded }
        }
    }

    /// The caller supplies the complete manifest. Only a completed package is ready.
    /// Each attempt uses a separate directory; a partial retry cannot corrupt an existing package.
    func downloadPackage(for course: Course, resources: [DownloadResource]) async throws -> URL {
        guard !resources.isEmpty,
              Set(resources.map(\.filename)).count == resources.count,
              resources.allSatisfy({ isSafeFilename($0.filename) }) else {
            throw URLError(.badURL)
        }
        let request = UUID()
        activeRequests[course.id] = request
        let directory: URL
        do {
            directory = try packageDirectory(request)
        } catch {
            states[course.id] = .failed(message: error.localizedDescription)
            throw error
        }
        states[course.id] = .downloading(progress: 0)
        do {
            for (index, resource) in resources.enumerated() {
                try Task.checkCancellation()
                let (temporaryURL, response) = try await session.download(from: resource.remoteURL)
                defer { try? fileManager.removeItem(at: temporaryURL) }
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
                try Task.checkCancellation()
                guard activeRequests[course.id] == request else { throw CancellationError() }
                try fileManager.moveItem(at: temporaryURL, to: directory.appendingPathComponent(resource.filename))
                states[course.id] = .downloading(progress: Double(index + 1) / Double(resources.count))
            }
            states[course.id] = .ready(localDirectory: directory)
            return directory
        } catch {
            try? fileManager.removeItem(at: directory)
            if activeRequests[course.id] == request {
                states[course.id] = Task.isCancelled || error is CancellationError
                    ? .notDownloaded : .failed(message: error.localizedDescription)
            }
            throw error
        }
    }

    private func isSafeFilename(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/") &&
            !name.contains("\\") && !name.contains(":") && !name.contains("\0")
    }

    private func packageDirectory(_ id: UUID) throws -> URL {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OfflineCourses", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}
