//
//  StudyPlanStore.swift
//  Resumed
//
//  Offline persistence for weekly plans (UserDefaults)
//

import Foundation

struct StudyPlanStore {
    static let shared = StudyPlanStore()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(weekOffset: Int, days: [DayPlan]) {
        let key = Self.key(for: weekOffset)
        guard let data = try? encoder.encode(days) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func load(weekOffset: Int) -> [DayPlan]? {
        let key = Self.key(for: weekOffset)
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? decoder.decode([DayPlan].self, from: data)
    }

    private static func key(for weekOffset: Int) -> String {
        "plan_week_\(weekOffset)"
    }
}
