//
//  SocialStatsManager.swift
//  Resumed
//
//  Real social stats based on user's personal accuracy per subject
//

import Foundation

struct SocialStatsResult {
    let percentCorrect: Int
    let message: String
}

@MainActor
struct SocialStatsManager {
    static let shared = SocialStatsManager()

    private init() {}

    func stats(for subject: String, isCorrect: Bool) -> SocialStatsResult {
        let snapshot = ProgressTracker.shared.snapshot()
        let subjectProgress = snapshot.subjectStats[subject]
        let accuracy = Int(subjectProgress?.accuracy ?? 0)
        let message = buildMessage(accuracy: accuracy, isCorrect: isCorrect, subject: subject)
        return SocialStatsResult(percentCorrect: accuracy, message: message)
    }

    private func buildMessage(accuracy: Int, isCorrect: Bool, subject: String) -> String {
        if isCorrect {
            if accuracy > 0 {
                return "Sua acurácia em \(subject): \(accuracy)%"
            }
            return "Boa! Continue praticando para acompanhar sua evolução."
        }

        if accuracy > 0 {
            return "Sua acurácia em \(subject): \(accuracy)%. Continue praticando!"
        }
        return "Não desanime. Revisão é o caminho para a aprovação."
    }
}
