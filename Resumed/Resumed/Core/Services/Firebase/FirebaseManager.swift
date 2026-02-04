//
//  FirebaseManager.swift
//  Resumed
//
//  Firebase Integration - Auth, Analytics, Crashlytics
//
//  SETUP REQUIRED:
//  1. Create Firebase project at console.firebase.google.com
//  2. Add iOS app with bundle ID: com.resumed.app
//  3. Download GoogleService-Info.plist and add to Xcode project
//  4. Add Firebase SDK via SPM: https://github.com/firebase/firebase-ios-sdk
//  5. Enable Google Sign-In in Firebase Console > Authentication
//

import Foundation
import Combine
import SwiftUI

// NOTE: Uncomment these imports after adding Firebase SDK via SPM
// import FirebaseCore
// import FirebaseAuth
// import FirebaseAnalytics
// import FirebaseCrashlytics
// import GoogleSignIn

// MARK: - Firebase Manager

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    @Published var isInitialized = false
    @Published var currentUser: FirebaseUser?
    @Published var isSigningIn = false
    @Published var authError: String?

    private init() {}

    // MARK: - Configuration

    func configure() {
        // Uncomment after adding Firebase SDK:
        // FirebaseApp.configure()
        // isInitialized = true
        // setupCrashlytics()
        // checkCurrentUser()

        // For now, mark as initialized for development
        isInitialized = true
        print("⚠️ Firebase: Running in mock mode. Add Firebase SDK to enable.")
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async throws -> FirebaseUser {
        isSigningIn = true
        authError = nil

        defer { isSigningIn = false }

        // MOCK IMPLEMENTATION - Replace with real Firebase code
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Return mock user
        let user = FirebaseUser(
            uid: "firebase_\(UUID().uuidString.prefix(8))",
            email: "estudante@gmail.com",
            displayName: "Estudante RESUMED",
            photoURL: nil,
            isEmailVerified: true
        )

        currentUser = user
        logEvent(.login, parameters: ["method": "google"])

        return user

        /* REAL IMPLEMENTATION - Uncomment after adding Firebase SDK:

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw FirebaseError.configurationError
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw FirebaseError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw FirebaseError.missingIDToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)

        let user = FirebaseUser(
            uid: authResult.user.uid,
            email: authResult.user.email ?? "",
            displayName: authResult.user.displayName ?? "",
            photoURL: authResult.user.photoURL,
            isEmailVerified: authResult.user.isEmailVerified
        )

        currentUser = user
        logEvent(.login, parameters: ["method": "google"])

        return user
        */
    }

    func signOut() async throws {
        // MOCK IMPLEMENTATION
        currentUser = nil
        logEvent(.logout, parameters: nil)

        /* REAL IMPLEMENTATION:
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
        currentUser = nil
        logEvent(.logout, parameters: nil)
        */
    }

    func deleteAccount() async throws {
        // MOCK IMPLEMENTATION
        logEvent(.accountDeleted, parameters: nil)
        currentUser = nil

        /* REAL IMPLEMENTATION:
        guard let user = Auth.auth().currentUser else {
            throw FirebaseError.notAuthenticated
        }

        logEvent(.accountDeleted, parameters: nil)
        try await user.delete()
        currentUser = nil
        */
    }

    private func checkCurrentUser() {
        /* REAL IMPLEMENTATION:
        if let user = Auth.auth().currentUser {
            currentUser = FirebaseUser(
                uid: user.uid,
                email: user.email ?? "",
                displayName: user.displayName ?? "",
                photoURL: user.photoURL,
                isEmailVerified: user.isEmailVerified
            )
        }
        */
    }

    // MARK: - Analytics

    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any]?) {
        // Uncomment after adding Firebase SDK:
        // Analytics.logEvent(event.rawValue, parameters: parameters)

        #if DEBUG
        print("📊 Analytics: \(event.rawValue) - \(parameters ?? [:])")
        #endif
    }

    func setUserProperty(_ value: String?, forName name: String) {
        // Uncomment after adding Firebase SDK:
        // Analytics.setUserProperty(value, forName: name)

        #if DEBUG
        print("📊 User Property: \(name) = \(value ?? "nil")")
        #endif
    }

    func setUserId(_ userId: String?) {
        // Uncomment after adding Firebase SDK:
        // Analytics.setUserID(userId)
        // Crashlytics.crashlytics().setUserID(userId ?? "")
    }

    // MARK: - Crashlytics

    private func setupCrashlytics() {
        /* REAL IMPLEMENTATION:
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        */
    }

    func logError(_ error: Error, userInfo: [String: Any]? = nil) {
        /* REAL IMPLEMENTATION:
        Crashlytics.crashlytics().record(error: error, userInfo: userInfo)
        */

        #if DEBUG
        print("🐛 Error logged: \(error.localizedDescription)")
        #endif
    }

    func log(_ message: String) {
        /* REAL IMPLEMENTATION:
        Crashlytics.crashlytics().log(message)
        */

        #if DEBUG
        print("📝 Log: \(message)")
        #endif
    }

    func setCustomValue(_ value: Any, forKey key: String) {
        /* REAL IMPLEMENTATION:
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        */
    }
}

// MARK: - Firebase User Model

struct FirebaseUser: Identifiable {
    let uid: String
    let email: String
    let displayName: String
    let photoURL: URL?
    let isEmailVerified: Bool

    var id: String { uid }

    var firstName: String {
        displayName.components(separatedBy: " ").first ?? displayName
    }
}

// MARK: - Firebase Errors

enum FirebaseError: Error, LocalizedError {
    case configurationError
    case noRootViewController
    case missingIDToken
    case notAuthenticated
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .configurationError:
            return "Erro de configuração do Firebase"
        case .noRootViewController:
            return "Não foi possível apresentar a tela de login"
        case .missingIDToken:
            return "Token de autenticação não encontrado"
        case .notAuthenticated:
            return "Usuário não autenticado"
        case .networkError:
            return "Erro de conexão"
        case .unknown:
            return "Erro desconhecido"
        }
    }
}

// MARK: - Analytics Events

enum AnalyticsEvent: String {
    // Auth
    case login = "login"
    case logout = "logout"
    case signUp = "sign_up"
    case accountDeleted = "account_deleted"

    // Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"
    case onboardingStepCompleted = "onboarding_step_completed"

    // Questions
    case questionAnswered = "question_answered"
    case questionSetStarted = "question_set_started"
    case questionSetCompleted = "question_set_completed"

    // FlashCards
    case flashcardReviewed = "flashcard_reviewed"
    case flashcardCreated = "flashcard_created"
    case flashcardSessionStarted = "flashcard_session_started"
    case flashcardSessionCompleted = "flashcard_session_completed"

    // Exams
    case examStarted = "exam_started"
    case examCompleted = "exam_completed"
    case examAbandoned = "exam_abandoned"

    // Study
    case studySessionStarted = "study_session_started"
    case studySessionEnded = "study_session_ended"
    case dailyGoalReached = "daily_goal_reached"

    // Gamification
    case levelUp = "level_up"
    case badgeUnlocked = "badge_unlocked"
    case streakMilestone = "streak_milestone"
    case xpEarned = "xp_earned"

    // Grey AI
    case greyMessageSent = "grey_message_sent"
    case greyResponseReceived = "grey_response_received"

    // Navigation
    case screenView = "screen_view"
    case tabSelected = "tab_selected"
    case featureUsed = "feature_used"

    // Subscription
    case paywallViewed = "paywall_viewed"
    case subscriptionStarted = "subscription_started"
    case subscriptionCancelled = "subscription_cancelled"
    case trialStarted = "trial_started"

    // Errors
    case errorOccurred = "error_occurred"
    case apiError = "api_error"
}

// MARK: - Analytics Helper Extensions

extension FirebaseManager {
    func trackScreen(_ screenName: String) {
        logEvent(.screenView, parameters: [
            "screen_name": screenName,
            "screen_class": screenName
        ])
    }

    func trackQuestionAnswered(subject: String, isCorrect: Bool, timeSpent: Int) {
        logEvent(.questionAnswered, parameters: [
            "subject": subject,
            "is_correct": isCorrect,
            "time_spent_seconds": timeSpent
        ])
    }

    func trackFlashcardReviewed(subject: String, quality: Int) {
        logEvent(.flashcardReviewed, parameters: [
            "subject": subject,
            "quality": quality
        ])
    }

    func trackExamCompleted(examId: String, score: Double, timeSpent: Int) {
        logEvent(.examCompleted, parameters: [
            "exam_id": examId,
            "score_percentage": score,
            "time_spent_minutes": timeSpent
        ])
    }

    func trackLevelUp(newLevel: Int, totalXP: Int) {
        logEvent(.levelUp, parameters: [
            "new_level": newLevel,
            "total_xp": totalXP
        ])
    }

    func trackBadgeUnlocked(_ badge: Badge) {
        logEvent(.badgeUnlocked, parameters: [
            "badge_id": badge.rawValue,
            "badge_name": badge.title
        ])
    }

    func trackSubscription(plan: String, price: Double, currency: String) {
        logEvent(.subscriptionStarted, parameters: [
            "plan": plan,
            "price": price,
            "currency": currency
        ])
    }
}

// MARK: - User Properties

extension FirebaseManager {
    func updateUserProperties(level: Int, isPro: Bool, streak: Int, targetExam: String?) {
        setUserProperty(String(level), forName: "user_level")
        setUserProperty(isPro ? "pro" : "free", forName: "subscription_status")
        setUserProperty(String(streak), forName: "current_streak")
        if let exam = targetExam {
            setUserProperty(exam, forName: "target_exam")
        }
    }
}
