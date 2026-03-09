//
//  ErrorReviewScheduler.swift
//  Resumed
//
//  Periodic error review scheduler (Andrei Toribio method)
//

import Foundation

struct ErrorReviewScheduler {
    static let shared = ErrorReviewScheduler()

    private init() {}

    func refreshSchedules() {
        let subjects = CoreDataManager.shared.fetchSubjectsWithHistory()
        for subject in subjects {
            let history = CoreDataManager.shared.fetchQuestionHistory(subject: subject, limit: 500)
            guard !history.isEmpty else { continue }
            updateSchedule(for: subject, history: history)
        }
    }

    func applyReviewTasks(to days: inout [DayPlan], weekStart: Date) {
        refreshSchedules()
        let calendar = Calendar.current
        for subject in CoreDataManager.shared.fetchSubjectsWithHistory() {
            guard let reviewDate = nextReviewDate(for: subject) else { continue }
            let dayIndex = calendar.dateComponents([.day], from: weekStart, to: reviewDate).day ?? -1
            guard dayIndex >= 0, dayIndex < days.count else { continue }

            let taskId = "review-\(subjectKey(subject))-\(Self.dayKey(from: reviewDate))"
            let alreadyExists = days[dayIndex].tasks.contains { $0.id == taskId }
            if alreadyExists { continue }

            let reviewTask = StudyTask(
                id: taskId,
                title: "Revisão de Erros",
                subject: subject,
                type: .review,
                dueDate: reviewDate,
                completed: false,
                estimatedMinutes: 30,
                theme: "Revisão",
                topics: nil
            )
            days[dayIndex].tasks.append(reviewTask)
            days[dayIndex].totalMinutes += reviewTask.estimatedMinutes
        }
    }

    private func updateSchedule(for subject: String, history: [CDQuestionHistory]) {
        let calendar = Calendar.current
        let sorted = history.sorted {
            ($0.answeredAt ?? .distantPast) > ($1.answeredAt ?? .distantPast)
        }
        let lastAnswer = sorted.first
        let total = history.count
        let correct = history.filter { $0.isCorrect }.count
        let accuracy = total > 0 ? Double(correct) / Double(total) * 100 : 0

        let daysToAdd: Int
        if let lastAnswer, !lastAnswer.isCorrect {
            daysToAdd = 3
        } else if accuracy < 60 {
            daysToAdd = 7
        } else if accuracy <= 80 {
            daysToAdd = 15
        } else {
            daysToAdd = 30
        }

        if let next = calendar.date(byAdding: .day, value: daysToAdd, to: Date()) {
            UserDefaults.standard.set(next, forKey: scheduleKey(for: subject))
        }
    }

    private func nextReviewDate(for subject: String) -> Date? {
        UserDefaults.standard.object(forKey: scheduleKey(for: subject)) as? Date
    }

    private func scheduleKey(for subject: String) -> String {
        "review_schedule_\(subjectKey(subject))"
    }

    private func subjectKey(_ subject: String) -> String {
        subject.lowercased().replacingOccurrences(of: " ", with: "_")
    }

    private static func dayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
