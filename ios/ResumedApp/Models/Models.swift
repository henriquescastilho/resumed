import Foundation

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: String
    let full_name: String?
    let email: String
    let avatar_url: String?
    let profile_data: ProfileData
    let is_onboarding_complete: Bool
}

struct ProfileData: Codable {
    var target_exams: [String]?
    var available_days: [Int]?
    var hours_per_day: Int?
    var level_assessment: [String: String]?
    var target_exam_date: String?
}

// MARK: - Study Plan
struct StudyPlanTask: Codable, Identifiable {
    let id: String
    let date: String
    let title: String
    let status: TaskStatus
    let type: TaskType
    let time_estimated_min: Int
    let time_spent_min: Int
    let topic_id: String?
}

enum TaskStatus: String, Codable {
    case pending
    case done
    case skipped
    case review
}

enum TaskType: String, Codable {
    case theory
    case exercise
    case review
}
