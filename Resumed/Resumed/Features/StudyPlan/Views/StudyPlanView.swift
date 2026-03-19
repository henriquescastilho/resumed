//
//  StudyPlanView.swift
//  Resumed
//
//  Study Plan View - Meu Plano (Weekly/Monthly/Daily Calendar)
//

import SwiftUI
import Combine
import WidgetKit

// MARK: - View Mode

enum PlanViewMode: String, CaseIterable {
    case week = "Semana"
    case month = "Mês"
    case day = "Dia"
}

// MARK: - Main View

struct StudyPlanView: View {
    @StateObject private var viewModel = StudyPlanViewModel()
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showQuestionsSheet = false
    @State private var selectedTask: StudyTask?
    @State private var showOfflineAlert = false
    @State private var showStudySheet = false
    @State private var viewMode: PlanViewMode = .week
    @State private var selectedDay: Date = Date()
    @State private var showCalendarExportAlert = false
    @State private var calendarExportMessage = ""
    @State private var showCalendarExportError = false
    @State private var showPlanBuilder = false
    @State private var showExportSheet = false
    @State private var showStudyGroups = false
    @State private var showEditSheet = false
    @State private var showAddSheet = false
    @State private var editingDayIndex: Int = 0
    @State private var addingToDate: Date = Date()

    var body: some View {
        VStack(spacing: 0) {
            // View mode picker
            Picker("Modo", selection: $viewMode) {
                ForEach(PlanViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.resumed.blackSecondary)

            // Migration banner
            if viewModel.migratedTasksCount > 0 {
                MigrationBanner(count: viewModel.migratedTasksCount)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xs)
            }

            // Content by mode
            switch viewMode {
            case .week:
                weekView
            case .month:
                CalendarHeatmapView { date in
                    selectedDay = date
                    viewMode = .day
                }
                .id(viewMode) // Force reload when switching back to month
            case .day:
                DayTimelineView(date: selectedDay) { taskId in
                    Task { await viewModel.toggleTask(taskId) }
                }
            }
        }
        .background(Color.resumed.black)
        .navigationTitle("Meu Plano")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    Button {
                        HapticManager.shared.selection()
                        showStudyGroups = true
                    } label: {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.resumed.gold)
                    }

                    Button {
                        HapticManager.shared.selection()
                        showExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(.resumed.gold)
                    }

                    Button {
                        HapticManager.shared.selection()
                        showPlanBuilder = true
                    } label: {
                        Image(systemName: "plus.rectangle.on.rectangle")
                            .font(.system(size: 14))
                            .foregroundColor(.resumed.gold)
                    }
                }
            }
        }
        .task {
            await viewModel.loadPlan()
        }
        .sheet(isPresented: $showPlanBuilder) {
            PlanBuilderView()
        }
        .sheet(isPresented: $showExportSheet) {
            ExportPlanSheet(days: viewModel.days, weekRange: viewModel.weekRange)
        }
        .navigationDestination(isPresented: $showStudyGroups) {
            StudyGroupView()
        }
        .onChange(of: showPlanBuilder) { _, isPresented in
            // Reload plan after builder is dismissed (plan may have been rebuilt)
            if !isPresented {
                Task { await viewModel.loadPlan() }
            }
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
        .sheet(isPresented: $showEditSheet) {
            if let task = selectedTask {
                EditTaskSheet(
                    mode: .edit(task: task),
                    onSave: { updatedTask in
                        viewModel.updateTask(updatedTask, inDayIndex: editingDayIndex)
                    },
                    onDelete: {
                        viewModel.deleteTask(task.id, fromDayIndex: editingDayIndex)
                    }
                )
            }
        }
        .sheet(isPresented: $showAddSheet) {
            EditTaskSheet(
                mode: .add(date: addingToDate),
                onSave: { newTask in
                    viewModel.addTask(newTask, toDayIndex: editingDayIndex)
                },
                onDelete: nil
            )
        }
        .alert("Offline", isPresented: $showOfflineAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Para resolver questões, conecte-se à internet.")
        }
        .alert("Calendário", isPresented: $showCalendarExportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(calendarExportMessage)
        }
        .alert("Erro no Calendário", isPresented: $showCalendarExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(calendarExportMessage)
        }
    }

    // MARK: - Week view (original layout)

    private var weekView: some View {
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
                    ForEach(Array(viewModel.days.enumerated()), id: \.element.id) { index, day in
                        DaySection(
                            day: day,
                            hasConflict: viewModel.conflictDayIndices.contains(index)
                        ) { taskId in
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
                        } onEditTask: { task in
                            selectedTask = task
                            editingDayIndex = index
                            showEditSheet = true
                        } onDeleteTask: { taskId in
                            viewModel.deleteTask(taskId, fromDayIndex: index)
                        } onAddTask: {
                            editingDayIndex = index
                            addingToDate = day.date
                            showAddSheet = true
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
            }
        }
    }

    // MARK: - Calendar export

    private func exportToCalendar() async {
        let service = EventKitService.shared
        let granted = await service.requestAccess()
        guard granted else {
            calendarExportMessage = "Acesso ao calendário negado. Verifique as permissões nas Configurações."
            showCalendarExportError = true
            return
        }

        HapticManager.shared.selection()

        do {
            switch viewMode {
            case .week:
                for day in viewModel.days {
                    try await service.exportDayPlan(day)
                }
                calendarExportMessage = "Semana exportada com sucesso para o Apple Calendário!"
            case .month:
                calendarExportMessage = "Use a visualização semanal ou diária para exportar eventos."
            case .day:
                let weekOffset = weekOffsetForDate(selectedDay)
                if let days = StudyPlanStore.shared.load(weekOffset: weekOffset),
                   let dayPlan = days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }) {
                    try await service.exportDayPlan(dayPlan)
                    calendarExportMessage = "Dia exportado com sucesso para o Apple Calendário!"
                } else {
                    calendarExportMessage = "Nenhuma tarefa encontrada para este dia."
                }
            }
            HapticManager.shared.success()
            showCalendarExportAlert = true
        } catch {
            calendarExportMessage = error.localizedDescription
            showCalendarExportError = true
        }
    }

    private func weekOffsetForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = Date()
        guard let todayWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ),
        let dateWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        ) else { return 0 }
        let diff = calendar.dateComponents([.weekOfYear], from: todayWeekStart, to: dateWeekStart)
        return diff.weekOfYear ?? 0
    }
}

// MARK: - Migration Banner

private struct MigrationBanner: View {
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(.resumed.warning)

            Text("\(count) tarefa\(count > 1 ? "s" : "") de dias anteriores foram movidas para hoje.")
                .font(.resumed.caption)
                .foregroundColor(.resumed.white)

            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.resumed.warning.opacity(0.12))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.resumed.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - ViewModel

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
    @Published var migratedTasksCount: Int = 0
    @Published var conflictDayIndices: [Int] = []

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
        autoMigrateUncompletedTasks()  // BEFORE injection — avoids migrating injected overlay tasks
        injectErrorReviews()           // AFTER migration
        detectConflicts()
        StudyWidgetDataBridge.syncTodayPlan(days)
    }

    /// Process any task completions made via the widget and re-sync (serial, idempotent).
    func onForeground() {
        let pending = StudyWidgetDataBridge.pendingCompletions()
        guard !pending.isEmpty else { return }
        Task {
            for taskId in pending {
                await completeTask(taskId)
            }
            StudyWidgetDataBridge.clearPendingCompletions()
            StudyWidgetDataBridge.syncTodayPlan(days)
        }
    }

    /// Idempotent task completion — only marks incomplete tasks as complete, never toggles back.
    func completeTask(_ taskId: String) async {
        for (dayIndex, day) in days.enumerated() {
            if let taskIndex = day.tasks.firstIndex(where: { $0.id == taskId }) {
                guard !days[dayIndex].tasks[taskIndex].completed else { return }
                days[dayIndex].tasks[taskIndex].completed = true
                let task = days[dayIndex].tasks[taskIndex]
                ProgressTracker.shared.recordStudy(subject: task.subject, minutes: task.estimatedMinutes)
                GamificationManager.shared.addXP(XPReward.completeTask, reason: .studySession)
                HapticManager.shared.success()
                updateProgress()
                StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
                return
            }
        }
    }

    private func detectConflicts() {
        let studyHoursPerDay = max(UserDefaults.standard.integer(forKey: "studyHoursPerDay"), 1)
        let dailyCapacity = studyHoursPerDay * 60
        conflictDayIndices = StudyPlanScheduler.shared.detectConflicts(in: days, dailyCapacityMinutes: dailyCapacity)
    }

    func previousWeek() {
        recordVelocityForCurrentWeek()
        weekOffset -= 1
        HapticManager.shared.selection()
        Task { await loadPlan() }
    }

    func nextWeek() {
        recordVelocityForCurrentWeek()
        weekOffset += 1
        HapticManager.shared.selection()
        Task { await loadPlan() }
    }

    private func recordVelocityForCurrentWeek() {
        guard weekOffset < 0 else { return } // Only record past (completed) weeks
        let plannedMinutes = days.reduce(0) { $0 + $1.totalMinutes }
        let actualMinutes = days.reduce(0) { $0 + $1.completedMinutes }
        guard plannedMinutes > 0 else { return }
        VelocityTracker.shared.record(
            weekOffset: weekOffset,
            plannedMinutes: plannedMinutes,
            actualMinutes: actualMinutes
        )
    }

    func toggleTask(_ taskId: String) async {
        for (dayIndex, day) in days.enumerated() {
            if let taskIndex = day.tasks.firstIndex(where: { $0.id == taskId }) {
                days[dayIndex].tasks[taskIndex].completed.toggle()
                let task = days[dayIndex].tasks[taskIndex]
                if task.completed {
                    ProgressTracker.shared.recordStudy(subject: task.subject, minutes: task.estimatedMinutes)
                    GamificationManager.shared.addXP(XPReward.completeTask, reason: .studySession)

                    // Schedule spaced reviews when completing a study task
                    if taskId.hasPrefix("spaced-") {
                        // Completing a spaced review — mark it done in store
                        let reviewId = String(taskId.dropFirst("spaced-".count))
                        SpacedReviewStore.complete(reviewId: reviewId)
                    } else if task.type == .review || task.type == .reading {
                        // Completing a study block — schedule future spaced reviews
                        let topic = task.theme ?? task.subject
                        SpacedReviewStore.scheduleReview(subject: task.subject, topic: topic)
                    }
                }
                HapticManager.shared.success()
                updateProgress()
                StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
                StudyWidgetDataBridge.syncTodayPlan(days)
                return
            }
        }
    }

    // MARK: - Task Editing

    func addTask(_ task: StudyTask, toDayIndex dayIndex: Int) {
        guard dayIndex >= 0, dayIndex < days.count else { return }
        days[dayIndex].tasks.append(task)
        days[dayIndex].totalMinutes += task.estimatedMinutes
        updateProgress()
        StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
        StudyWidgetDataBridge.syncTodayPlan(days)
        HapticManager.shared.success()
    }

    func updateTask(_ task: StudyTask, inDayIndex dayIndex: Int) {
        guard dayIndex >= 0, dayIndex < days.count else { return }
        if let taskIndex = days[dayIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            let oldMinutes = days[dayIndex].tasks[taskIndex].estimatedMinutes
            days[dayIndex].tasks[taskIndex] = task
            days[dayIndex].totalMinutes += (task.estimatedMinutes - oldMinutes)
            updateProgress()
            StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
            StudyWidgetDataBridge.syncTodayPlan(days)
        }
    }

    func deleteTask(_ taskId: String, fromDayIndex dayIndex: Int) {
        guard dayIndex >= 0, dayIndex < days.count else { return }
        if let taskIndex = days[dayIndex].tasks.firstIndex(where: { $0.id == taskId }) {
            let task = days[dayIndex].tasks[taskIndex]
            days[dayIndex].totalMinutes -= task.estimatedMinutes
            days[dayIndex].tasks.remove(at: taskIndex)
            updateProgress()
            StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
            StudyWidgetDataBridge.syncTodayPlan(days)
            HapticManager.shared.notification(.warning)
        }
    }

    func dayIndex(for date: Date) -> Int? {
        let calendar = Calendar.current
        return days.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) })
    }

    // MARK: - Auto-migration

    private func autoMigrateUncompletedTasks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Guard: only run once per day, namespaced per user
        let uid = SupabaseManager.shared.currentUser?.id ?? "local"
        let migrationKey = "lastMigrationDate_\(uid)"
        if let lastRun = UserDefaults.standard.object(forKey: migrationKey) as? Date,
           calendar.isDate(lastRun, inSameDayAs: today) {
            return
        }

        var migrated = 0

        // Find today's index in current week
        guard let todayIndex = days.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) else {
            return
        }

        // Scan past days in current week (offset 0 only to keep scope manageable)
        for dayIndex in 0..<todayIndex {
            let pastDay = days[dayIndex]
            guard calendar.startOfDay(for: pastDay.date) < today else { continue }

            let uncompleted = pastDay.tasks.filter { !$0.completed && !$0.id.hasPrefix("spaced-") && !$0.id.hasPrefix("review-") }
            for task in uncompleted {
                // Build migrated copy
                var migratedTask = task
                migratedTask = StudyTask(
                    id: "migrated-\(task.id)",
                    title: task.title,
                    subject: task.subject,
                    type: task.type,
                    dueDate: today,
                    completed: false,
                    estimatedMinutes: task.estimatedMinutes,
                    theme: task.theme,
                    topics: task.topics
                )

                // Append to today's tasks (avoid duplicates)
                let alreadyThere = days[todayIndex].tasks.contains(where: { $0.id == migratedTask.id })
                if !alreadyThere {
                    days[todayIndex].tasks.append(migratedTask)
                    days[todayIndex].totalMinutes += migratedTask.estimatedMinutes
                    migrated += 1
                }

                // Remove original from past day so it won't inflate progress
                if let origIndex = days[dayIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                    days[dayIndex].totalMinutes -= days[dayIndex].tasks[origIndex].estimatedMinutes
                    days[dayIndex].tasks.remove(at: origIndex)
                }
            }
        }

        if migrated > 0 {
            migratedTasksCount = migrated
            StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
            updateProgress()
            UserDefaults.standard.set(today, forKey: migrationKey)
        }
    }

    private func updateProgress() {
        let totalMinutes = days.reduce(0) { $0 + $1.totalMinutes }
        let completedMinutes = days.reduce(0) { $0 + $1.completedMinutes }
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

            return DayPlan(date: date, tasks: orderedTasks, totalMinutes: totalMinutes)
        }

        updateProgress()
    }

    private func buildWeeklyAllocation() -> [String: Int] {
        let studyHoursPerDay = max(UserDefaults.standard.integer(forKey: "studyHoursPerDay"), 1)
        let weeklyMinutes = VelocityTracker.shared.adjustedMinutesForWeek(declaredDailyHours: studyHoursPerDay)

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

        // Apply placement test weights: fraco subjects get extra time, forte subjects less.
        let placementWeights = PlacementTestStore.shared.priorityWeights()
        if !placementWeights.isEmpty {
            let totalBefore = Double(allocation.values.reduce(0, +))

            var weighted: [String: Double] = [:]
            for subject in ordered {
                let base = Double(allocation[subject] ?? minPerSubject)
                let multiplier = placementWeights[subject] ?? 1.0
                weighted[subject] = base * multiplier
            }

            let totalAfter = weighted.values.reduce(0, +)
            let scaleFactor = totalAfter > 0 ? totalBefore / totalAfter : 1.0
            for subject in ordered {
                let scaled = (weighted[subject] ?? Double(minPerSubject)) * scaleFactor
                allocation[subject] = max(PlanDefaults.minBlockMinutes, Int(scaled.rounded()))
            }
        }

        // Apply active template subject weights (if present)
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "templateSubjectWeights"),
           let templateWeights = try? decoder.decode([String: Double].self, from: data) {
            let totalBefore = Double(allocation.values.reduce(0, +))
            var weighted: [String: Double] = [:]
            for subject in ordered {
                let base = Double(allocation[subject] ?? minPerSubject)
                let multiplier = templateWeights[subject] ?? 1.0
                weighted[subject] = base * multiplier
            }
            let totalAfter = weighted.values.reduce(0, +)
            let scaleFactor = totalAfter > 0 ? totalBefore / totalAfter : 1.0
            for subject in ordered {
                let scaled = (weighted[subject] ?? Double(minPerSubject)) * scaleFactor
                allocation[subject] = max(PlanDefaults.minBlockMinutes, Int(scaled.rounded()))
            }
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
        injectSpacedReviews(into: &updated)
        updated = updated.map { day in
            var copy = day
            copy.tasks = orderByPriority(copy.tasks)
            return copy
        }
        days = updated
        updateProgress()
        StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
    }

    private func injectSpacedReviews(into days: inout [DayPlan]) {
        let calendar = Calendar.current
        for dayIndex in days.indices {
            let dayDate = calendar.startOfDay(for: days[dayIndex].date)
            let reviews = SpacedReviewStore.reviewsForDate(dayDate)
            for entry in reviews {
                let taskId = "spaced-\(entry.review.id)"
                guard !days[dayIndex].tasks.contains(where: { $0.id == taskId }) else { continue }

                let task = StudyTask(
                    id: taskId,
                    title: "Revisão \(entry.review.label)",
                    subject: entry.subject,
                    type: .flashcards,
                    dueDate: entry.review.scheduledDate,
                    completed: entry.review.completed,
                    estimatedMinutes: 15,
                    theme: entry.topic,
                    topics: ["Revisão espaçada — \(entry.review.label) após estudo"]
                )
                days[dayIndex].tasks.insert(task, at: 0) // Reviews first
                days[dayIndex].totalMinutes += task.estimatedMinutes
            }
        }
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

// MARK: - DaySection

struct DaySection: View {
    let day: DayPlan
    var hasConflict: Bool = false
    let onToggleTask: (String) -> Void
    let onQuestions: (StudyTask) -> Void
    let onStudy: (StudyTask) -> Void
    let onEditTask: (StudyTask) -> Void
    let onDeleteTask: (String) -> Void
    let onAddTask: () -> Void
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button { withAnimation { isExpanded.toggle() } } label: {
                HStack {
                    VStack(alignment: .leading) {
                        HStack(spacing: Spacing.xs) {
                            Text(day.dayOfWeek)
                                .font(.resumed.caption)
                                .foregroundColor(day.isToday ? .resumed.gold : .resumed.gray)
                            if hasConflict {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.resumed.warning)
                            }
                        }
                        Text(day.dayNumber)
                            .font(.resumed.h3)
                            .foregroundColor(day.isToday ? .resumed.gold : .resumed.white)
                    }

                    Spacer()

                    if hasConflict {
                        Text("Sobrecarregado")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.resumed.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.resumed.warning.opacity(0.12))
                            .cornerRadius(CornerRadius.sm)
                    }

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
                if hasConflict {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.resumed.warning)
                        Text("Dia sobrecarregado — considere redistribuir")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.warning)
                    }
                    .padding(.horizontal, Spacing.xs)
                    .padding(.bottom, Spacing.xs)
                }

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
                        .contextMenu {
                            if !task.id.hasPrefix("spaced-") && !task.id.hasPrefix("review-") {
                                Button {
                                    onEditTask(task)
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    onDeleteTask(task.id)
                                } label: {
                                    Label("Remover", systemImage: "trash")
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if !task.id.hasPrefix("spaced-") && !task.id.hasPrefix("review-") {
                                Button(role: .destructive) {
                                    onDeleteTask(task.id)
                                } label: {
                                    Label("Remover", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                // Add Task button
                Button {
                    onAddTask()
                    HapticManager.shared.selection()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Adicionar tarefa")
                            .font(.resumed.bodySmall)
                    }
                    .foregroundColor(.resumed.gold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.sm)
                }
            }
        }
        .padding(Spacing.md)
        .background(day.isToday ? Color.resumed.gold.opacity(0.05) : Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - TaskRow

struct TaskRow: View {
    let task: StudyTask
    let onToggle: () -> Void
    let onQuestions: () -> Void
    let onStudy: () -> Void

    private var isSpacedReview: Bool {
        task.id.hasPrefix("spaced-") || task.id.hasPrefix("review-")
    }

    private var accentColor: Color {
        isSpacedReview ? .resumed.info : .resumed.gold
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Button(action: onToggle) {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: IconSize.lg))
                        .foregroundColor(task.completed ? accentColor : .resumed.gray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xs) {
                        if isSpacedReview {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 12))
                                .foregroundColor(.resumed.info)
                        }
                        if task.wasAutoMigrated == true {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.resumed.warning)
                        }
                        Text(task.subject)
                            .font(.resumed.body)
                            .foregroundColor(task.completed ? .resumed.gray : .resumed.white)
                            .strikethrough(task.completed)
                    }

                    HStack(spacing: Spacing.xs) {
                        if isSpacedReview {
                            Text(task.title)
                                .font(.resumed.caption)
                                .foregroundColor(.resumed.info)
                        }
                        if let theme = task.theme, !theme.isEmpty, theme != "Revisão" {
                            Text(theme)
                                .font(.resumed.caption)
                                .foregroundColor(.resumed.gray)
                        }
                        Text("• \(task.estimatedMinutes) min")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                }

                Spacer()

                if isSpacedReview {
                    Text("SRS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.resumed.info)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.resumed.info.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                }
            }

            if !isSpacedReview {
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
        }
        .padding(Spacing.sm)
        .background(isSpacedReview ? Color.resumed.info.opacity(0.03) : Color.resumed.blackTertiary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            isSpacedReview
                ? RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.resumed.info.opacity(0.15), lineWidth: 1)
                : nil
        )
    }
}

// MARK: - StudyDetailSheet

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
