//
//  SimulationLogStore.swift
//  Resumed
//
//  Persistence for simulation logs (UserDefaults JSON)
//

import Foundation

enum SimulationLogStore {
    private static var key: String {
        let uid = SupabaseManager.shared.currentUser?.id ?? "local"
        return "simulation_logs_\(uid)"
    }

    static func save(_ log: SimulationLog) {
        var all = loadAll()
        all.insert(log, at: 0) // newest first
        // Keep last 100 logs max
        if all.count > 100 { all = Array(all.prefix(100)) }
        persist(all)
    }

    static func loadAll() -> [SimulationLog] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let logs = try? JSONDecoder().decode([SimulationLog].self, from: data)
        else { return [] }
        return logs
    }

    static func delete(id: String) {
        var all = loadAll()
        all.removeAll { $0.id == id }
        persist(all)
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func persist(_ logs: [SimulationLog]) {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
