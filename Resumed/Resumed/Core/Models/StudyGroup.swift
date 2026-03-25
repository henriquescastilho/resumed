//
//  StudyGroup.swift
//  Resumed
//
//  Models for Study Groups and Challenges (Phase 4 - Social)
//

import Foundation

// MARK: - Study Group

struct StudyGroup: Codable, Identifiable {
    let id: String
    let name: String
    let ownerId: String
    var memberIds: [String]
    var memberNames: [String]
    let createdAt: Date
    var inviteCode: String
}

// MARK: - Group Challenge

struct GroupChallenge: Codable, Identifiable {
    let id: String
    let groupId: String
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    var entries: [ChallengeEntry]
    let metric: ChallengeMetric
    var isActive: Bool

    var daysRemaining: Int {
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: endDate)
        return max(0, diff.day ?? 0)
    }

    var hasEnded: Bool {
        Date() > endDate
    }

    enum ChallengeMetric: String, Codable, CaseIterable {
        case studyMinutes = "Minutos de Estudo"
        case questionsAnswered = "Questões Respondidas"
        case tasksCompleted = "Tarefas Concluídas"
        case xpEarned = "XP Ganho"

        var icon: String {
            switch self {
            case .studyMinutes: return "clock.fill"
            case .questionsAnswered: return "checkmark.circle.fill"
            case .tasksCompleted: return "list.bullet.circle.fill"
            case .xpEarned: return "star.fill"
            }
        }

        var accentColor: String {
            switch self {
            case .studyMinutes: return "warning"
            case .questionsAnswered: return "info"
            case .tasksCompleted: return "success"
            case .xpEarned: return "gold"
            }
        }
    }
}

// MARK: - Challenge Entry

struct ChallengeEntry: Codable, Identifiable {
    let id: String
    let userId: String
    var displayName: String
    var score: Int
    var lastUpdated: Date
}
