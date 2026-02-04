//
//  FocusSessionManagerTests.swift
//  ResumedTests
//

import XCTest
@testable import Resumed

final class FocusSessionManagerTests: XCTestCase {
    private let lastDayKey = "pomodoro_last_day"
    private let completedKey = "pomodoros_completed_today"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: lastDayKey)
        UserDefaults.standard.removeObject(forKey: completedKey)
        UserDefaults.standard.removeObject(forKey: "focus_duration_seconds")
        UserDefaults.standard.removeObject(forKey: "break_duration_seconds")
    }

    func testCompletePomodoroIncrementsDailyCount() {
        let manager = FocusSessionManager.shared
        manager.resetIfNewDay(currentDate: Date())
        let initial = manager.pomodorosCompletedToday
        manager.completeFocus(currentDate: Date())
        XCTAssertEqual(manager.pomodorosCompletedToday, min(initial + 1, 8))
    }

    func testDailyResetOnNewDay() {
        let manager = FocusSessionManager.shared
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        UserDefaults.standard.set("2000-01-01", forKey: lastDayKey)
        UserDefaults.standard.set(5, forKey: completedKey)

        manager.resetIfNewDay(currentDate: yesterday)
        manager.resetIfNewDay(currentDate: Date())

        XCTAssertEqual(manager.pomodorosCompletedToday, 0)
    }

    func testCompletePomodoroIncrementsXP() {
        let manager = FocusSessionManager.shared
        let gamification = GamificationManager.shared
        let before = gamification.totalXP

        manager.completeFocus(currentDate: Date())

        XCTAssertGreaterThanOrEqual(gamification.totalXP - before, 25)
    }

    func testPauseKeepsRemainingSeconds() {
        let manager = FocusSessionManager.shared
        manager.focusDurationSeconds = 10
        manager.start()
        let remainingBefore = manager.remainingSeconds
        manager.pause()
        XCTAssertTrue(manager.isPaused)
        XCTAssertGreaterThanOrEqual(manager.remainingSeconds, remainingBefore - 1)
        manager.stop()
    }
}
