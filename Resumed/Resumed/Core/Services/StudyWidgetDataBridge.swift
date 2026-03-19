//
//  StudyWidgetDataBridge.swift
//  Resumed
//
//  Syncs study plan data to the App Group shared container
//  so the study widget extension can read it.
//
//  App Group: group.com.resumed.app
//

import Foundation
import WidgetKit

@MainActor
final class StudyWidgetDataBridge {
    static let suiteName = "group.com.resumed.app"

    // MARK: - Sync Today's Plan

    /// Called by StudyPlanViewModel after plan changes.
    /// Finds today's DayPlan and writes up to 4 tasks into the App Group.
    static func syncTodayPlan(_ days: [DayPlan]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        let todayPlan = days.first { $0.isToday }
        let tasks = (todayPlan?.tasks ?? []).prefix(4)

        // Encode task data as parallel arrays (widget cannot import main-app types)
        let taskIds = tasks.map { $0.id }
        let taskSubjects = tasks.map { $0.subject }
        let taskThemes = tasks.map { $0.theme ?? $0.type.displayName }
        let taskMinutes = tasks.map { $0.estimatedMinutes }
        let taskCompleted = tasks.map { $0.completed }

        defaults.set(taskIds, forKey: "widget_study_task_ids")
        defaults.set(taskSubjects, forKey: "widget_study_task_subjects")
        defaults.set(taskThemes, forKey: "widget_study_task_themes")
        defaults.set(taskMinutes, forKey: "widget_study_task_minutes")
        defaults.set(taskCompleted, forKey: "widget_study_task_completed")

        let completedCount = tasks.filter { $0.completed }.count
        let totalCount = tasks.count
        defaults.set(completedCount, forKey: "widget_study_progress")
        defaults.set(totalCount, forKey: "widget_study_total")

        // Next incomplete task (for small widget)
        if let next = tasks.first(where: { !$0.completed }) {
            defaults.set(next.id, forKey: "widget_next_task_id")
            defaults.set(next.subject, forKey: "widget_next_task_title")
            defaults.set(next.theme ?? next.type.displayName, forKey: "widget_next_task_theme")
            defaults.set(next.estimatedMinutes, forKey: "widget_next_task_minutes")
            defaults.set(false, forKey: "widget_next_task_completed")
            defaults.set(false, forKey: "widget_next_task_empty")
        } else if tasks.isEmpty {
            defaults.set("", forKey: "widget_next_task_id")
            defaults.set("", forKey: "widget_next_task_title")
            defaults.set("", forKey: "widget_next_task_theme")
            defaults.set(0, forKey: "widget_next_task_minutes")
            defaults.set(false, forKey: "widget_next_task_completed")
            defaults.set(true, forKey: "widget_next_task_empty")
        } else {
            // All tasks completed
            defaults.set("", forKey: "widget_next_task_id")
            defaults.set("Tudo concluído!", forKey: "widget_next_task_title")
            defaults.set("", forKey: "widget_next_task_theme")
            defaults.set(0, forKey: "widget_next_task_minutes")
            defaults.set(true, forKey: "widget_next_task_completed")
            defaults.set(false, forKey: "widget_next_task_empty")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Sync Exam Countdown

    /// Called by HomeViewModel in loadData().
    /// Reads the nearest future exam from UserExamStore and writes it to App Group.
    static func syncExamCountdown() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        let exams = UserExamStore.load().filter { $0.isFuture }.sorted { $0.date < $1.date }

        if let nearest = exams.first {
            defaults.set(nearest.name, forKey: "widget_exam_name")
            defaults.set(nearest.date.timeIntervalSince1970, forKey: "widget_exam_date")
            defaults.set(false, forKey: "widget_exam_empty")
        } else {
            defaults.set("", forKey: "widget_exam_name")
            defaults.set(0, forKey: "widget_exam_days_remaining")
            defaults.set(true, forKey: "widget_exam_empty")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Widget Intent — Task Completion

    /// Called by CompleteStudyTaskIntent when user taps checkbox in widget.
    /// Appends the taskId to the pending completions array in App Group.
    static func markTaskComplete(taskId: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        var pending = defaults.stringArray(forKey: "widget_pending_completions") ?? []
        if !pending.contains(taskId) {
            pending.append(taskId)
        }
        defaults.set(pending, forKey: "widget_pending_completions")
    }

    /// Called by the app on foreground to check which tasks were completed via widget.
    static func pendingCompletions() -> [String] {
        let defaults = UserDefaults(suiteName: suiteName)
        return defaults?.stringArray(forKey: "widget_pending_completions") ?? []
    }

    /// Called after pending completions have been processed.
    static func clearPendingCompletions() {
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removeObject(forKey: "widget_pending_completions")
    }
}
