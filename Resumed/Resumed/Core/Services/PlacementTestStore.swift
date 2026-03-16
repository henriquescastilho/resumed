//
//  PlacementTestStore.swift
//  Resumed
//
//  Persistence layer for placement test results.
//

import Foundation

final class PlacementTestStore {
    static let shared = PlacementTestStore()
    private init() {}

    static let resultKey = "placementTestResult"
    static let hasTakenTestKey = "hasCompletedPlacementTest"

    func saveResult(_ result: PlacementTestResult) {
        guard let data = try? JSONEncoder().encode(result) else { return }
        UserDefaults.standard.set(data, forKey: Self.resultKey)
        UserDefaults.standard.set(true, forKey: Self.hasTakenTestKey)
    }

    func loadResult() -> PlacementTestResult? {
        guard let data = UserDefaults.standard.data(forKey: Self.resultKey),
              let result = try? JSONDecoder().decode(PlacementTestResult.self, from: data)
        else { return nil }
        return result
    }

    var hasTakenTest: Bool {
        UserDefaults.standard.bool(forKey: Self.hasTakenTestKey)
    }

    func priorityWeights() -> [String: Double] {
        guard let result = loadResult() else { return [:] }
        return Dictionary(uniqueKeysWithValues: result.specialtyLevels.compactMap { key, value in
            guard let level = SpecialtyLevel(rawValue: value) else { return nil }
            return (key, level.studyWeight)
        })
    }

    func clearResult() {
        UserDefaults.standard.removeObject(forKey: Self.resultKey)
        UserDefaults.standard.removeObject(forKey: Self.hasTakenTestKey)
    }
}
