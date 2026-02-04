//
//  StudyPlanView.swift
//  Resumed
//
//  Study Plan View - Meu Plano (Weekly Calendar)
//

import SwiftUI
import Combine

struct StudyPlanView: View {
    @StateObject private var viewModel = StudyPlanViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Week navigation
            HStack {
                Button { viewModel.previousWeek() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.resumed.gold)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text("Semana: \(viewModel.weekRange)")
                    .font(.resumed.h4)
                    .foregroundColor(.resumed.white)

                Spacer()

                Button { viewModel.nextWeek() } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.resumed.gold)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, Spacing.md)
            .background(Color.resumed.blackSecondary)

            // Progress
            ProgressBar(current: Int(viewModel.weekProgress * 100), total: 100, showLabel: true)
                .padding(Spacing.md)

            // Days
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(viewModel.days) { day in
                        DaySection(day: day) { taskId in
                            Task { await viewModel.toggleTask(taskId) }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
            }
        }
        .background(Color.resumed.black)
        .navigationTitle("Meu Plano")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPlan()
        }
    }
}

@MainActor
class StudyPlanViewModel: ObservableObject {
    @Published var weekOffset = 0
    @Published var days: [DayPlan] = []
    @Published var weekProgress: Double = 0

    var weekRange: String {
        let (start, end) = WeekNavigator.weekDateRange(for: weekOffset)
        return WeekNavigator.formatWeekRange(start, end)
    }

    func loadPlan() async {
        loadMockData()
    }

    func previousWeek() {
        weekOffset -= 1
        HapticManager.shared.selection()
        Task { await loadPlan() }
    }

    func nextWeek() {
        weekOffset += 1
        HapticManager.shared.selection()
        Task { await loadPlan() }
    }

    func toggleTask(_ taskId: String) async {
        for (dayIndex, day) in days.enumerated() {
            if let taskIndex = day.tasks.firstIndex(where: { $0.id == taskId }) {
                days[dayIndex].tasks[taskIndex].completed.toggle()
                HapticManager.shared.success()
                updateProgress()
                return
            }
        }
    }

    private func updateProgress() {
        let totalMinutes = days.reduce(0) { $0 + $1.totalMinutes }
        let completedMinutes = days.reduce(0) { sum, day in
            sum + day.tasks.filter { $0.completed }.reduce(0) { $0 + $1.estimatedMinutes }
        }
        weekProgress = totalMinutes > 0 ? Double(completedMinutes) / Double(totalMinutes) : 0
    }

    private func loadMockData() {
        let calendar = Calendar.current
        let (weekStart, _) = WeekNavigator.weekDateRange(for: weekOffset)

        days = (0..<7).compactMap { dayOffset -> DayPlan? in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { return nil }

            let tasks: [StudyTask] = (dayOffset < 5) ? [
                StudyTask(
                    id: "task-\(dayOffset)-1",
                    title: "Clínica Médica",
                    subject: "Clínica Médica",
                    type: .review,
                    dueDate: date,
                    completed: dayOffset < 2,
                    estimatedMinutes: 60,
                    theme: "Cardiologia",
                    topics: ["IC", "Arritmias"]
                ),
                StudyTask(
                    id: "task-\(dayOffset)-2",
                    title: "Cirurgia Geral",
                    subject: "Cirurgia Geral",
                    type: .review,
                    dueDate: date,
                    completed: dayOffset < 1,
                    estimatedMinutes: 45,
                    theme: "Trauma",
                    topics: ["ATLS"]
                )
            ] : []

            let orderedTasks = orderByPriority(tasks)
            let totalMinutes = tasks.reduce(0) { $0 + $1.estimatedMinutes }
            let completedMinutes = tasks.filter { $0.completed }.reduce(0) { $0 + $1.estimatedMinutes }

            return DayPlan(date: date, tasks: orderedTasks, totalMinutes: totalMinutes, completedMinutes: completedMinutes)
        }

        updateProgress()
    }

    private func orderByPriority(_ tasks: [StudyTask]) -> [StudyTask] {
        let priority = UserDefaults.standard.stringArray(forKey: "subjectPriority") ?? []
        guard !priority.isEmpty else { return tasks }
        let indexMap = Dictionary(uniqueKeysWithValues: priority.enumerated().map { ($0.element, $0.offset) })
        return tasks.sorted { left, right in
            let leftIndex = indexMap[left.subject] ?? Int.max
            let rightIndex = indexMap[right.subject] ?? Int.max
            return leftIndex < rightIndex
        }
    }
}

struct DaySection: View {
    let day: DayPlan
    let onToggleTask: (String) -> Void
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button { withAnimation { isExpanded.toggle() } } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(day.dayOfWeek)
                            .font(.resumed.caption)
                            .foregroundColor(day.isToday ? .resumed.gold : .resumed.gray)
                        Text(day.dayNumber)
                            .font(.resumed.h3)
                            .foregroundColor(day.isToday ? .resumed.gold : .resumed.white)
                    }

                    Spacer()

                    if day.totalMinutes > 0 {
                        Text("\(day.completedMinutes)/\(day.totalMinutes) min")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.resumed.gray)
                }
            }

            if isExpanded {
                if day.tasks.isEmpty {
                    Text("Nenhuma tarefa")
                        .font(.resumed.body)
                        .foregroundColor(.resumed.gray)
                } else {
                    ForEach(day.tasks) { task in
                        TaskRow(task: task) { onToggleTask(task.id) }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(day.isToday ? Color.resumed.gold.opacity(0.05) : Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.lg)
    }
}

struct TaskRow: View {
    let task: StudyTask
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: IconSize.lg))
                    .foregroundColor(task.completed ? .resumed.gold : .resumed.gray)
            }

            VStack(alignment: .leading) {
                Text(task.subject)
                    .font(.resumed.body)
                    .foregroundColor(task.completed ? .resumed.gray : .resumed.white)
                    .strikethrough(task.completed)

                HStack(spacing: Spacing.xs) {
                    Image(systemName: task.type.icon)
                        .font(.system(size: 10))
                    Text(task.type.displayName)
                        .font(.resumed.caption)
                }
                .foregroundColor(.resumed.gray)
            }

            Spacer()

            Text("\(task.estimatedMinutes) min")
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)
        }
        .padding(Spacing.sm)
        .background(Color.resumed.blackTertiary)
        .cornerRadius(CornerRadius.md)
    }
}
