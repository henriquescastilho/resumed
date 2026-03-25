//
//  StudyWidgetEntry.swift
//  ResumedWidget
//
//  Timeline entry types for the three study widgets.
//

import WidgetKit
import Foundation

// MARK: - Next Task Entry (systemSmall)

struct NextTaskEntry: TimelineEntry {
    let date: Date
    let taskTitle: String       // subject name
    let taskTheme: String       // theme or type label
    let taskMinutes: Int
    let taskId: String
    let isCompleted: Bool
    let isEmpty: Bool           // true when no tasks today

    static var placeholder: NextTaskEntry {
        NextTaskEntry(
            date: Date(),
            taskTitle: "Clínica Médica",
            taskTheme: "Matriz ENAMED",
            taskMinutes: 45,
            taskId: "placeholder",
            isCompleted: false,
            isEmpty: false
        )
    }

    static var empty: NextTaskEntry {
        NextTaskEntry(
            date: Date(),
            taskTitle: "",
            taskTheme: "",
            taskMinutes: 0,
            taskId: "",
            isCompleted: false,
            isEmpty: true
        )
    }
}

// MARK: - Day Progress Entry (systemMedium)

struct DayProgressEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]     // max 4 for medium widget
    let completedCount: Int
    let totalCount: Int
    let progressFraction: Double

    struct WidgetTask: Identifiable {
        let id: String
        let subject: String
        let minutes: Int
        let completed: Bool
    }

    var remainingMinutes: Int {
        tasks.filter { !$0.completed }.reduce(0) { $0 + $1.minutes }
    }

    static var placeholder: DayProgressEntry {
        DayProgressEntry(
            date: Date(),
            tasks: [
                WidgetTask(id: "1", subject: "Clínica Médica", minutes: 60, completed: true),
                WidgetTask(id: "2", subject: "Cirurgia Geral", minutes: 45, completed: false),
                WidgetTask(id: "3", subject: "Pediatria", minutes: 30, completed: false),
                WidgetTask(id: "4", subject: "Ginecologia", minutes: 30, completed: false)
            ],
            completedCount: 1,
            totalCount: 4,
            progressFraction: 0.25
        )
    }

    static var empty: DayProgressEntry {
        DayProgressEntry(date: Date(), tasks: [], completedCount: 0, totalCount: 0, progressFraction: 0)
    }
}

// MARK: - Exam Countdown Entry (systemSmall)

struct ExamCountdownEntry: TimelineEntry {
    let date: Date
    let examName: String
    let daysRemaining: Int
    let isEmpty: Bool           // no exam configured

    var urgencyColor: String {
        if daysRemaining > 90 { return "10B981" }   // success green
        if daysRemaining > 30 { return "FFD700" }   // gold
        return "EF4444"                              // error red
    }

    static var placeholder: ExamCountdownEntry {
        ExamCountdownEntry(date: Date(), examName: "ENAMED", daysRemaining: 180, isEmpty: false)
    }

    static var empty: ExamCountdownEntry {
        ExamCountdownEntry(date: Date(), examName: "", daysRemaining: 0, isEmpty: true)
    }
}
