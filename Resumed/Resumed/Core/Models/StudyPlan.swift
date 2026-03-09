//
//  StudyPlan.swift
//  Resumed
//
//  Data Models - Study Plan
//

import Foundation

// MARK: - Study Plan

struct StudyPlan: Codable {
    let id: String
    let userId: String
    let startDate: Date
    let targetExamDate: Date
    let targetExam: String
    var tasks: [StudyTask]
    var subjectPlans: [SubjectPlan]
    let createdAt: Date
    let updatedAt: Date
}

struct SubjectPlan: Codable, Identifiable {
    let id: String
    let subject: String
    var totalHours: Int
    var completedHours: Int
    let themes: [String]

    var progress: Double {
        guard totalHours > 0 else { return 0 }
        return Double(completedHours) / Double(totalHours)
    }
}

// MARK: - Study Task

struct StudyTask: Codable, Identifiable {
    let id: String
    let title: String
    let subject: String
    let type: TaskType
    let dueDate: Date
    var completed: Bool
    let estimatedMinutes: Int
    let theme: String?
    let topics: [String]?

    enum TaskType: String, Codable {
        case review = "review"
        case practice = "practice"
        case flashcards = "flashcards"
        case reading = "reading"
        case video = "video"

        var displayName: String {
            switch self {
            case .review: return "Revisão"
            case .practice: return "Revisão"
            case .flashcards: return "ResuCard"
            case .reading: return "Leitura"
            case .video: return "Vídeo"
            }
        }

        var icon: String {
            switch self {
            case .review: return "book.fill"
            case .practice: return "book.fill"
            case .flashcards: return "rectangle.stack.fill"
            case .reading: return "doc.text.fill"
            case .video: return "play.rectangle.fill"
            }
        }
    }
}

// MARK: - Day Plan

struct DayPlan: Identifiable, Codable {
    var id: UUID = UUID()
    let date: Date
    var tasks: [StudyTask]
    var totalMinutes: Int
    var completedMinutes: Int

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).capitalized
    }

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var progress: Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(completedMinutes) / Double(totalMinutes)
    }

    enum CodingKeys: String, CodingKey {
        case date, tasks, totalMinutes, completedMinutes
    }

    init(date: Date, tasks: [StudyTask], totalMinutes: Int, completedMinutes: Int) {
        self.date = date
        self.tasks = tasks
        self.totalMinutes = totalMinutes
        self.completedMinutes = completedMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        tasks = try container.decode([StudyTask].self, forKey: .tasks)
        totalMinutes = try container.decode(Int.self, forKey: .totalMinutes)
        completedMinutes = try container.decode(Int.self, forKey: .completedMinutes)
        id = UUID()
    }
}

// MARK: - Week Navigator

struct WeekNavigator {
    static func weekDateRange(for offset: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = Date()

        guard let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) else {
            return (today, today)
        }

        guard let offsetStart = calendar.date(byAdding: .weekOfYear, value: offset, to: weekStart),
              let offsetEnd = calendar.date(byAdding: .day, value: 6, to: offsetStart) else {
            return (today, today)
        }

        return (offsetStart, offsetEnd)
    }

    static func formatWeekRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")

        formatter.dateFormat = "d"
        let startDay = formatter.string(from: start)

        formatter.dateFormat = "d MMM"
        let endFormatted = formatter.string(from: end)

        return "\(startDay) - \(endFormatted)"
    }
}
