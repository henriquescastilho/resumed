import XCTest
@testable import Resumed

final class SocialStatsManagerTests: XCTestCase {
    func testStatsPercentWithinRange() {
        let result = SocialStatsManager.shared.stats(for: "Clínica Médica", isCorrect: true)
        XCTAssertGreaterThanOrEqual(result.percentCorrect, 10)
        XCTAssertLessThanOrEqual(result.percentCorrect, 90)
        XCTAssertFalse(result.message.isEmpty)
    }
}
