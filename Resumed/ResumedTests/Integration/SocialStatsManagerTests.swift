import XCTest
@testable import Resumed

final class SocialStatsManagerTests: XCTestCase {
    @MainActor
    func testStatsPercentWithinRange() {
        let result = SocialStatsManager.shared.stats(for: "Clínica Médica", isCorrect: true)
        XCTAssertGreaterThanOrEqual(result.percentCorrect, 0)
        XCTAssertLessThanOrEqual(result.percentCorrect, 100)
        XCTAssertFalse(result.message.isEmpty)
    }
}
