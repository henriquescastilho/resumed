//
//  QuestionSessionManager.swift
//  Resumed
//
//  Question session flow (Duolingo-style)
//

import Foundation
import Combine

private func todayDateKey() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: Date())
}

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
    @Published var showAutoCardToast = false

    // Timed exam mode
    @Published var isTimedMode = false
    @Published var totalTimeRemaining: Int = 0
    @Published var timedExamFinished = false
    var examStartDate: Date?
    var durationSeconds: Int = 0
    var perQuestionTimes: [String: Int] = [:]
    var perSubjectResults: [String: (correct: Int, total: Int)] = [:]
    private var timerTask: Task<Void, Never>?
    private var examXPAwarded = false

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

        // Track per-question time and per-subject results for timed mode
        if isTimedMode {
            perQuestionTimes[question.id] = elapsed
            var subjectResult = perSubjectResults[question.subject] ?? (correct: 0, total: 0)
            subjectResult.total += 1
            if isCorrect { subjectResult.correct += 1 }
            perSubjectResults[question.subject] = subjectResult
        }

        coreData.saveQuestionAnswer(
            questionId: question.id,
            selectedAnswer: selected,
            isCorrect: isCorrect,
            subject: question.subject,
            timeSpentSeconds: elapsed
        )

        UsageLimiter.shared.incrementQuestions()
        GamificationManager.shared.recordQuestionAnswered(isCorrect: isCorrect)
        ProgressTracker.shared.recordQuestion(subject: question.subject, isCorrect: isCorrect)
        let xp = isCorrect ? XPReward.correctAnswer : XPReward.wrongAnswer
        xpEarned += xp
        GamificationManager.shared.addXP(xp, reason: .correctAnswer)

        let social = SocialStatsManager.shared.stats(for: question.subject, isCorrect: isCorrect)
        socialMessage = social.message

        questionStart = Date().addingTimeInterval(Double(elapsed))

        // Write to UserDefaults keys consumed by DailyChallengesView
        let todayKey = todayDateKey()
        let ud = UserDefaults.standard

        if isCorrect {
            let correctKey = "questions_correct_today_\(todayKey)"
            ud.set(ud.integer(forKey: correctKey) + 1, forKey: correctKey)

            let streakKey = "correct_streak_today_\(todayKey)"
            ud.set(ud.integer(forKey: streakKey) + 1, forKey: streakKey)
        } else {
            // A wrong answer resets the consecutive-correct streak for today
            let streakKey = "correct_streak_today_\(todayKey)"
            ud.set(0, forKey: streakKey)
        }

        // Track distinct subjects studied today
        let subjectsKey = "subjects_studied_today_\(todayKey)"
        var subjectsSet = Set(ud.stringArray(forKey: "\(subjectsKey)_list") ?? [])
        let wasNew = !subjectsSet.contains(question.subject)
        subjectsSet.insert(question.subject)
        ud.set(Array(subjectsSet), forKey: "\(subjectsKey)_list")
        if wasNew {
            ud.set(subjectsSet.count, forKey: subjectsKey)
        }

        // Auto-generate ResuCard from wrong answers
        if !isCorrect, !question.explanation.isEmpty {
            let autoCardId = "auto_\(question.id)"
            if coreData.fetchFlashCard(id: autoCardId) == nil {
                let front = String(question.statement.prefix(200))
                let correctOption = question.options.first(where: { $0.id == question.correctOptionId })
                let back = "**Resposta correta:** \(correctOption?.text ?? question.correctOptionId)\n\n\(question.explanation)"
                let card = FlashCard(
                    id: autoCardId,
                    front: front,
                    back: back,
                    subject: question.subject,
                    tags: ["auto", "erros"]
                )
                coreData.saveFlashCard(card)
                showAutoCardToast = true
            }
        }
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

    // MARK: - Timed Exam Mode

    func awardExamXPOnce() {
        guard !examXPAwarded else { return }
        examXPAwarded = true
        GamificationManager.shared.addXP(XPReward.examComplete, reason: .correctAnswer)
    }

    func startTimedMode(durationSeconds: Int) {
        self.isTimedMode = true
        self.durationSeconds = durationSeconds
        self.examStartDate = Date()
        self.totalTimeRemaining = durationSeconds
        self.perQuestionTimes = [:]
        self.perSubjectResults = [:]
        self.timedExamFinished = false
        self.examXPAwarded = false

        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self, !Task.isCancelled else { return }
                let elapsed = Int(Date().timeIntervalSince(self.examStartDate ?? Date()))
                let remaining = max(self.durationSeconds - elapsed, 0)
                self.totalTimeRemaining = remaining
                if remaining <= 0 {
                    self.autoSubmit()
                    return
                }
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func autoSubmit() {
        if !isAnswered {
            if selectedOptionId != nil {
                confirmAnswer()
            } else if let question = currentQuestion {
                // No selection — count as unanswered (wrong) in subject results
                var subjectResult = perSubjectResults[question.subject] ?? (correct: 0, total: 0)
                subjectResult.total += 1
                perSubjectResults[question.subject] = subjectResult
                isAnswered = true
            }
        }
        timedExamFinished = true
        stopTimer()
    }

    var formattedTimeRemaining: String {
        let h = totalTimeRemaining / 3600
        let m = (totalTimeRemaining % 3600) / 60
        let s = totalTimeRemaining % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    var totalElapsedFormatted: String {
        guard let start = examStartDate else { return "–" }
        let elapsed = Int(Date().timeIntervalSince(start))
        let h = elapsed / 3600
        let m = (elapsed % 3600) / 60
        if h > 0 {
            return "\(h)h\(String(format: "%02d", m))min"
        }
        return "\(m)min"
    }

    var totalDurationFormatted: String {
        let h = durationSeconds / 3600
        let m = (durationSeconds % 3600) / 60
        if h > 0 {
            return "\(h)h\(String(format: "%02d", m))min"
        }
        return "\(m)min"
    }
}
