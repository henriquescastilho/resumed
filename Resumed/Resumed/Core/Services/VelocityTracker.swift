//
//  VelocityTracker.swift
//  Resumed
//
//  Tracks planned vs actual study minutes per week to calibrate future plan allocations.
//

import Foundation

@MainActor
final class VelocityTracker {
    static let shared = VelocityTracker()

    private var key: String {
        let uid = SupabaseManager.shared.currentUser?.id ?? "local"
        return "velocityRecords_\(uid)"
    }
    private let maxRecords = 12
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Persistence

    private func loadRecords() -> [VelocityRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? decoder.decode([VelocityRecord].self, from: data)
        else { return [] }
        return records
    }

    private func saveRecords(_ records: [VelocityRecord]) {
        guard let data = try? encoder.encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Public API

    /// Record planned vs actual minutes for a given week offset.
    func record(weekOffset: Int, plannedMinutes: Int, actualMinutes: Int) {
        var records = loadRecords()

        // Remove any existing record for the same week
        records.removeAll { $0.weekOffset == weekOffset }

        let entry = VelocityRecord(
            weekOffset: weekOffset,
            plannedMinutes: plannedMinutes,
            actualMinutes: actualMinutes,
            recordedAt: Date()
        )
        records.append(entry)

        // Keep only the most recent maxRecords entries
        if records.count > maxRecords {
            records = Array(records.sorted { $0.recordedAt > $1.recordedAt }.prefix(maxRecords))
        }

        saveRecords(records)
    }

    /// Average actual/planned ratio over the last N completed weeks. Clamped to 0.5...1.5.
    /// Returns 1.0 when there are no records (no adjustment).
    func rollingVelocity(lastNWeeks: Int = 4) -> Double {
        let records = loadRecords()
            .filter { $0.plannedMinutes > 0 }
            .sorted { $0.recordedAt > $1.recordedAt }
            .prefix(lastNWeeks)

        guard !records.isEmpty else { return 1.0 }

        let ratioSum = records.reduce(0.0) { sum, rec in
            sum + (Double(rec.actualMinutes) / Double(rec.plannedMinutes))
        }
        let average = ratioSum / Double(records.count)
        return max(0.5, min(1.5, average))
    }

    /// Returns the weekly minute budget for a given daily hours setting, adjusted by velocity.
    func adjustedMinutesForWeek(declaredDailyHours: Int) -> Int {
        let rawMinutes = declaredDailyHours * 60 * 7
        let velocity = rollingVelocity()
        return Int(Double(rawMinutes) * velocity)
    }
}
