//
//  QuestionSessionManager.swift
//  Resumed
//
//  Question session flow (Duolingo-style)
//

import Foundation
import Combine

@MainActor
final class QuestionSessionManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var questions: [Question] = []
    @Published var currentIndex = 0
    @Published var selectedOptionId: String?
    @Published var isAnswered = false
    @Published var isCorrect = false
    @Published var explanation = ""
    @Published var socialMessage = ""
    @Published var xpEarned = 0
    @Published var correctCount = 0

    private var sessionStart: Date?
    private var questionStart: Date?
    private let coreData = CoreDataManager.shared

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    func start(subject: String, count: Int) async {
        isLoading = true
        errorMessage = nil
        currentIndex = 0
        selectedOptionId = nil
        isAnswered = false
        isCorrect = false
        xpEarned = 0
        correctCount = 0
        sessionStart = Date()

        do {
            if APIClient.mode == .mock {
                questions = try await MockAPIClient.shared.getQuestions(subjects: [subject], count: count, difficulty: nil)
            } else {
                questions = try await APIClient.shared.getQuestions(subjects: [subject], count: count, difficulty: nil)
            }
            questionStart = Date()
        } catch {
            errorMessage = "Não foi possível carregar questões."
        }

        isLoading = false
    }

    func selectOption(_ optionId: String) {
        guard !isAnswered else { return }
        selectedOptionId = optionId
    }

    func confirmAnswer() {
        guard let question = currentQuestion, let selected = selectedOptionId else { return }
        guard !isAnswered else { return }

        isAnswered = true
        isCorrect = selected == question.correctOptionId
        explanation = question.explanation
        if isCorrect { correctCount += 1 }

        let elapsed = Int(Date().timeIntervalSince(questionStart ?? Date()))
        coreData.saveQuestionAnswer(
            questionId: question.id,
            selectedAnswer: selected,
            isCorrect: isCorrect,
            subject: question.subject,
            timeSpentSeconds: elapsed
        )

        GamificationManager.shared.recordQuestionAnswered(isCorrect: isCorrect)
        ProgressTracker.shared.recordQuestion(subject: question.subject, isCorrect: isCorrect)
        let xp = isCorrect ? XPReward.correctAnswer : XPReward.wrongAnswer
        xpEarned += xp
        GamificationManager.shared.addXP(xp, reason: .correctAnswer)

        let social = SocialStatsManager.shared.stats(for: question.subject, isCorrect: isCorrect)
        socialMessage = social.message

        questionStart = Date().addingTimeInterval(Double(elapsed))
    }

    func nextQuestion() {
        guard currentIndex + 1 < questions.count else { return }
        currentIndex += 1
        selectedOptionId = nil
        isAnswered = false
        isCorrect = false
        explanation = ""
        socialMessage = ""
        questionStart = Date()
    }

    func isFinished() -> Bool {
        currentIndex >= questions.count - 1 && isAnswered
    }
}
