//
//  UsageLimiter.swift
//  Resumed
//
//  Tracks daily question usage for free tier limits
//

import Foundation

@MainActor
final class UsageLimiter {
    static let shared = UsageLimiter()

    private let dailyLimitKey = "daily_questions_count"
    private let lastDateKey = "daily_questions_date"
    private let freeLimit = 50

    private init() {}

    func incrementQuestions() {
        resetIfNewDay()
        let count = UserDefaults.standard.integer(forKey: dailyLimitKey) + 1
        UserDefaults.standard.set(count, forKey: dailyLimitKey)
    }

    func hasReachedLimit() -> Bool {
        resetIfNewDay()
        return UserDefaults.standard.integer(forKey: dailyLimitKey) >= freeLimit
    }

    func remainingQuestions() -> Int {
        resetIfNewDay()
        return max(0, freeLimit - UserDefaults.standard.integer(forKey: dailyLimitKey))
    }

    private func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date
        if lastDate == nil || !Calendar.current.isDate(lastDate!, inSameDayAs: today) {
            UserDefaults.standard.set(0, forKey: dailyLimitKey)
            UserDefaults.standard.set(today, forKey: lastDateKey)
        }
    }
}
