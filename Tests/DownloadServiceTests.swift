import XCTest
@testable import EARTrip

@MainActor
final class DownloadServiceTests: XCTestCase {
    func testCancelledDemoDoesNotBecomeReady() async {
        let downloads = DownloadService()
        let task = Task { await downloads.prepareMockCourse(MockCatalog.jagalchi) }
        task.cancel()
        await task.value
        XCTAssertEqual(downloads.state(for: MockCatalog.jagalchi), .notDownloaded)
    }

    func testUnsafeOrEmptyManifestCannotBecomeReady() async {
        let downloads = DownloadService()
        let url = URL(string: "https://example.invalid/audio.m4a")!
        for resources in [[], [DownloadResource(remoteURL: url, filename: "../escape")],
                          [DownloadResource(remoteURL: url, filename: "/absolute")],
                          [DownloadResource(remoteURL: url, filename: "audio"), DownloadResource(remoteURL: url, filename: "audio")]] {
            do {
                _ = try await downloads.downloadPackage(for: MockCatalog.jagalchi, resources: resources)
                XCTFail("Invalid manifest accepted")
            } catch {
                XCTAssertEqual(downloads.state(for: MockCatalog.jagalchi), .notDownloaded)
            }
        }
    }

    func testDemoReadyIsNotAnOfflinePackage() {
        XCTAssertTrue(DownloadState.demoReady.isReady)
        XCTAssertNotEqual(DownloadState.demoReady, .ready(localDirectory: URL(fileURLWithPath: "/example")))
    }
}
