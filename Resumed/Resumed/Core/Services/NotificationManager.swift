//
//  NotificationManager.swift
//  Resumed
//
//  Push Notifications - Local & Remote
//

import Foundation
import UserNotifications
import UIKit
import Combine

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted

            if granted {
                await registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("❌ Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Daily Study Reminder

    func scheduleDailyReminder(at hour: Int, minute: Int) {
        let identifier = "daily_study_reminder"

        // Remove existing
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Hora de estudar! 📚"
        content.body = getRandomStudyReminderBody()
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "STUDY_REMINDER"
        content.userInfo = ["type": "daily_reminder"]

        // Create trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Schedule
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily reminder: \(error)")
            } else {
                print("✅ Daily reminder scheduled for \(hour):\(minute)")
            }
        }

        // Save preference
        UserDefaults.standard.set(true, forKey: "dailyReminderEnabled")
        UserDefaults.standard.set(hour, forKey: "dailyReminderHour")
        UserDefaults.standard.set(minute, forKey: "dailyReminderMinute")
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily_study_reminder"])
        UserDefaults.standard.set(false, forKey: "dailyReminderEnabled")
    }

    private func getRandomStudyReminderBody() -> String {
        let messages = [
            "Seu streak de estudos está esperando! 🔥",
            "5 minutos fazem diferença. Vamos lá!",
            "Seus flashcards estão prontos para revisão.",
            "A aprovação é construída um dia de cada vez.",
            "Não perca seu streak! Mantenha a consistência.",
            "Hora de praticar algumas questões!",
            "Cada questão te aproxima da residência.",
            "Grey está online e pronto para ajudar!"
        ]
        return messages.randomElement() ?? messages[0]
    }

    // MARK: - Streak at Risk

    func scheduleStreakAtRiskNotification(currentStreak: Int) {
        let identifier = "streak_at_risk"

        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard currentStreak >= 3 else { return } // Only for streaks >= 3 days

        let content = UNMutableNotificationContent()
        content.title = "Seu streak está em risco! 🔥"
        content.body = "Você tem um streak de \(currentStreak) dias. Não deixe acabar hoje!"
        content.sound = .default
        content.categoryIdentifier = "STREAK_RISK"
        content.userInfo = ["type": "streak_risk", "streak": currentStreak]

        // Trigger at 9 PM if user hasn't studied
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule streak risk notification: \(error)")
            }
        }
    }

    func cancelStreakAtRiskNotification() {
        center.removePendingNotificationRequests(withIdentifiers: ["streak_at_risk"])
    }

    // MARK: - Flashcard Review Reminder

    func scheduleFlashcardReminder(cardsCount: Int, delay: TimeInterval = 3600) {
        let identifier = "flashcard_reminder"

        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard cardsCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "ResuCards prontos! 🧠"
        content.body = "\(cardsCount) flashcards estão esperando revisão."
        content.sound = .default
        content.categoryIdentifier = "FLASHCARD_REMINDER"
        content.userInfo = ["type": "flashcard_reminder", "count": cardsCount]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    // MARK: - Weekly Report

    func scheduleWeeklyReport() {
        let identifier = "weekly_report"

        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Seu resumo semanal 📊"
        content.body = "Confira seu progresso da semana!"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_REPORT"
        content.userInfo = ["type": "weekly_report"]

        // Every Sunday at 6 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    // MARK: - Daily Challenge

    func scheduleDailyChallengeNotification() {
        let identifier = "daily_challenge"

        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Novo desafio diário! 🎯"
        content.body = "Seu desafio de hoje está disponível. Bora conquistar?"
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHALLENGE"
        content.userInfo = ["type": "daily_challenge"]

        // Every day at 8 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    // MARK: - Achievement Unlocked

    func sendAchievementNotification(badge: Badge) {
        let content = UNMutableNotificationContent()
        content.title = "Conquista desbloqueada! 🎖️"
        content.body = "Você ganhou: \(badge.title)"
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        content.userInfo = ["type": "achievement", "badge": badge.rawValue]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "achievement_\(badge.rawValue)", content: content, trigger: trigger)

        center.add(request)
    }

    // MARK: - Level Up

    func sendLevelUpNotification(newLevel: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Level Up! 🚀"
        content.body = "Parabéns! Você alcançou o nível \(newLevel)!"
        content.sound = .default
        content.categoryIdentifier = "LEVEL_UP"
        content.userInfo = ["type": "level_up", "level": newLevel]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "level_up_\(newLevel)", content: content, trigger: trigger)

        center.add(request)
    }

    // MARK: - Custom Notification

    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        trigger: UNNotificationTrigger,
        categoryIdentifier: String = "DEFAULT",
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = userInfo

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            }
        }
    }

    // MARK: - Cancel All

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - List Pending

    func listPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        pendingNotifications = requests
        print("📬 Pending notifications: \(requests.count)")
        for request in requests {
            print("  - \(request.identifier): \(request.content.title)")
        }
    }

    // MARK: - Notification Categories (Actions)

    func registerNotificationCategories() {
        // Study Reminder Actions
        let studyAction = UNNotificationAction(
            identifier: "STUDY_NOW",
            title: "Estudar agora",
            options: [.foreground]
        )
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Lembrar em 1h",
            options: []
        )

        let studyCategory = UNNotificationCategory(
            identifier: "STUDY_REMINDER",
            actions: [studyAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )

        // Streak Risk Actions
        let openAppAction = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "Manter streak",
            options: [.foreground]
        )

        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_RISK",
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )

        // Flashcard Actions
        let reviewAction = UNNotificationAction(
            identifier: "REVIEW_CARDS",
            title: "Revisar agora",
            options: [.foreground]
        )

        let flashcardCategory = UNNotificationCategory(
            identifier: "FLASHCARD_REMINDER",
            actions: [reviewAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )

        // Daily Challenge Actions
        let acceptChallengeAction = UNNotificationAction(
            identifier: "ACCEPT_CHALLENGE",
            title: "Aceitar desafio",
            options: [.foreground]
        )

        let challengeCategory = UNNotificationCategory(
            identifier: "DAILY_CHALLENGE",
            actions: [acceptChallengeAction],
            intentIdentifiers: [],
            options: []
        )

        // Register all categories
        center.setNotificationCategories([
            studyCategory,
            streakCategory,
            flashcardCategory,
            challengeCategory
        ])
    }
}

// MARK: - Notification Handler Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    // Called when notification is received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Called when user interacts with notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier

        // Handle actions
        switch actionIdentifier {
        case "STUDY_NOW", "OPEN_APP", "REVIEW_CARDS", "ACCEPT_CHALLENGE":
            // App will open, navigation handled by deep link
            break

        case "REMIND_LATER":
            // Schedule reminder for 1 hour later
            Task { @MainActor in
                NotificationManager.shared.scheduleNotification(
                    identifier: "remind_later_\(UUID().uuidString)",
                    title: response.notification.request.content.title,
                    body: response.notification.request.content.body,
                    trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
                )
            }

        default:
            break
        }

        completionHandler()
    }
}

// MARK: - Widget Data Update

extension NotificationManager {
    func updateWidgetData(
        streak: Int,
        dailyGoal: Int,
        dailyProgress: Int,
        pendingCards: Int,
        accuracy: Int,
        level: Int,
        xpProgress: Double,
        quote: String
    ) {
        guard let defaults = UserDefaults(suiteName: "group.com.resumed.app") else { return }

        defaults.set(streak, forKey: "widget_streak")
        defaults.set(dailyGoal, forKey: "widget_dailyGoal")
        defaults.set(dailyProgress, forKey: "widget_dailyProgress")
        defaults.set(pendingCards, forKey: "widget_pendingCards")
        defaults.set(accuracy, forKey: "widget_accuracy")
        defaults.set(level, forKey: "widget_level")
        defaults.set(xpProgress, forKey: "widget_xpProgress")
        defaults.set(quote, forKey: "widget_quote")

        // Trigger widget refresh
        // WidgetCenter.shared.reloadAllTimelines() // Uncomment when WidgetKit is added
    }
}
