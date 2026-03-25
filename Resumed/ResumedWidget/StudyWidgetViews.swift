//
//  StudyWidgetViews.swift
//  ResumedWidget
//
//  View implementations for all three study widgets.
//  Uses Color(hex:) extension defined in ResumedWidget.swift.
//

import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Shared Helpers

private struct GoldLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.caption2, design: .monospaced))
            .fontWeight(.bold)
            .foregroundColor(Color(hex: "FFD700"))
            .tracking(1)
    }
}

private struct CircularProgressRing: View {
    let fraction: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "333333"), lineWidth: 4)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: min(fraction, 1))
                .stroke(
                    Color(hex: "FFD700"),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            Text("\(Int(fraction * 100))%")
                .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Next Task Widget View (systemSmall)

struct NextTaskWidgetView: View {
    let entry: NextTaskEntry

    var body: some View {
        ZStack {
            Color(hex: "000000")

            if entry.isEmpty {
                emptyView
            } else if entry.isCompleted {
                allDoneView
            } else {
                taskView
            }
        }
        .widgetBackground(Color(hex: "000000"))
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "888888"))
            Text("Nenhuma\ntarefa hoje")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "888888"))
        }
    }

    private var allDoneView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "10B981"))
            Text("Tudo\nconcluído!")
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
    }

    private var taskView: some View {
        VStack(alignment: .leading, spacing: 6) {
            GoldLabel(text: "PRÓXIMA TAREFA")

            Spacer()

            Text(entry.taskTitle)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            if !entry.taskTheme.isEmpty {
                Text(entry.taskTheme)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "888888"))
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 6) {
                Text("\(entry.taskMinutes) min")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "FFD700"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "FFD700").opacity(0.12))
                    .cornerRadius(4)

                Spacer()

                Image(systemName: "book.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "888888"))
            }
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "333333"), lineWidth: 1)
        )
    }
}

// MARK: - Day Progress Widget View (systemMedium)

struct DayProgressWidgetView: View {
    let entry: DayProgressEntry
    @Environment(\.widgetFamily) var family

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: entry.date).uppercased()
    }

    var body: some View {
        ZStack {
            Color(hex: "000000")

            if entry.totalCount == 0 {
                emptyView
            } else {
                HStack(spacing: 14) {
                    leftColumn
                    Divider()
                        .background(Color(hex: "333333"))
                    rightColumn
                }
                .padding(14)
            }
        }
        .widgetBackground(Color(hex: "000000"))
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "888888"))
            Text("Nenhuma tarefa\nno plano de hoje")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "888888"))
        }
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                GoldLabel(text: "HOJE")
                Text("•")
                    .font(.system(size: 8))
                    .foregroundColor(Color(hex: "888888"))
                Text(dateString)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(hex: "888888"))
            }

            Spacer()

            CircularProgressRing(fraction: entry.progressFraction, size: 62)

            Spacer()

            Text("\(entry.completedCount)/\(entry.totalCount) tarefas")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "888888"))

            if entry.remainingMinutes > 0 {
                Text("\(entry.remainingMinutes)min rest.")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "FFD700"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entry.tasks.prefix(4)) { task in
                taskRow(task)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func taskRow(_ task: DayProgressEntry.WidgetTask) -> some View {
        if #available(iOS 17.0, *) {
            Button(intent: CompleteStudyTaskIntent(taskId: task.id)) {
                taskRowContent(task)
            }
            .buttonStyle(.plain)
        } else {
            taskRowContent(task)
        }
    }

    private func taskRowContent(_ task: DayProgressEntry.WidgetTask) -> some View {
        HStack(spacing: 6) {
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(task.completed ? Color(hex: "10B981") : Color(hex: "888888"))

            VStack(alignment: .leading, spacing: 1) {
                Text(task.subject)
                    .font(.system(size: 11, weight: task.completed ? .regular : .medium))
                    .foregroundColor(task.completed ? Color(hex: "888888") : .white)
                    .lineLimit(1)
                    .strikethrough(task.completed, color: Color(hex: "888888"))

                Text("\(task.minutes) min")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Color(hex: "888888"))
            }

            Spacer()
        }
    }
}

// MARK: - Exam Countdown Widget View (systemSmall)

struct ExamCountdownWidgetView: View {
    let entry: ExamCountdownEntry

    var body: some View {
        ZStack {
            Color(hex: "000000")

            if entry.isEmpty {
                emptyView
            } else {
                countdownView
            }
        }
        .widgetBackground(Color(hex: "000000"))
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "888888"))
            Text("Configure\nsuas provas")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "888888"))
        }
    }

    private var countdownView: some View {
        VStack(spacing: 6) {
            GoldLabel(text: "FALTAM")

            Spacer()

            Text("\(max(entry.daysRemaining, 0))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: entry.urgencyColor))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("dias para")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "888888"))

            Text(entry.examName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)

            Spacer()
        }
        .padding(12)
    }
}

// MARK: - Study Lock Screen Views

struct StudyLockCircularView: View {
    let entry: DayProgressEntry

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 3)

            Circle()
                .trim(from: 0, to: min(entry.progressFraction, 1))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(entry.progressFraction * 100))%")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
    }
}

struct StudyLockRectangularView: View {
    let entry: NextTaskEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "book.fill")
                .font(.system(size: 12))
            if entry.isEmpty {
                Text("Sem tarefas")
                    .font(.system(size: 12))
            } else {
                Text("Próxima: \(entry.taskTitle) — \(entry.taskMinutes)min")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
        }
    }
}

struct StudyLockInlineView: View {
    let entry: DayProgressEntry

    var body: some View {
        if entry.totalCount > 0 {
            Text("\(entry.completedCount)/\(entry.totalCount) tarefas · \(entry.remainingMinutes)min restantes")
                .font(.system(size: 12))
        } else {
            Text("Sem tarefas no plano")
                .font(.system(size: 12))
        }
    }
}

// MARK: - containerBackground compatibility shim

extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self
        }
    }
}
