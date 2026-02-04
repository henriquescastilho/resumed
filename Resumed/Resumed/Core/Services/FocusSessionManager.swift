//
//  FocusSessionManager.swift
//  Resumed
//
//  Pomodoro Focus Session Manager
//

import Foundation
import Combine
@preconcurrency import UserNotifications
import AudioToolbox

@MainActor
final class FocusSessionManager: ObservableObject {
    static let shared = FocusSessionManager()
    static let neuronGoal = FocusDefaults.neuronGoal

    enum Phase: String, Codable {
        case focus
        case breakTime
    }

    // MARK: - Published State

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var phase: Phase = .focus
    @Published private(set) var remainingSeconds: Int = FocusDefaults.focusDurationSeconds
    @Published private(set) var pomodorosCompletedToday: Int = 0
    @Published private(set) var totalPomodorosCompleted: Int = 0

    @Published var focusDurationSeconds: Int = FocusDefaults.focusDurationSeconds {
        didSet { UserDefaults.standard.set(focusDurationSeconds, forKey: Keys.focusDurationSeconds) }
    }
    @Published var breakDurationSeconds: Int = FocusDefaults.breakDurationSeconds {
        didSet { UserDefaults.standard.set(breakDurationSeconds, forKey: Keys.breakDurationSeconds) }
    }

    private var timer: Timer?
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationId = "focus_session_end"

    private init() {
        loadFromStorage()
        resetIfNewDay()
    }

    // MARK: - Public API

    var isLimitReached: Bool {
        pomodorosCompletedToday >= FocusDefaults.maxPomodorosPerDay
    }

    func start() {
        resetIfNewDay()
        guard !isLimitReached else { return }

        isRunning = true
        isPaused = false
        phase = .focus
        remainingSeconds = focusDurationSeconds

        scheduleFocusEndNotificationIfPossible()
        startTimer()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        stopTimer()
        cancelFocusNotification()
    }

    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        scheduleFocusEndNotificationIfPossible()
        startTimer()
    }

    func stop() {
        isRunning = false
        isPaused = false
        phase = .focus
        remainingSeconds = focusDurationSeconds
        stopTimer()
        cancelFocusNotification()
    }

    // MARK: - Internal for Testing

    func resetIfNewDay(currentDate: Date = Date()) {
        let todayKey = Self.dayKey(from: currentDate)
        let lastDay = UserDefaults.standard.string(forKey: Keys.lastDayKey)
        if lastDay != todayKey {
            UserDefaults.standard.set(todayKey, forKey: Keys.lastDayKey)
            UserDefaults.standard.set(0, forKey: Keys.pomodorosCompletedToday)
        }
        pomodorosCompletedToday = UserDefaults.standard.integer(forKey: Keys.pomodorosCompletedToday)
    }

    func completeFocus(currentDate: Date = Date()) {
        pomodorosCompletedToday = min(pomodorosCompletedToday + 1, FocusDefaults.maxPomodorosPerDay)
        UserDefaults.standard.set(pomodorosCompletedToday, forKey: Keys.pomodorosCompletedToday)
        totalPomodorosCompleted += 1
        UserDefaults.standard.set(totalPomodorosCompleted, forKey: Keys.totalPomodorosCompleted)

        GamificationManager.shared.addXP(FocusDefaults.xpPerPomodoro, reason: .studySession)
        GamificationManager.shared.updateStreak()

        HapticManager.shared.success()
        playSound()

        phase = .breakTime
        remainingSeconds = breakDurationSeconds
        isRunning = true
        isPaused = false

        stopTimer()
        cancelFocusNotification()
        startTimer()
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func finishBreak() {
        phase = .focus
        remainingSeconds = focusDurationSeconds
        isRunning = false
        isPaused = false
        stopTimer()
    }

    private func tick() {
        guard isRunning, !isPaused else { return }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }

        if remainingSeconds <= 0 {
            switch phase {
            case .focus:
                completeFocus()
            case .breakTime:
                finishBreak()
            }
        }
    }

    // MARK: - Notifications

    private func scheduleFocusEndNotificationIfPossible() {
        let center = notificationCenter
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                Task { @MainActor in
                    self.scheduleFocusNotification()
                }
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted {
                        Task { @MainActor in
                            self.scheduleFocusNotification()
                        }
                    }
                }
            default:
                break
            }
        }
    }

    private func scheduleFocusNotification() {
        cancelFocusNotification()
        let content = UNMutableNotificationContent()
        content.title = "Foco encerrado!"
        content.body = "Bom trabalho! Hora da pausa."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remainingSeconds), repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        notificationCenter.add(request)
    }

    private func cancelFocusNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
    }

    // MARK: - Sound

    private func playSound() {
        AudioServicesPlaySystemSound(1005)
    }

    // MARK: - Storage

    private func loadFromStorage() {
        let storedFocus = UserDefaults.standard.integer(forKey: Keys.focusDurationSeconds)
        let storedBreak = UserDefaults.standard.integer(forKey: Keys.breakDurationSeconds)
        focusDurationSeconds = storedFocus > 0 ? storedFocus : FocusDefaults.focusDurationSeconds
        breakDurationSeconds = storedBreak > 0 ? storedBreak : FocusDefaults.breakDurationSeconds
        remainingSeconds = focusDurationSeconds
        pomodorosCompletedToday = UserDefaults.standard.integer(forKey: Keys.pomodorosCompletedToday)
        totalPomodorosCompleted = UserDefaults.standard.integer(forKey: Keys.totalPomodorosCompleted)
    }

    private static func dayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private enum FocusDefaults {
    static let focusDurationSeconds = 25 * 60
    static let breakDurationSeconds = 5 * 60
    static let maxPomodorosPerDay = 8
    static let xpPerPomodoro = 25
    static let neuronGoal = 60
}

private enum Keys {
    static let focusDurationSeconds = "focus_duration_seconds"
    static let breakDurationSeconds = "break_duration_seconds"
    static let pomodorosCompletedToday = "pomodoros_completed_today"
    static let lastDayKey = "pomodoro_last_day"
    static let totalPomodorosCompleted = "pomodoro_total_completed"
}
