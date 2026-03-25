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

    // MARK: - Phase 1 fields (optional, backward-compatible)
    var calendarEventId: String?    // EKEvent identifier after export
    var startTime: Date?            // Specific time within the day
    var wasAutoMigrated: Bool?      // true when auto-moved from previous day
    var originalDueDate: Date?      // date before migration

    enum TaskType: String, Codable {
        case review = "review"
        case practice = "practice"
        case flashcards = "flashcards"
        case reading = "reading"
        case video = "video"

        var displayName: String {
            switch self {
            case .review: return "Revisão"
            case .practice: return "Questões"
            case .flashcards: return "ResuCard"
            case .reading: return "Leitura"
            case .video: return "Vídeo"
            }
        }

        var icon: String {
            switch self {
            case .review: return "book.fill"
            case .practice: return "list.bullet.clipboard.fill"
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

    /// Computed from completed tasks — never stored, always accurate.
    var completedMinutes: Int {
        tasks.filter { $0.completed }.reduce(0) { $0 + $1.estimatedMinutes }
    }

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
        case date, tasks, totalMinutes
    }

    init(date: Date, tasks: [StudyTask], totalMinutes: Int) {
        self.date = date
        self.tasks = tasks
        self.totalMinutes = totalMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        tasks = try container.decode([StudyTask].self, forKey: .tasks)
        totalMinutes = try container.decode(Int.self, forKey: .totalMinutes)
        id = UUID()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(tasks, forKey: .tasks)
        try container.encode(totalMinutes, forKey: .totalMinutes)
    }

    mutating func recomputeTotalMinutes() {
        totalMinutes = tasks.reduce(0) { $0 + $1.estimatedMinutes }
    }
}

// MARK: - Spaced Review (Ebbinghaus curve)

struct SpacedReview: Codable, Identifiable {
    let id: String
    let subject: String
    let topic: String
    let originDate: Date          // when the topic was first studied
    var reviews: [ScheduledReview]

    struct ScheduledReview: Codable, Identifiable {
        let id: String
        let intervalDays: Int     // D+1, D+3, D+7, D+15, D+30
        let scheduledDate: Date
        var completed: Bool

        var label: String {
            switch intervalDays {
            case 1: return "24h"
            case 3: return "3 dias"
            case 7: return "7 dias"
            case 15: return "15 dias"
            case 30: return "30 dias"
            default: return "\(intervalDays)d"
            }
        }
    }

    /// Standard Ebbinghaus intervals
    static let intervals = [1, 3, 7, 15, 30]

    /// Create a full review schedule from when a topic was studied
    static func create(subject: String, topic: String, studiedOn: Date = Date()) -> SpacedReview {
        let calendar = Calendar.current
        let baseId = "\(subject)_\(topic)_\(dayKey(from: studiedOn))"
            .lowercased().replacingOccurrences(of: " ", with: "_")

        let reviews = intervals.compactMap { interval -> ScheduledReview? in
            guard let date = calendar.date(byAdding: .day, value: interval, to: studiedOn) else { return nil }
            return ScheduledReview(
                id: "\(baseId)_d\(interval)",
                intervalDays: interval,
                scheduledDate: date,
                completed: false
            )
        }

        return SpacedReview(
            id: baseId,
            subject: subject,
            topic: topic,
            originDate: studiedOn,
            reviews: reviews
        )
    }

    private static func dayKey(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

/// Persistence layer for spaced reviews
enum SpacedReviewStore {
    private static var key: String {
        let uid = SupabaseManager.shared.currentUser?.id ?? "local"
        return "spacedReviews_\(uid)"
    }

    static func load() -> [SpacedReview] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let reviews = try? JSONDecoder().decode([SpacedReview].self, from: data)
        else { return [] }
        return reviews
    }

    static func save(_ reviews: [SpacedReview]) {
        if let data = try? JSONEncoder().encode(reviews) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Schedule reviews for a newly studied topic
    static func scheduleReview(subject: String, topic: String) {
        var all = load()
        let matchKey = "\(subject)_\(topic)".lowercased()
        // Allow re-schedule if existing entry has all reviews completed
        if let existingIndex = all.firstIndex(where: { "\($0.subject)_\($0.topic)".lowercased() == matchKey }) {
            let allCompleted = all[existingIndex].reviews.allSatisfy { $0.completed }
            if !allCompleted { return }
            all.remove(at: existingIndex)
        }
        let review = SpacedReview.create(subject: subject, topic: topic)
        all.append(review)
        save(all)
    }

    /// Mark a specific review as completed
    static func complete(reviewId: String) {
        var all = load()
        for i in all.indices {
            if let j = all[i].reviews.firstIndex(where: { $0.id == reviewId }) {
                all[i].reviews[j].completed = true
            }
        }
        save(all)
    }

    /// Get all pending reviews for a date range
    static func pendingReviews(from startDate: Date, to endDate: Date) -> [SpacedReview.ScheduledReview] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        return load().flatMap { review in
            review.reviews.filter { scheduled in
                !scheduled.completed &&
                calendar.startOfDay(for: scheduled.scheduledDate) >= start &&
                calendar.startOfDay(for: scheduled.scheduledDate) <= end
            }
        }
    }

    /// Get reviews for a specific date, enriched with subject/topic info
    static func reviewsForDate(_ date: Date) -> [(review: SpacedReview.ScheduledReview, subject: String, topic: String)] {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)

        return load().flatMap { spaced in
            spaced.reviews
                .filter { !$0.completed && calendar.startOfDay(for: $0.scheduledDate) == target }
                .map { (review: $0, subject: spaced.subject, topic: spaced.topic) }
        }
    }

    /// Clean up old completed reviews (> 60 days ago)
    static func prune() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
        var all = load()
        all.removeAll { $0.originDate < cutoff && $0.reviews.allSatisfy { $0.completed } }
        save(all)
    }
}

// MARK: - Study Plan Template

struct StudyPlanTemplate: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let targetExam: String
    let weeklyHours: Int
    let subjectWeights: [String: Double]   // subject -> relative weight (0.5 to 2.0)
    let createdByUser: Bool
    var isActive: Bool
}

// MARK: - Velocity Record

struct VelocityRecord: Codable {
    let weekOffset: Int
    let plannedMinutes: Int
    let actualMinutes: Int
    let recordedAt: Date
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
