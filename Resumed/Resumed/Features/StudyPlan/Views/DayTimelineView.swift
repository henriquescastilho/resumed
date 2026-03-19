//
//  DayTimelineView.swift
//  Resumed
//
//  Vertical timeline view for a single study day
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class DayTimelineViewModel: ObservableObject {
    @Published var dayPlan: DayPlan?
    @Published var targetDate: Date = Date()

    private let calendar = Calendar.current

    func loadDay(_ date: Date) {
        targetDate = date
        let weekOffset = weekOffsetFor(date: date)

        if let days = StudyPlanStore.shared.load(weekOffset: weekOffset) {
            dayPlan = days.first { calendar.isDate($0.date, inSameDayAs: date) }
        } else {
            dayPlan = nil
        }
    }

    func toggleTask(_ taskId: String) {
        guard let plan = dayPlan else { return }
        let weekOffset = weekOffsetFor(date: targetDate)

        if let taskIndex = dayPlan?.tasks.firstIndex(where: { $0.id == taskId }) {
            dayPlan?.tasks[taskIndex].completed.toggle()

            // Persist change back through the week store
            if var days = StudyPlanStore.shared.load(weekOffset: weekOffset) {
                for (dayIndex, day) in days.enumerated() {
                    if calendar.isDate(day.date, inSameDayAs: targetDate) {
                        days[dayIndex] = dayPlan ?? plan
                    }
                }
                StudyPlanStore.shared.save(weekOffset: weekOffset, days: days)
            }
        }
    }

    var tasksWithTime: [StudyTask] {
        (dayPlan?.tasks ?? []).filter { $0.startTime != nil }
    }

    var tasksWithoutTime: [StudyTask] {
        (dayPlan?.tasks ?? []).filter { $0.startTime == nil }
    }

    var dayTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: targetDate).capitalized
    }

    // MARK: - Private

    private func weekOffsetFor(date: Date) -> Int {
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

// MARK: - View

struct DayTimelineView: View {
    let date: Date
    let onToggleTask: ((String) -> Void)?

    @StateObject private var viewModel = DayTimelineViewModel()

    private let timelineStart = 6   // 06:00
    private let timelineEnd = 23    // 23:00
    private let hourHeight: CGFloat = 60

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Day title
                Text(viewModel.dayTitle)
                    .font(.resumed.h4)
                    .foregroundColor(.resumed.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.sm)

                // Tasks without start time
                if !viewModel.tasksWithoutTime.isEmpty {
                    unscheduledSection
                }

                // Timeline
                timelineSection
            }
            .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
        }
        .background(Color.resumed.black)
        .onAppear {
            viewModel.loadDay(date)
        }
        .onChange(of: date) { _, newDate in
            viewModel.loadDay(newDate)
        }
    }

    // MARK: - Unscheduled section

    private var unscheduledSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "clock.badge.questionmark")
                    .foregroundColor(.resumed.gray)
                    .font(.system(size: 14))
                Text("Sem horário")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }
            .padding(.horizontal, Spacing.md)

            ForEach(viewModel.tasksWithoutTime) { task in
                TimelineTaskBlock(task: task) {
                    toggleTask(task.id)
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Timeline section

    private var timelineSection: some View {
        ZStack(alignment: .topLeading) {
            // Hour lines
            VStack(spacing: 0) {
                ForEach(timelineStart...timelineEnd, id: \.self) { hour in
                    HStack(spacing: Spacing.sm) {
                        Text(String(format: "%02d:00", hour))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.resumed.gray)
                            .frame(width: 44, alignment: .trailing)

                        Rectangle()
                            .fill(Color.resumed.border)
                            .frame(height: 1)
                    }
                    .frame(height: hourHeight)
                }
            }
            .padding(.horizontal, Spacing.md)

            // Task blocks overlaid on timeline
            ForEach(viewModel.tasksWithTime) { task in
                if let startTime = task.startTime {
                    let offset = timeOffset(for: startTime)
                    let blockHeight = max(40, CGFloat(task.estimatedMinutes) / 60.0 * hourHeight)

                    TimelineTaskBlock(task: task) {
                        toggleTask(task.id)
                    }
                    .frame(height: blockHeight)
                    .padding(.leading, 60) // after the hour label column
                    .padding(.trailing, Spacing.md)
                    .offset(y: offset)
                }
            }
        }
    }

    // MARK: - Helpers

    private func timeOffset(for date: Date) -> CGFloat {
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        let totalMinutes = (hour - timelineStart) * 60 + minute
        return CGFloat(totalMinutes) / 60.0 * hourHeight
    }

    private func toggleTask(_ taskId: String) {
        viewModel.toggleTask(taskId)
        onToggleTask?(taskId)
        HapticManager.shared.success()
    }
}

// MARK: - Task Block

struct TimelineTaskBlock: View {
    let task: StudyTask
    let onToggle: () -> Void

    private var subjectColor: Color {
        switch task.subject {
        case "Clínica Médica": return .resumed.clinicaMedica
        case "Cirurgia Geral": return .resumed.cirurgia
        case "Pediatria": return .resumed.pediatria
        case "Ginecologia e Obstetrícia": return .resumed.ginecologia
        case "MFC", "Saúde Coletiva", "Medicina Preventiva": return .resumed.preventiva
        default: return .resumed.outras
        }
    }

    private var isSpacedReview: Bool {
        task.id.hasPrefix("spaced-") || task.id.hasPrefix("review-")
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Color accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(isSpacedReview ? Color.resumed.info : subjectColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    if isSpacedReview {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 10))
                            .foregroundColor(.resumed.info)
                    }
                    Text(task.subject)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(task.completed ? .resumed.gray : .resumed.white)
                        .strikethrough(task.completed)
                        .lineLimit(1)
                }

                if let theme = task.theme, !theme.isEmpty {
                    Text(theme)
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                        .lineLimit(1)
                }

                Text("\(task.estimatedMinutes) min")
                    .font(.system(size: 11))
                    .foregroundColor(.resumed.gray)
            }

            Spacer()

            // Completion toggle
            Button(action: onToggle) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.completed ? (isSpacedReview ? .resumed.info : .resumed.gold) : .resumed.gray)
            }
            .padding(.trailing, Spacing.xs)
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(isSpacedReview ? Color.resumed.info.opacity(0.08) : Color.resumed.blackSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    isSpacedReview ? Color.resumed.info.opacity(0.2) : (subjectColor.opacity(0.3)),
                    lineWidth: 1
                )
        )
    }
}
