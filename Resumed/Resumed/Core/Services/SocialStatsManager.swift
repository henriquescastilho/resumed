//
//  SocialStatsManager.swift
//  Resumed
//
//  Mock social stats for questions
//

import Foundation

struct SocialStatsResult {
    let percentCorrect: Int
    let message: String
}

struct SocialStatsManager {
    static let shared = SocialStatsManager()

    private init() {}

    func stats(for subject: String, isCorrect: Bool) -> SocialStatsResult {
        let percent = mockPercentCorrect(for: subject)
        let message = buildMessage(percentCorrect: percent, isCorrect: isCorrect)
        return SocialStatsResult(percentCorrect: percent, message: message)
    }

    private func mockPercentCorrect(for subject: String) -> Int {
        let seed = subject.unicodeScalars.map { Int($0.value) }.reduce(0, +)
        let value = (seed % 60) + 30
        return min(max(value, 10), 90)
    }

    private func buildMessage(percentCorrect: Int, isCorrect: Bool) -> String {
        if isCorrect {
            if percentCorrect < 50 {
                let wrong = 100 - percentCorrect
                return "\(wrong)% das pessoas erraram e você acertou."
            }
            return "\(percentCorrect)% das pessoas acertaram essa questão."
        }

        if percentCorrect > 70 {
            return "\(percentCorrect)% das pessoas acertaram. Vamos revisar esse tema."
        }
        return "Muita gente também errou. Revisão rápida ajuda bastante."
    }
}
