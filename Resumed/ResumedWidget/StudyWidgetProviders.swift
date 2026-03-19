//
//  StudyWidgetProviders.swift
//  ResumedWidget
//
//  Timeline providers for the three study widgets.
//  All data is read from the App Group shared UserDefaults.
//

import WidgetKit
import Foundation

private let suiteName = "group.com.resumed.app"

// MARK: - Next Task Provider

struct NextTaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextTaskEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NextTaskEntry) -> Void) {
        completion(loadNextTaskEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTaskEntry>) -> Void) {
        let entry = loadNextTaskEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadNextTaskEntry() -> NextTaskEntry {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        let isEmpty = defaults.bool(forKey: "widget_next_task_empty")
        if isEmpty {
            return .empty
        }
        return NextTaskEntry(
            date: Date(),
            taskTitle: defaults.string(forKey: "widget_next_task_title") ?? "Sem tarefas",
            taskTheme: defaults.string(forKey: "widget_next_task_theme") ?? "",
            taskMinutes: defaults.integer(forKey: "widget_next_task_minutes"),
            taskId: defaults.string(forKey: "widget_next_task_id") ?? "",
            isCompleted: defaults.bool(forKey: "widget_next_task_completed"),
            isEmpty: false
        )
    }
}

// MARK: - Day Progress Provider

struct DayProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayProgressEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DayProgressEntry) -> Void) {
        completion(loadDayProgressEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayProgressEntry>) -> Void) {
        let entry = loadDayProgressEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadDayProgressEntry() -> DayProgressEntry {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard

        let ids = defaults.stringArray(forKey: "widget_study_task_ids") ?? []
        let subjects = defaults.stringArray(forKey: "widget_study_task_subjects") ?? []
        let minutesRaw = defaults.array(forKey: "widget_study_task_minutes") as? [Int] ?? []
        let completedRaw = defaults.array(forKey: "widget_study_task_completed") as? [Bool] ?? []

        let count = min(min(ids.count, subjects.count), 4)
        var tasks: [DayProgressEntry.WidgetTask] = []
        for i in 0..<count {
            let id = ids[i]
            let subject = i < subjects.count ? subjects[i] : ""
            let minutes = i < minutesRaw.count ? minutesRaw[i] : 0
            let completed = i < completedRaw.count ? completedRaw[i] : false
            tasks.append(DayProgressEntry.WidgetTask(id: id, subject: subject, minutes: minutes, completed: completed))
        }

        let completedCount = defaults.integer(forKey: "widget_study_progress")
        let totalCount = defaults.integer(forKey: "widget_study_total")
        let fraction: Double = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0

        return DayProgressEntry(
            date: Date(),
            tasks: tasks,
            completedCount: completedCount,
            totalCount: totalCount,
            progressFraction: fraction
        )
    }
}

// MARK: - Exam Countdown Provider

struct ExamCountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExamCountdownEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ExamCountdownEntry) -> Void) {
        completion(loadExamEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExamCountdownEntry>) -> Void) {
        let entry = loadExamEntry()
        // Refresh at midnight so the day counter ticks correctly
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let midnight = calendar.startOfDay(for: tomorrow)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func loadExamEntry() -> ExamCountdownEntry {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        let isEmpty = defaults.bool(forKey: "widget_exam_empty")
        if isEmpty {
            return .empty
        }
        return ExamCountdownEntry(
            date: Date(),
            examName: defaults.string(forKey: "widget_exam_name") ?? "",
            daysRemaining: {
                let examTime = defaults.double(forKey: "widget_exam_date")
                guard examTime > 0 else { return defaults.integer(forKey: "widget_exam_days_remaining") }
                let examDate = Date(timeIntervalSince1970: examTime)
                return max(0, Calendar.current.dateComponents([.day], from: Date(), to: examDate).day ?? 0)
            }(),
            isEmpty: false
        )
    }
}
