//
//  PlacementTestViewModel.swift
//  Resumed
//
//  Adaptive placement test session logic
//

import Foundation
import SwiftUI
import Combine

enum TestPhase {
    case intro, testing, results
}

@MainActor
final class PlacementTestViewModel: ObservableObject {

    @Published var phase: TestPhase = .intro
    @Published var currentQuestion: PlacementQuestion?
    @Published var selectedOptionId: String?
    @Published var isAnswered = false
    @Published var isCorrect = false
    @Published var answeredCount = 0
    @Published var totalExpected = 0
    @Published var result: PlacementTestResult?

    private var remainingSpecialties: [PlacementSpecialty] = []
    private var currentSpecialty: PlacementSpecialty?
    private var firstAnswerCorrect: Bool?
    private var isOnHardFollowUp = false
    private var specialtyLevels: [PlacementSpecialty: SpecialtyLevel] = [:]

    // MARK: - Start

    func startTest() {
        remainingSpecialties = PlacementSpecialty.allCases.shuffled()
        specialtyLevels = [:]
        answeredCount = 0
        totalExpected = PlacementSpecialty.allCases.count * 2
        phase = .testing
        advanceToNextQuestion()
    }

    func skip() {
        UserDefaults.standard.set(true, forKey: PlacementTestStore.hasTakenTestKey)
    }

    // MARK: - Answer Flow

    func selectOption(_ id: String) {
        guard !isAnswered else { return }
        selectedOptionId = id
        HapticManager.shared.selection()
    }

    func confirmAnswer() {
        guard let question = currentQuestion, let selected = selectedOptionId, !isAnswered else { return }

        isAnswered = true
        isCorrect = selected == question.correctOptionId

        HapticManager.shared.notification(isCorrect ? .success : .error)

        if !isOnHardFollowUp {
            firstAnswerCorrect = isCorrect
        } else {
            guard let specialty = currentSpecialty else { return }
            specialtyLevels[specialty] = isCorrect ? .forte : .medio
        }

        answeredCount += 1
    }

    func nextQuestion() {
        guard isAnswered, let specialty = currentSpecialty else { return }

        if !isOnHardFollowUp {
            if firstAnswerCorrect == true {
                isOnHardFollowUp = true
                loadQuestion(specialty: specialty, difficulty: .hard)
            } else {
                specialtyLevels[specialty] = .fraco
                totalExpected -= 1
                moveToNextSpecialty()
            }
        } else {
            moveToNextSpecialty()
        }
    }

    var progress: Double {
        guard totalExpected > 0 else { return 0 }
        return Double(answeredCount) / Double(totalExpected)
    }

    // MARK: - Private

    private func advanceToNextQuestion() {
        guard !remainingSpecialties.isEmpty else {
            computeResult()
            return
        }
        let specialty = remainingSpecialties.removeFirst()
        currentSpecialty = specialty
        firstAnswerCorrect = nil
        isOnHardFollowUp = false
        loadQuestion(specialty: specialty, difficulty: .medium)
    }

    private func moveToNextSpecialty() {
        currentSpecialty = nil
        firstAnswerCorrect = nil
        isOnHardFollowUp = false
        advanceToNextQuestion()
    }

    private func loadQuestion(specialty: PlacementSpecialty, difficulty: QuestionDifficulty) {
        // First try the real question bank; fall back to embedded pool if unavailable
        let bankQuestions = QuestionBankLoader.shared.allQuestions()
            .filter { $0.subject == specialty.rawValue }
            .shuffled()

        if !bankQuestions.isEmpty {
            let bankQuestion = bankQuestions.first!
            let placement = PlacementQuestion(
                id: bankQuestion.id,
                specialty: specialty,
                difficulty: difficulty,
                statement: bankQuestion.statement,
                options: bankQuestion.options,
                correctOptionId: bankQuestion.correctOptionId,
                explanation: bankQuestion.explanation
            )
            withAnimation(.easeInOut(duration: 0.25)) {
                currentQuestion = placement
                selectedOptionId = nil
                isAnswered = false
                isCorrect = false
            }
            return
        }

        // Fallback: embedded hardcoded pool
        let pool = PlacementQuestion.questions(for: specialty, difficulty: difficulty)
        guard let question = pool.randomElement() else {
            if difficulty == .medium { specialtyLevels[specialty] = .medio; totalExpected -= 1 }
            moveToNextSpecialty()
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentQuestion = question
            selectedOptionId = nil
            isAnswered = false
            isCorrect = false
        }
    }

    private func computeResult() {
        for specialty in PlacementSpecialty.allCases where specialtyLevels[specialty] == nil {
            specialtyLevels[specialty] = .medio
        }

        let ordered = PlacementSpecialty.allCases.sorted { a, b in
            (specialtyLevels[a]?.studyWeight ?? 1.0) > (specialtyLevels[b]?.studyWeight ?? 1.0)
        }

        let levels = Dictionary(uniqueKeysWithValues: specialtyLevels.map { ($0.key.rawValue, $0.value.rawValue) })
        let priority = ordered.map { $0.rawValue }

        let testResult = PlacementTestResult(completedAt: Date(), specialtyLevels: levels, suggestedPriority: priority)
        self.result = testResult
        PlacementTestStore.shared.saveResult(testResult)
        UserDefaults.standard.set(priority, forKey: "subjectPriority")

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { phase = .results }
        HapticManager.shared.celebration()
    }
}
