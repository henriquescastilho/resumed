//
//  GamificationManager.swift
//  Resumed
//
//  Gamification System - XP, Levels, Badges
//

import SwiftUI
import Combine

@MainActor
class GamificationManager: ObservableObject {
    static let shared = GamificationManager()

    @Published var currentXP: Int = 0
    @Published var totalXP: Int = 0
    @Published var level: Int = 1
    @Published var streak: Int = 0
    @Published var unlockedBadges: Set<Badge> = []
    @Published var showLevelUpAnimation = false

    private init() {
        loadFromStorage()
    }

    func addXP(_ amount: Int, reason: XPReason) {
        let previousLevel = level
        totalXP += amount

        level = LevelSystem.levelForXP(totalXP)
        let xpForCurrentLevel = LevelSystem.xpForLevel(level)
        currentXP = totalXP - xpForCurrentLevel

        if level > previousLevel {
            showLevelUpAnimation = true
            HapticManager.shared.levelUp()
            checkLevelBadges()
        }

        checkBadgeProgress()
        saveToStorage()

        Task { await syncWithServer() }
    }

    func xpToNextLevel() -> Int {
        let nextLevelXP = LevelSystem.xpForLevel(level + 1)
        let currentLevelXP = LevelSystem.xpForLevel(level)
        return nextLevelXP - currentLevelXP
    }

    func progressToNextLevel() -> Double {
        let xpNeeded = xpToNextLevel()
        guard xpNeeded > 0 else { return 1.0 }
        return Double(currentXP) / Double(xpNeeded)
    }

    func updateStreak() {
        let lastStudyDate = UserDefaults.standard.object(forKey: "lastStudyDate") as? Date

        if let lastDate = lastStudyDate {
            let calendar = Calendar.current
            let daysSinceLastStudy = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0

            if daysSinceLastStudy == 1 {
                streak += 1
                addXP(XPReward.dailyStreak, reason: .streak)
                checkStreakBadges()
            } else if daysSinceLastStudy > 1 {
                streak = 1
            }
        } else {
            streak = 1
        }

        UserDefaults.standard.set(Date(), forKey: "lastStudyDate")
        saveToStorage()
    }

    func unlockBadge(_ badge: Badge) {
        guard !unlockedBadges.contains(badge) else { return }
        unlockedBadges.insert(badge)
        HapticManager.shared.celebration()
        saveToStorage()
    }

    private func checkBadgeProgress() {
        let totalQuestions = UserDefaults.standard.integer(forKey: "totalQuestionsAnswered")
        let totalFlashcards = UserDefaults.standard.integer(forKey: "totalFlashcardsReviewed")
        let examsCompleted = UserDefaults.standard.integer(forKey: "examsCompleted")

        // Question badges
        if totalQuestions >= 1 { unlockBadge(.firstQuestion) }
        if totalQuestions >= 100 { unlockBadge(.hundredQuestions) }
        if totalQuestions >= 500 { unlockBadge(.fiveHundredQuestions) }
        if totalQuestions >= 1000 { unlockBadge(.thousandQuestions) }
        if totalQuestions >= 5000 { unlockBadge(.fiveThousandQuestions) }

        // Flashcard badges
        if totalFlashcards >= 50 { unlockBadge(.flashcardFan) }
        if totalFlashcards >= 500 { unlockBadge(.memoryMaster) }
        if totalFlashcards >= 2000 { unlockBadge(.flashcardGuru) }

        // Exam badges
        if examsCompleted >= 1 { unlockBadge(.firstExamComplete) }
    }

    private func checkStreakBadges() {
        if streak >= 7 { unlockBadge(.weekStreak) }
        if streak >= 30 { unlockBadge(.monthStreak) }
        if streak >= 100 { unlockBadge(.hundredDayStreak) }
        if streak >= 365 { unlockBadge(.yearStreak) }

        // Check comeback badge (returned after 7+ days)
        let lastStudyDate = UserDefaults.standard.object(forKey: "previousLastStudyDate") as? Date
        if let lastDate = lastStudyDate {
            let daysSinceLastStudy = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysSinceLastStudy >= 7 { unlockBadge(.comeback) }
        }
    }

    private func checkLevelBadges() {
        if level >= 10 { unlockBadge(.levelTen) }
        if level >= 25 { unlockBadge(.levelTwentyFive) }
        if level >= 50 { unlockBadge(.levelFifty) }
        if level >= 100 { unlockBadge(.levelHundred) }
    }

    func checkTimeBadges() {
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())

        // Night owl (midnight to 4am)
        if hour >= 0 && hour < 4 { unlockBadge(.nightOwl) }

        // Early bird (4am to 6am)
        if hour >= 4 && hour < 6 { unlockBadge(.earlyBird) }

        // Weekend warrior (Saturday=7, Sunday=1)
        if weekday == 1 || weekday == 7 {
            let weekendStudyTime = UserDefaults.standard.integer(forKey: "weekendStudyMinutes")
            if weekendStudyTime >= 240 { unlockBadge(.weekendWarrior) }
        }
    }

    func checkPerfectScore(accuracy: Double) {
        if accuracy >= 100 { unlockBadge(.perfectScore) }
    }

    func checkExamAce(examsWithHighScore: Int) {
        if examsWithHighScore >= 10 { unlockBadge(.examAce) }
    }

    func recordFlashcardReview() {
        let total = UserDefaults.standard.integer(forKey: "totalFlashcardsReviewed") + 1
        UserDefaults.standard.set(total, forKey: "totalFlashcardsReviewed")
        checkBadgeProgress()
    }

    func recordQuestionAnswered(isCorrect: Bool) {
        let total = UserDefaults.standard.integer(forKey: "totalQuestionsAnswered") + 1
        UserDefaults.standard.set(total, forKey: "totalQuestionsAnswered")

        if isCorrect {
            let correct = UserDefaults.standard.integer(forKey: "totalCorrectAnswers") + 1
            UserDefaults.standard.set(correct, forKey: "totalCorrectAnswers")
        }

        updateStreak()
        checkBadgeProgress()
    }

    func recordExamComplete(accuracy: Double) {
        let total = UserDefaults.standard.integer(forKey: "examsCompleted") + 1
        UserDefaults.standard.set(total, forKey: "examsCompleted")

        if accuracy >= 80 {
            let highScoreExams = UserDefaults.standard.integer(forKey: "examsWithHighScore") + 1
            UserDefaults.standard.set(highScoreExams, forKey: "examsWithHighScore")
            checkExamAce(examsWithHighScore: highScoreExams)
        }

        checkPerfectScore(accuracy: accuracy)
        checkBadgeProgress()
    }

    private func saveToStorage() {
        UserDefaults.standard.set(totalXP, forKey: "gamification_totalXP")
        UserDefaults.standard.set(streak, forKey: "gamification_streak")
        let badgeNames = unlockedBadges.map { $0.rawValue }
        UserDefaults.standard.set(badgeNames, forKey: "gamification_badges")
    }

    private func loadFromStorage() {
        totalXP = UserDefaults.standard.integer(forKey: "gamification_totalXP")
        streak = UserDefaults.standard.integer(forKey: "gamification_streak")

        level = LevelSystem.levelForXP(totalXP)
        currentXP = totalXP - LevelSystem.xpForLevel(level)

        if let badgeNames = UserDefaults.standard.array(forKey: "gamification_badges") as? [String] {
            unlockedBadges = Set(badgeNames.compactMap { Badge(rawValue: $0) })
        }
    }

    private func syncWithServer() async {
        // Skip server sync in mock mode
        guard APIClient.mode != .mock else { return }

        do {
            let _ = try await APIClient.shared.updateUserXP(totalXP: totalXP, level: level)
        } catch {
            print("Failed to sync XP: \(error)")
        }
    }
}

enum XPReason: String {
    case correctAnswer = "Resposta correta"
    case flashcardReview = "Revisão de card"
    case examComplete = "Prova concluída"
    case streak = "Streak diário"
    case studySession = "Sessão de estudo"
}

// MARK: - Level Up View

struct LevelUpView: View {
    let level: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                ZStack {
                    Circle()
                        .fill(Color.resumed.gold.opacity(0.3))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)

                    Circle()
                        .fill(Color.resumed.gold)
                        .frame(width: 150, height: 150)

                    VStack {
                        Text("LEVEL")
                            .font(.resumed.caption)
                            .fontWeight(.bold)
                        Text("\(level)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.resumed.black)
                }

                Text("Parabéns!")
                    .font(.resumed.h1)
                    .foregroundColor(.resumed.white)

                Text(LevelSystem.titleForLevel(level))
                    .font(.resumed.h4)
                    .foregroundColor(.resumed.gold)

                ResumedButton(title: "Continuar", style: .primary, action: onDismiss)
            }
        }
    }
}
