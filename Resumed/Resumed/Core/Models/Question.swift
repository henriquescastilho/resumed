//
//  Question.swift
//  Resumed
//
//  Data Models - Questions & Answers
//

import Foundation

// MARK: - Question Model

struct Question: Codable, Identifiable {
    let id: String
    let statement: String
    let subject: String
    let topic: String?
    let difficulty: QuestionDifficulty
    let year: Int?
    let institution: String?
    let options: [QuestionOption]
    let correctOptionId: String
    let explanation: String
    let references: [String]?
    let tags: [String]?
    let source: String?

    // Local tracking
    var lastReviewed: Date?
    var nextReview: Date?
    var reviewCount: Int = 0
    var correctCount: Int = 0

    var text: String { statement }

    init(
        id: String,
        statement: String,
        options: [QuestionOption],
        correctOptionId: String,
        explanation: String,
        subject: String,
        topic: String? = nil,
        difficulty: QuestionDifficulty = .medium,
        source: String? = nil
    ) {
        self.id = id
        self.statement = statement
        self.options = options
        self.correctOptionId = correctOptionId
        self.explanation = explanation
        self.subject = subject
        self.topic = topic
        self.difficulty = difficulty
        self.source = source
        self.year = nil
        self.institution = nil
        self.references = nil
        self.tags = nil
    }
}

struct QuestionOption: Codable, Identifiable {
    let id: String
    let text: String

    init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

enum QuestionDifficulty: String, Codable, CaseIterable {
    case all = "all"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    var displayName: String {
        switch self {
        case .all: return "Todas"
        case .easy: return "Fácil"
        case .medium: return "Médio"
        case .hard: return "Difícil"
        }
    }
}

// MARK: - Answer Models

struct AnswerRequest: Codable {
    let optionId: Int
    let timeSpent: Int
}

struct AnswerResult: Codable {
    let questionId: String
    let isCorrect: Bool
    let correctOption: Int
    let explanation: String?
    let xpEarned: Int
    let streak: Int
}

// MARK: - Study Session

struct StudySession: Codable, Identifiable {
    let id: String
    var startTime: Date
    var endTime: Date?
    var questionsAnswered: Int
    var correctAnswers: Int
    var xpEarned: Int
    var subject: String?

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }
}

// MARK: - XP System

struct XPReward {
    static let correctAnswer = 15
    static let wrongAnswer = 5
    static let flashcardErrei = 5
    static let flashcardDificil = 10
    static let flashcardBom = 15
    static let flashcardFacil = 20
    static let completeTask = 50
    static let dailyGoal = 100
    static let examComplete = 200
    static let dailyStreak = 25
}

// MARK: - Level System

struct LevelSystem {
    static func xpForLevel(_ level: Int) -> Int {
        return Int(1000.0 * pow(Double(level), 1.5))
    }

    static func levelForXP(_ xp: Int) -> Int {
        var level = 1
        var totalXP = 0
        while totalXP + xpForLevel(level) <= xp {
            totalXP += xpForLevel(level)
            level += 1
        }
        return level
    }

    static func titleForLevel(_ level: Int) -> String {
        switch level {
        case 1...5: return "Residente Jr"
        case 6...10: return "Residente Sênior"
        case 11...20: return "Residente Master"
        case 21...30: return "R2"
        case 31...50: return "R3"
        default: return "Especialista"
        }
    }
}
