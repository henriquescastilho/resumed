//
//  UserExam.swift
//  Resumed
//
//  Multi-exam tracking — stores user's target exams with dates
//

import Foundation

struct UserExam: Codable, Identifiable {
    let id: String
    var name: String
    var date: Date

    var isFuture: Bool {
        date > Date()
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0)
    }
}

enum UserExamStore {
    private static let key = "userExams_v1"

    static func load() -> [UserExam] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let exams = try? JSONDecoder().decode([UserExam].self, from: data)
        else { return [] }
        return exams
    }

    static func save(_ exams: [UserExam]) {
        if let data = try? JSONEncoder().encode(exams) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func add(_ exam: UserExam) {
        var all = load()
        all.removeAll { $0.id == exam.id }
        all.append(exam)
        save(all)
    }

    static func remove(id: String) {
        var all = load()
        all.removeAll { $0.id == id }
        save(all)
    }
}
