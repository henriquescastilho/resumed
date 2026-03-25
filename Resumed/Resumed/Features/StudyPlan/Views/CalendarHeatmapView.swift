//
//  CalendarHeatmapView.swift
//  Resumed
//
//  Monthly heatmap showing study intensity per day
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class CalendarHeatmapViewModel: ObservableObject {
    @Published var monthOffset: Int = 0
    @Published var dailyMinutes: [Date: Int] = [:]
    @Published var selectedDay: Date?

    private let calendar = Calendar.current

    var displayMonth: Date {
        let today = Date()
        return calendar.date(byAdding: .month, value: monthOffset, to: today) ?? today
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayMonth).capitalized
    }

    /// All day cells for the month grid (including padding days from prev/next months)
    var gridDays: [Date?] {
        let firstOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: displayMonth)
        ) ?? displayMonth

        // weekday: Sunday=1...Saturday=7. We want Sunday as first column (index 0).
        let firstWeekday = (calendar.component(.weekday, from: firstOfMonth) - 1) // 0-based

        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let daysInMonth = range.count

        var cells: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in 1...daysInMonth {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
            cells.append(date)
        }

        // Pad to complete the last row
        let remainder = cells.count % 7
        if remainder != 0 {
            cells += Array(repeating: nil, count: 7 - remainder)
        }

        return cells
    }

    func loadData() {
        // Scan week offsets that cover the current month
        let firstOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: displayMonth)
        ) ?? displayMonth
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!

        var result: [Date: Int] = [:]

        for dayIndex in 0..<range.count {
            guard let date = calendar.date(byAdding: .day, value: dayIndex, to: firstOfMonth) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            // Determine which weekOffset contains this date
            let weekOffset = weekOffsetFor(date: startOfDay)
            if let days = StudyPlanStore.shared.load(weekOffset: weekOffset) {
                for dayPlan in days {
                    if calendar.isDate(dayPlan.date, inSameDayAs: startOfDay) {
                        let completed = dayPlan.tasks
                            .filter { $0.completed }
                            .reduce(0) { $0 + $1.estimatedMinutes }
                        result[startOfDay] = (result[startOfDay] ?? 0) + completed
                    }
                }
            }
        }

        dailyMinutes = result
    }

    func previousMonth() {
        monthOffset -= 1
        loadData()
    }

    func nextMonth() {
        monthOffset += 1
        loadData()
    }

    func minutesFor(_ date: Date) -> Int {
        let key = Calendar.current.startOfDay(for: date)
        return dailyMinutes[key] ?? 0
    }

    func intensityColor(for date: Date) -> Color {
        let minutes = minutesFor(date)
        guard minutes > 0 else { return Color.resumed.blackTertiary }

        let maxMinutes = 240.0 // 4 hours = max intensity
        let ratio = min(Double(minutes) / maxMinutes, 1.0)

        // Interpolate from blackTertiary to gold
        return Color.resumed.gold.opacity(0.2 + ratio * 0.8)
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
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

struct CalendarHeatmapView: View {
    @StateObject private var viewModel = CalendarHeatmapViewModel()
    let onDaySelected: (Date) -> Void

    private let weekdayLabels = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 7)

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Month navigation header
            HStack {
                Button {
                    viewModel.previousMonth()
                    HapticManager.shared.selection()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.resumed.gold)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text(viewModel.monthTitle)
                    .font(.resumed.h4)
                    .foregroundColor(.resumed.white)

                Spacer()

                Button {
                    viewModel.nextMonth()
                    HapticManager.shared.selection()
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.resumed.gold)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, Spacing.md)

            // Weekday labels
            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Spacing.md)

            // Day cells
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(Array(viewModel.gridDays.enumerated()), id: \.offset) { _, optDate in
                    if let date = optDate {
                        DayCellView(
                            date: date,
                            color: viewModel.intensityColor(for: date),
                            isToday: viewModel.isToday(date),
                            minutes: viewModel.minutesFor(date)
                        )
                        .onTapGesture {
                            HapticManager.shared.selection()
                            viewModel.selectedDay = date
                            onDaySelected(date)
                        }
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)

            // Legend
            HStack(spacing: Spacing.sm) {
                Text("Menos")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)

                ForEach([0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { opacity in
                    Circle()
                        .fill(Color.resumed.gold.opacity(opacity))
                        .frame(width: 12, height: 12)
                }

                Text("Mais")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }
            .padding(.horizontal, Spacing.md)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

// MARK: - Day Cell

private struct DayCellView: View {
    let date: Date
    let color: Color
    let isToday: Bool
    let minutes: Int

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)

            if isToday {
                Circle()
                    .stroke(Color.resumed.gold, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }

            Text(dayNumber)
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                .foregroundColor(minutes > 0 ? .resumed.black : .resumed.white)
        }
        .frame(width: 36, height: 36)
    }
}
