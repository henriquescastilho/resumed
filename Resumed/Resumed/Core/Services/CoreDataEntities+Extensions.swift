//
//  CoreDataEntities+Extensions.swift
//  Resumed
//
//  Helpers for Core Data generated classes
//

import Foundation
import CoreData

extension CDFlashCard {
    func toFlashCard() -> FlashCard {
        let tagsArray: [String]
        if let tags = tags as? [String] {
            tagsArray = tags
        } else if let tags = tags as? NSArray {
            tagsArray = tags.compactMap { $0 as? String }
        } else {
            tagsArray = []
        }

        return FlashCard(
            id: id ?? UUID().uuidString,
            front: front ?? "",
            back: back ?? "",
            subject: subject ?? "Geral",
            tags: tagsArray,
            easinessFactor: easeFactor,
            interval: Int(interval),
            repetitions: Int(repetitions),
            nextReviewDate: nextReviewDate ?? Date(),
            lastReviewDate: lastReviewedAt
        )
    }

    func update(from card: FlashCard) {
        easeFactor = card.easinessFactor
        interval = Int32(card.interval)
        repetitions = Int32(card.repetitions)
        nextReviewDate = card.nextReviewDate
        lastReviewedAt = card.lastReviewDate
        isSynced = false
    }
}

extension CDQuestion {
    func toQuestion() -> Question? {
        guard let data = optionsData,
              let options = try? JSONDecoder().decode([QuestionOption].self, from: data) else {
            return nil
        }
        return Question(
            id: id ?? UUID().uuidString,
            statement: statement ?? "",
            options: options,
            correctOptionId: correctOptionId ?? "",
            explanation: explanation ?? "",
            subject: subject ?? "Geral",
            source: source ?? ""
        )
    }
}
