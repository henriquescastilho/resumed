//
//  WidgetDataBridge.swift
//  Resumed
//
//  Syncs app data to the App Group shared container
//  so the widget extension can read it.
//
//  SETUP: Both the app target and widget target must have
//  the "group.com.resumed.app" App Group in their capabilities.
//

import Foundation
import WidgetKit

@MainActor
class WidgetDataBridge {
    static let shared = WidgetDataBridge()

    private let suiteName = "group.com.resumed.app"
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private let quotes = [
        "A persistência é o caminho do êxito.",
        "Estudar com método muda tudo.",
        "Cada questão te aproxima da aprovação.",
        "Disciplina supera motivação.",
        "Sua aprovação começa hoje!",
        "O esforço de hoje é o resultado de amanhã.",
        "Não pare quando estiver cansado. Pare quando terminar.",
        "A medicina é uma jornada, não um sprint."
    ]

    private init() {}

    /// Call this after any significant state change to keep the widget updated
    func sync() {
        guard let defaults = sharedDefaults else {
            print("⚠️ Widget App Group not configured")
            return
        }

        let gamification = GamificationManager.shared
        let progressSnapshot = ProgressTracker.shared.snapshot()

        defaults.set(gamification.streak, forKey: "widget_streak")
        defaults.set(gamification.level, forKey: "widget_level")
        defaults.set(gamification.progressToNextLevel(), forKey: "widget_xpProgress")

        // Daily goal from settings
        let dailyGoal = UserDefaults.standard.integer(forKey: "dailyQuestionGoal")
        defaults.set(dailyGoal > 0 ? dailyGoal : 20, forKey: "widget_dailyGoal")

        // Daily progress (questions answered today)
        let todayKey = Self.todayKey()
        let todayProgress = UserDefaults.standard.integer(forKey: "questions_today_\(todayKey)")
        defaults.set(todayProgress, forKey: "widget_dailyProgress")

        // Pending flashcards
        let pendingCards = countDueFlashcards()
        defaults.set(pendingCards, forKey: "widget_pendingCards")

        // Overall accuracy
        defaults.set(progressSnapshot.overallAccuracy, forKey: "widget_accuracy")

        // Random motivational quote
        defaults.set(quotes.randomElement() ?? quotes[0], forKey: "widget_quote")

        // Tell WidgetKit to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func countDueFlashcards() -> Int {
        let cards = CoreDataManager.shared.fetchDueFlashCards()
        return cards.count
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func todayKey() -> String {
        dayFormatter.string(from: Date())
    }
}
