import XCTest
@testable import Resumed

final class StudyPlanStoreTests: XCTestCase {
    func testSaveAndLoadWeekPlan() {
        let store = StudyPlanStore.shared
        let day = DayPlan(date: Date(), tasks: [], totalMinutes: 0, completedMinutes: 0)
        store.save(weekOffset: 999, days: [day])
        let loaded = store.load(weekOffset: 999)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 1)
    }
}
