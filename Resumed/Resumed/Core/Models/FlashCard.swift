//
//  FlashCard.swift
//  Resumed
//
//  Data Models - FlashCards with SM-2 Algorithm
//

import Foundation
import SwiftUI

// MARK: - FlashCard Model

struct FlashCard: Codable, Identifiable {
    let id: String
    var front: String
    var back: String
    var subject: String
    var tags: [String]

    // SM-2 Algorithm properties
    var easinessFactor: Double
    var interval: Int
    var repetitions: Int
    var nextReviewDate: Date
    var lastReviewDate: Date?

    init(
        id: String = UUID().uuidString,
        front: String,
        back: String,
        subject: String,
        tags: [String] = [],
        easinessFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0,
        nextReviewDate: Date = Date(),
        lastReviewDate: Date? = nil
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.subject = subject
        self.tags = tags
        self.easinessFactor = easinessFactor
        self.interval = interval
        self.repetitions = repetitions
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
    }
}

// MARK: - SM-2 Algorithm

struct SM2Algorithm {
    enum Quality: Int, CaseIterable {
        case errei = 0
        case dificil = 1
        case bom = 2
        case facil = 3

        var displayName: String {
            switch self {
            case .errei: return "Errei"
            case .dificil: return "Difícil"
            case .bom: return "Bom"
            case .facil: return "Fácil"
            }
        }

        var emoji: String {
            switch self {
            case .errei: return "😓"
            case .dificil: return "🤔"
            case .bom: return "😊"
            case .facil: return "🎯"
            }
        }

        // NOVO: SF Symbol icons (sem emojis)
        var icon: String {
            switch self {
            case .errei: return "xmark.circle.fill"
            case .dificil: return "exclamationmark.triangle.fill"
            case .bom: return "checkmark.circle.fill"
            case .facil: return "star.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .errei: return .resumed.error
            case .dificil: return .resumed.warning
            case .bom: return .resumed.success
            case .facil: return .resumed.gold
            }
        }

        var xpReward: Int {
            switch self {
            case .errei: return XPReward.flashcardErrei
            case .dificil: return XPReward.flashcardDificil
            case .bom: return XPReward.flashcardBom
            case .facil: return XPReward.flashcardFacil
            }
        }
    }

    static func applyReview(to card: inout FlashCard, quality: Quality) {
        let q = quality.rawValue

        // Update easiness factor
        let newEF = card.easinessFactor + (0.1 - (3 - Double(q)) * (0.08 + (3 - Double(q)) * 0.02))
        card.easinessFactor = max(1.3, newEF)

        // Update repetitions and interval
        if q < 2 {
            card.repetitions = 0
            card.interval = 1
        } else {
            card.repetitions += 1
            switch card.repetitions {
            case 1:
                card.interval = 1
            case 2:
                card.interval = 6
            default:
                card.interval = Int(Double(card.interval) * card.easinessFactor)
            }
        }

        // Set next review date
        card.lastReviewDate = Date()
        card.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: card.interval,
            to: Date()
        ) ?? Date()
    }
}

// MARK: - FlashCard API Models

struct FlashCardsDueResponse: Codable {
    let flashcards: [FlashCardDTO]
    let total: Int
}

struct FlashCardDTO: Codable {
    let id: String
    let front: String
    let back: String
    let subject: String
    let tags: [String]?
    let easinessFactor: Double?
    let interval: Int?
    let repetitions: Int?
    let nextReviewAt: Date?
    let lastReviewedAt: Date?

    func toFlashCard() -> FlashCard {
        FlashCard(
            id: id,
            front: front,
            back: back,
            subject: subject,
            tags: tags ?? [],
            easinessFactor: easinessFactor ?? 2.5,
            interval: interval ?? 0,
            repetitions: repetitions ?? 0,
            nextReviewDate: nextReviewAt ?? Date(),
            lastReviewDate: lastReviewedAt
        )
    }
}

struct FlashCardReviewRequest: Codable {
    let quality: Int
}

struct FlashCardReviewResponse: Codable {
    let success: Bool
    let nextReviewAt: Date
    let xpEarned: Int
}

struct CreateFlashCardRequest: Codable {
    let front: String
    let back: String
    let subject: String
    let tags: [String]
}
