//
//  ProgressTracker.swift
//  Resumed
//
//  Local progress tracking from study sessions and questions
//

import Foundation

struct SubjectProgress: Codable {
    var questionsAnswered: Int
    var correctAnswers: Int
    var studyMinutes: Int

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }
}

struct ProgressSnapshot {
    let totalQuestions: Int
    let totalCorrect: Int
    let studyMinutes: Int
    let subjectStats: [String: SubjectProgress]
}

@MainActor
final class ProgressTracker {
    static let shared = ProgressTracker()

    private let subjectStatsKey = "progress_subject_stats"
    private let totalStudyMinutesKey = "progress_total_study_minutes"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func recordStudy(subject: String, minutes: Int) {
        var stats = loadSubjectStats()
        var progress = stats[subject] ?? SubjectProgress(questionsAnswered: 0, correctAnswers: 0, studyMinutes: 0)
        progress.studyMinutes += max(minutes, 0)
        stats[subject] = progress
        saveSubjectStats(stats)

        let total = UserDefaults.standard.integer(forKey: totalStudyMinutesKey) + max(minutes, 0)
        UserDefaults.standard.set(total, forKey: totalStudyMinutesKey)
    }

    func recordQuestion(subject: String, isCorrect: Bool) {
        var stats = loadSubjectStats()
        var progress = stats[subject] ?? SubjectProgress(questionsAnswered: 0, correctAnswers: 0, studyMinutes: 0)
        progress.questionsAnswered += 1
        if isCorrect { progress.correctAnswers += 1 }
        stats[subject] = progress
        saveSubjectStats(stats)
    }

    func recordExamResult(totalQuestions: Int, correctAnswers: Int, subject: String = "Simulado") {
        var stats = loadSubjectStats()
        var progress = stats[subject] ?? SubjectProgress(questionsAnswered: 0, correctAnswers: 0, studyMinutes: 0)
        progress.questionsAnswered += max(totalQuestions, 0)
        progress.correctAnswers += max(correctAnswers, 0)
        stats[subject] = progress
        saveSubjectStats(stats)
    }

    func snapshot() -> ProgressSnapshot {
        let stats = loadSubjectStats()
        let totalQuestions = stats.values.reduce(0) { $0 + $1.questionsAnswered }
        let totalCorrect = stats.values.reduce(0) { $0 + $1.correctAnswers }
        let studyMinutes = UserDefaults.standard.integer(forKey: totalStudyMinutesKey)
        return ProgressSnapshot(
            totalQuestions: totalQuestions,
            totalCorrect: totalCorrect,
            studyMinutes: studyMinutes,
            subjectStats: stats
        )
    }

    private func loadSubjectStats() -> [String: SubjectProgress] {
        guard let data = UserDefaults.standard.data(forKey: subjectStatsKey) else { return [:] }
        return (try? decoder.decode([String: SubjectProgress].self, from: data)) ?? [:]
    }

    private func saveSubjectStats(_ stats: [String: SubjectProgress]) {
        guard let data = try? encoder.encode(stats) else { return }
        UserDefaults.standard.set(data, forKey: subjectStatsKey)
    }
}
