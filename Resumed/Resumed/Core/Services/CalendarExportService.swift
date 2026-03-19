//
//  CalendarExportService.swift
//  Resumed
//
//  Generates ICS files and week-plan images for sharing.
//

import UIKit
import SwiftUI

final class CalendarExportService {
    static let shared = CalendarExportService()
    private init() {}

    // MARK: - ICS Generation

    /// Builds a complete iCalendar (.ics) string from an array of DayPlans.
    func generateICS(for days: [DayPlan]) -> String {
        var lines: [String] = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//Resumed//Study Plan//PT",
            "CALSCALE:GREGORIAN",
            "METHOD:PUBLISH"
        ]

        for day in days {
            // Start study blocks at 08:00, stacking them sequentially
            var cursor: Date = {
                let calendar = Calendar.current
                var comps = calendar.dateComponents([.year, .month, .day], from: day.date)
                comps.hour = 8
                comps.minute = 0
                comps.second = 0
                return calendar.date(from: comps) ?? day.date
            }()

            for task in day.tasks {
                let startDate: Date
                if let taskStart = task.startTime {
                    startDate = taskStart
                } else {
                    startDate = cursor
                }
                let endDate = startDate.addingTimeInterval(Double(task.estimatedMinutes) * 60)

                let dtStart = icsDate(startDate)
                let dtEnd = icsDate(endDate)
                let summary = "[\(task.subject)] \(task.theme ?? task.type.displayName)"
                let description = "\(task.type.displayName) • \(task.estimatedMinutes) min"
                let uid = "\(task.id)@resumed.app"

                lines += [
                    "BEGIN:VEVENT",
                    "DTSTART:\(dtStart)",
                    "DTEND:\(dtEnd)",
                    "SUMMARY:\(icsEscape(summary))",
                    "DESCRIPTION:\(icsEscape(description))",
                    "UID:\(uid)",
                    "END:VEVENT"
                ]

                cursor = endDate
            }
        }

        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\r\n")
    }

    /// Writes the ICS content to a temporary file and returns its URL for the share sheet.
    func exportICSFile(for days: [DayPlan]) -> URL? {
        let content = generateICS(for: days)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("plano_resumo.ics")
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    // MARK: - Week Image Rendering (iOS 16+)

    /// Renders a snapshot of the week plan as a UIImage using SwiftUI ImageRenderer.
    @MainActor
    func renderWeekAsImage(days: [DayPlan], weekRange: String) -> UIImage? {
        if #available(iOS 16.0, *) {
            let view = WeekPlanSnapshotView(days: days, weekRange: weekRange)
            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage
        }
        return nil
    }

    // MARK: - Helpers

    private func icsDate(_ date: Date) -> String {
        // Format: 20260318T080000Z (ICS standard requires UTC)
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withYear, .withMonth, .withDay, .withTime]
        basic.timeZone = TimeZone(secondsFromGMT: 0)
        return basic.string(from: date)
    }

    private func icsEscape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

// MARK: - Week Plan Snapshot View (used by ImageRenderer)

struct WeekPlanSnapshotView: View {
    let days: [DayPlan]
    let weekRange: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RESUMED")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.28))
                    Text("Plano de Estudos • \(weekRange)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 28))
                    .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.28))
            }
            .padding(16)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))

            // Days grid
            VStack(spacing: 1) {
                ForEach(days.prefix(7)) { day in
                    HStack(spacing: 0) {
                        // Day label
                        VStack(spacing: 2) {
                            Text(day.dayOfWeek.prefix(3).uppercased())
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(day.isToday
                                    ? Color(red: 0.85, green: 0.70, blue: 0.28)
                                    : .white.opacity(0.5))
                            Text(day.dayNumber)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(day.isToday
                                    ? Color(red: 0.85, green: 0.70, blue: 0.28)
                                    : .white)
                        }
                        .frame(width: 48)
                        .padding(.vertical, 10)

                        // Tasks pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(day.tasks.prefix(5)) { task in
                                    Text(task.subject.components(separatedBy: " ").first ?? task.subject)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(task.completed
                                            ? Color.gray.opacity(0.4)
                                            : Color(red: 0.85, green: 0.70, blue: 0.28))
                                        .cornerRadius(4)
                                }
                                if day.tasks.count > 5 {
                                    Text("+\(day.tasks.count - 5)")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 8)
                        }

                        Spacer()

                        Text("\(day.totalMinutes)min")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.trailing, 8)
                    }
                    .background(day.isToday
                        ? Color(red: 0.85, green: 0.70, blue: 0.28).opacity(0.06)
                        : Color(red: 0.13, green: 0.13, blue: 0.13))
                }
            }

            // Footer
            HStack {
                Spacer()
                Text("Exportado pelo app Resumed")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
        .frame(width: 390)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .cornerRadius(16)
    }
}
