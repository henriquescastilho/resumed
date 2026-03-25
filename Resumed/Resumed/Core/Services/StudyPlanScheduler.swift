//
//  StudyPlanScheduler.swift
//  Resumed
//
//  Conflict detection and overflow redistribution for weekly study plans.
//

import Foundation

@MainActor
final class StudyPlanScheduler {
    static let shared = StudyPlanScheduler()
    private init() {}

    // A day is "conflicted" when its total planned minutes exceed dailyCapacity * 1.2
    private let overloadFactor: Double = 1.2

    // MARK: - Conflict Detection

    /// Returns the indices of DayPlans that exceed the daily capacity threshold.
    func detectConflicts(in days: [DayPlan], dailyCapacityMinutes: Int) -> [Int] {
        let threshold = Double(dailyCapacityMinutes) * overloadFactor
        return days.indices.filter { Double(days[$0].totalMinutes) > threshold }
    }

    // MARK: - Overflow Redistribution

    /// Moves the lowest-priority (last) tasks from overloaded days to the lightest available
    /// day in the same 7-day window until each day is within the capacity threshold.
    func redistributeOverflow(in days: inout [DayPlan], dailyCapacityMinutes: Int) {
        let threshold = Double(dailyCapacityMinutes) * overloadFactor

        for dayIndex in days.indices {
            // Redistribute until this day is within threshold
            while Double(days[dayIndex].totalMinutes) > threshold {
                // Find the lightest day (excluding current) that has headroom
                guard let targetIndex = lightestDayIndex(in: days,
                                                         excluding: dayIndex,
                                                         capacity: dailyCapacityMinutes) else {
                    break // No valid target — stop to avoid infinite loop
                }

                // Move the last (lowest-priority) incomplete task
                guard let taskIndex = days[dayIndex].tasks.indices.last(where: {
                    !days[dayIndex].tasks[$0].completed
                }) else {
                    break
                }

                var movedTask = days[dayIndex].tasks[taskIndex]
                // Update the dueDate to the target day
                movedTask = StudyTask(
                    id: movedTask.id,
                    title: movedTask.title,
                    subject: movedTask.subject,
                    type: movedTask.type,
                    dueDate: days[targetIndex].date,
                    completed: movedTask.completed,
                    estimatedMinutes: movedTask.estimatedMinutes,
                    theme: movedTask.theme,
                    topics: movedTask.topics
                )

                let minutes = movedTask.estimatedMinutes
                days[dayIndex].tasks.remove(at: taskIndex)
                days[dayIndex].totalMinutes -= minutes

                days[targetIndex].tasks.append(movedTask)
                days[targetIndex].totalMinutes += minutes
            }
        }
    }

    // MARK: - Private Helpers

    private func lightestDayIndex(in days: [DayPlan], excluding index: Int, capacity: Int) -> Int? {
        let threshold = Double(capacity) * overloadFactor
        return days.indices
            .filter { $0 != index && Double(days[$0].totalMinutes) < threshold }
            .min { days[$0].totalMinutes < days[$1].totalMinutes }
    }
}
