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
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showQuestionsSheet = false
    @State private var selectedTask: StudyTask?
    @State private var showOfflineAlert = false
    @State private var showStudySheet = false

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
                        } onQuestions: { task in
                            if networkMonitor.isConnected {
                                selectedTask = task
                                showQuestionsSheet = true
                            } else {
                                showOfflineAlert = true
                            }
                        } onStudy: { task in
                            selectedTask = task
                            showStudySheet = true
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
        .sheet(isPresented: $showQuestionsSheet) {
            if let task = selectedTask {
                DailyQuestionsView(
                    subject: task.subject,
                    theme: task.theme,
                    isOnline: networkMonitor.isConnected
                )
            }
        }
        .sheet(isPresented: $showStudySheet) {
            if let task = selectedTask {
                StudyDetailSheet(task: task) {
                    Task { await viewModel.toggleTask(task.id) }
                }
            }
        }
        .alert("Offline", isPresented: $showOfflineAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Para resolver questões, conecte-se à internet.")
        }
    }
}

@MainActor
class StudyPlanViewModel: ObservableObject {
    private enum PlanDefaults {
        static let weeklyMinimumPercent: Double = 0.13
        static let minBlockMinutes: Int = 20
        static let roundToMinutes: Int = 5
    }

    private let mandatorySubjects = [
        "Clínica Médica",
        "Cirurgia Geral",
        "Ginecologia e Obstetrícia",
        "Pediatria",
        "MFC",
        "Saúde Mental",
        "Saúde Coletiva"
    ]

    @Published var weekOffset = 0
    @Published var days: [DayPlan] = []
    @Published var weekProgress: Double = 0

    var weekRange: String {
        let (start, end) = WeekNavigator.weekDateRange(for: weekOffset)
        return WeekNavigator.formatWeekRange(start, end)
    }

    func loadPlan() async {
        if let stored = StudyPlanStore.shared.load(weekOffset: weekOffset), isPlanValid(stored) {
            days = stored
        } else {
            loadMockData()
            StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
        }
        injectErrorReviews()
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
                let task = days[dayIndex].tasks[taskIndex]
                if task.completed {
                    ProgressTracker.shared.recordStudy(subject: task.subject, minutes: task.estimatedMinutes)
                    GamificationManager.shared.addXP(XPReward.completeTask, reason: .studySession)
                }
                HapticManager.shared.success()
                updateProgress()
                StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
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

        let weeklyAllocation = buildWeeklyAllocation()

        days = (0..<7).compactMap { dayOffset -> DayPlan? in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { return nil }

            let tasks = buildDailyTasks(
                date: date,
                dayOffset: dayOffset,
                allocation: weeklyAllocation
            )
            let orderedTasks = orderByPriority(tasks)
            let totalMinutes = orderedTasks.reduce(0) { $0 + $1.estimatedMinutes }
            let completedMinutes = orderedTasks.filter { $0.completed }.reduce(0) { $0 + $1.estimatedMinutes }

            return DayPlan(date: date, tasks: orderedTasks, totalMinutes: totalMinutes, completedMinutes: completedMinutes)
        }

        updateProgress()
    }

    private func buildWeeklyAllocation() -> [String: Int] {
        let studyHoursPerDay = max(UserDefaults.standard.integer(forKey: "studyHoursPerDay"), 1)
        let weeklyMinutes = studyHoursPerDay * 60 * 7

        let minPerSubject = Int(Double(weeklyMinutes) * PlanDefaults.weeklyMinimumPercent)
        let baseTotal = minPerSubject * mandatorySubjects.count
        let remaining = max(weeklyMinutes - baseTotal, 0)

        let priority = UserDefaults.standard.stringArray(forKey: "subjectPriority") ?? []
        let rankedSubjects = priority.filter { mandatorySubjects.contains($0) }
        let fallbackSubjects = mandatorySubjects.filter { !rankedSubjects.contains($0) }
        let ordered = rankedSubjects + fallbackSubjects

        let weights = ordered.enumerated().map { index, _ in max(ordered.count - index, 1) }
        let weightSum = weights.reduce(0, +)

        var allocation: [String: Int] = [:]
        for (index, subject) in ordered.enumerated() {
            let bonus = weightSum > 0 ? Int(Double(remaining) * Double(weights[index]) / Double(weightSum)) : 0
            allocation[subject] = minPerSubject + bonus
        }

        return allocation
    }

    private func buildDailyTasks(date: Date, dayOffset: Int, allocation: [String: Int]) -> [StudyTask] {
        var tasks: [StudyTask] = []

        let priority = UserDefaults.standard.stringArray(forKey: "subjectPriority") ?? []
        let rankedSubjects = priority.filter { mandatorySubjects.contains($0) }
        let fallbackSubjects = mandatorySubjects.filter { !rankedSubjects.contains($0) }
        let orderedSubjects = rankedSubjects + fallbackSubjects

        var dailyMinutesBySubject: [String: Int] = [:]
        for subject in orderedSubjects {
            let weekly = allocation[subject] ?? 0
            let rawDaily = Double(weekly) / 7.0
            let rounded = max(PlanDefaults.minBlockMinutes, roundTo(rawDaily))
            dailyMinutesBySubject[subject] = rounded
        }

        let dayTarget = max(UserDefaults.standard.integer(forKey: "studyHoursPerDay"), 1) * 60
        let currentSum = dailyMinutesBySubject.values.reduce(0, +)
        if let top = orderedSubjects.first, currentSum != dayTarget {
            let diff = dayTarget - currentSum
            dailyMinutesBySubject[top] = max(PlanDefaults.minBlockMinutes, (dailyMinutesBySubject[top] ?? 0) + diff)
        }

        for (index, subject) in orderedSubjects.enumerated() {
            let minutes = dailyMinutesBySubject[subject] ?? PlanDefaults.minBlockMinutes
            let task = StudyTask(
                id: "task-\(dayOffset)-\(index)-\(subjectKey(subject))",
                title: subject,
                subject: subject,
                type: .review,
                dueDate: date,
                completed: false,
                estimatedMinutes: minutes,
                theme: "Matriz ENAMED",
                topics: nil
            )
            tasks.append(task)
        }

        return tasks
    }

    private func roundTo(_ value: Double) -> Int {
        let step = Double(PlanDefaults.roundToMinutes)
        let rounded = Int((value / step).rounded() * step)
        return max(PlanDefaults.minBlockMinutes, rounded)
    }

    private func subjectKey(_ subject: String) -> String {
        subject.lowercased().replacingOccurrences(of: " ", with: "_")
    }

    private func injectErrorReviews() {
        let (weekStart, _) = WeekNavigator.weekDateRange(for: weekOffset)
        var updated = days
        ErrorReviewScheduler.shared.applyReviewTasks(to: &updated, weekStart: weekStart)
        updated = updated.map { day in
            var copy = day
            copy.tasks = orderByPriority(copy.tasks)
            return copy
        }
        days = updated
        updateProgress()
        StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
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

    private func isPlanValid(_ days: [DayPlan]) -> Bool {
        let subjectsInPlan = Set(days.flatMap { $0.tasks.map { $0.subject } })
        let required = Set(mandatorySubjects)
        return required.isSubset(of: subjectsInPlan)
    }
}

struct DaySection: View {
    let day: DayPlan
    let onToggleTask: (String) -> Void
    let onQuestions: (StudyTask) -> Void
    let onStudy: (StudyTask) -> Void
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
                        TaskRow(
                            task: task,
                            onToggle: { onToggleTask(task.id) },
                            onQuestions: { onQuestions(task) },
                            onStudy: { onStudy(task) }
                        )
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
    let onQuestions: () -> Void
    let onStudy: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
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

                    Text("Conteúdo do dia • \(task.estimatedMinutes) min")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }

                Spacer()
            }

            HStack(spacing: Spacing.sm) {
                ResumedButton(
                    title: "Estudar",
                    style: .ghost,
                    action: onStudy,
                    icon: "book.fill",
                    fullWidth: true
                )
                ResumedButton(
                    title: "Questões",
                    style: .ghost,
                    action: onQuestions,
                    icon: "pencil.and.list.clipboard",
                    fullWidth: true
                )
            }
        }
        .padding(Spacing.sm)
        .background(Color.resumed.blackTertiary)
        .cornerRadius(CornerRadius.md)
    }
}

private struct StudyDetailSheet: View {
    let task: StudyTask
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(task.subject)
                    .font(.resumed.h3)
                    .foregroundColor(.resumed.white)

                if let theme = task.theme {
                    Text("Tema: \(theme)")
                        .font(.resumed.bodySmall)
                        .foregroundColor(.resumed.gray)
                }

                if let topics = task.topics, !topics.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Assuntos")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                        ForEach(topics, id: \.self) { topic in
                            Text("• \(topic)")
                                .font(.resumed.body)
                                .foregroundColor(.resumed.white)
                        }
                    }
                }

                Text("Este bloco é o conteúdo principal do dia. Após estudar, marque como concluído.")
                    .font(.resumed.bodySmall)
                    .foregroundColor(.resumed.gray)

                Spacer()

                ResumedButton(title: "Marcar como estudado", style: .primary, action: {
                    onComplete()
                    dismiss()
                })
            }
            .padding(Spacing.md)
            .background(Color.resumed.black)
            .navigationTitle("Estudar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
        }
    }
}
