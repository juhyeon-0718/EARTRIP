import XCTest
import UIKit
@testable import EARTrip

final class DesignAssetTests: XCTestCase {
    @MainActor
    func testApprovedArtworkIsBundled() {
        for name in ["CompanionWalking", "CompanionResting", "TravelHero",
                     "SeoulArtwork", "GyeongjuArtwork", "HarborArtwork"] {
            let image = UIImage(named: name)
            XCTAssertNotNil(image, "Missing approved design asset: \(name)")
            XCTAssertGreaterThan(image?.size.width ?? 0, 0)
            XCTAssertGreaterThan(image?.size.height ?? 0, 0)
        }
    }
}
