//
//  SupabaseManager.swift
//  Resumed
//
//  Supabase Auth (email + phone) + Analytics
//

import Foundation
import Combine
import SwiftUI
import Supabase

// MARK: - Supabase Manager

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    @Published var currentUser: SupabaseUser?
    @Published var isSigningIn = false
    @Published var authError: String?
    @Published var isAuthenticated = false

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: SupabaseConfig.url) else {
            preconditionFailure("Invalid SUPABASE_URL: \(SupabaseConfig.url)")
        }
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey
        )

        Task { await restoreSession() }
    }

    // MARK: - Session

    private func restoreSession() async {
        do {
            let session = try await client.auth.session
            currentUser = mapUser(session.user)
            isAuthenticated = true
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }

    func listenForAuthChanges() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn:
                        if let user = session?.user {
                            self.currentUser = self.mapUser(user)
                            self.isAuthenticated = true
                        }
                    case .signedOut:
                        self.currentUser = nil
                        self.isAuthenticated = false
                    case .tokenRefreshed, .userUpdated:
                        if let user = session?.user {
                            self.currentUser = self.mapUser(user)
                        }
                    default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Sign Up (email + senha)

    func signUp(email: String, password: String, fullName: String, phone: String? = nil) async throws -> SupabaseUser {
        isSigningIn = true
        authError = nil
        defer { isSigningIn = false }

        var metadata: [String: AnyJSON] = [
            "full_name": .string(fullName)
        ]
        if let phone = phone, !phone.isEmpty {
            metadata["phone"] = .string(phone)
        }

        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: metadata
        )

        let authUser = response.user

        // If phone was provided, update the user's phone number for Supabase Auth
        if let phone = phone, !phone.isEmpty {
            try await client.auth.update(user: UserAttributes(phone: phone))
        }

        let user = mapUser(authUser)
        currentUser = user
        isAuthenticated = true
        logEvent(.signUp, parameters: ["method": "email"])

        return user
    }

    // MARK: - Sign In (email + senha)

    func signIn(email: String, password: String) async throws -> SupabaseUser {
        isSigningIn = true
        authError = nil
        defer { isSigningIn = false }

        let session = try await client.auth.signIn(
            email: email,
            password: password
        )

        let user = mapUser(session.user)
        currentUser = user
        isAuthenticated = true
        logEvent(.login, parameters: ["method": "email"])

        return user
    }

    // MARK: - Phone OTP

    /// Envia código OTP por SMS
    func sendPhoneOTP(phone: String) async throws {
        isSigningIn = true
        authError = nil
        defer { isSigningIn = false }

        try await client.auth.signInWithOTP(phone: phone)
    }

    /// Verifica código OTP recebido por SMS
    func verifyPhoneOTP(phone: String, code: String) async throws -> SupabaseUser {
        isSigningIn = true
        authError = nil
        defer { isSigningIn = false }

        let session = try await client.auth.verifyOTP(
            phone: phone,
            token: code,
            type: .sms
        )

        let user = mapUser(session.user)
        currentUser = user
        isAuthenticated = true
        logEvent(.login, parameters: ["method": "phone"])

        return user
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
        logEvent(.logout, parameters: nil)
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        let session = try await client.auth.session
        let userId = session.user.id.uuidString

        // 1. Delete user data from tables (RLS allows own-row deletion)
        // study_progress may not exist yet — ignore errors
        try? await client.from("study_progress")
            .delete()
            .eq("user_id", value: userId)
            .execute()

        try? await client.from("profiles")
            .delete()
            .eq("id", value: userId)
            .execute()

        // 2. Call server-side RPC to delete auth user (requires DB function)
        try await client.rpc("delete_own_account").execute()

        // 3. Clean up local state
        logEvent(.accountDeleted, parameters: nil)
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    // MARK: - Update Profile

    func updateProfile(fullName: String? = nil, phone: String? = nil) async throws {
        var attributes = UserAttributes()
        if let fullName = fullName {
            attributes.data = ["full_name": .string(fullName)]
        }
        if let phone = phone {
            attributes.phone = phone
        }
        try await client.auth.update(user: attributes)

        // Refresh user
        await restoreSession()
    }

    // MARK: - Sync Onboarding Data

    func syncOnboardingData(_ data: OnboardingData) async throws {
        // 1. Update auth metadata
        var metadata: [String: AnyJSON] = [
            "full_name": .string(data.name),
            "target_exam": .string(data.targetExam),
            "study_hours_per_day": .double(Double(data.studyHoursPerDay)),
            "subject_priority": .array(data.subjectPriority.map { .string($0) }),
        ]
        if let specialty = data.specialty {
            metadata["specialty"] = .string(specialty)
        }
        if let examDate = data.examDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            metadata["exam_date"] = .string(formatter.string(from: examDate))
        }
        try await client.auth.update(user: UserAttributes(data: metadata))

        // 2. Upsert to profiles table (proper relational storage)
        let session = try await client.auth.session
        let userId = session.user.id.uuidString

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        var profileData: [String: AnyJSON] = [
            "id": .string(userId),
            "full_name": .string(data.name),
            "email": .string(session.user.email ?? ""),
            "phone": .string(data.phone),
            "city": .string(data.city),
            "university": .string(data.university),
            "target_exam": .string(data.targetExam),
            "study_hours_per_day": .double(Double(data.studyHoursPerDay)),
            "subject_priority": .array(data.subjectPriority.map { .string($0) }),
            "onboarding_completed": .bool(true),
        ]

        if let specialty = data.specialty {
            profileData["specialty"] = .string(specialty)
        }
        if let state = data.state {
            profileData["state"] = .string(state)
        }
        if let examDate = data.examDate {
            profileData["exam_date"] = .string(dateFormatter.string(from: examDate))
        }

        try await client.from("profiles")
            .upsert(profileData)
            .execute()
    }

    // MARK: - Sync Progress

    func syncProgress(xp: Int, level: Int, streak: Int, totalQuestions: Int, totalCorrect: Int, studyTimeMinutes: Int, badges: [String]) async throws {
        // Update auth metadata (backward compatible)
        let metadata: [String: AnyJSON] = [
            "xp": .double(Double(xp)),
            "level": .double(Double(level)),
            "streak": .double(Double(streak)),
            "total_questions": .double(Double(totalQuestions)),
            "total_correct": .double(Double(totalCorrect)),
            "study_time_minutes": .double(Double(studyTimeMinutes)),
            "badges": .array(badges.map { .string($0) })
        ]
        try await client.auth.update(user: UserAttributes(data: metadata))

        // Upsert today's progress to study_progress table
        let session = try await client.auth.session
        let userId = session.user.id.uuidString
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let today = dateFormatter.string(from: Date())

        let progressData: [String: AnyJSON] = [
            "user_id": .string(userId),
            "date": .string(today),
            "xp_earned": .double(Double(xp)),
            "questions_answered": .double(Double(totalQuestions)),
            "questions_correct": .double(Double(totalCorrect)),
            "study_time_minutes": .double(Double(studyTimeMinutes)),
            "streak_count": .double(Double(streak)),
        ]

        try await client.from("study_progress")
            .upsert(progressData, onConflict: "user_id,date")
            .execute()
    }

    // MARK: - Access Token

    func getAccessToken() async throws -> String {
        let session = try await client.auth.session
        return session.accessToken
    }

    // MARK: - Helpers

    private func mapUser(_ authUser: Auth.User) -> SupabaseUser {
        SupabaseUser(
            id: authUser.id.uuidString,
            email: authUser.email ?? "",
            phone: authUser.phone ?? "",
            fullName: authUser.userMetadata["full_name"]?.stringValue ?? "",
            avatarURL: nil,
            isEmailConfirmed: authUser.emailConfirmedAt != nil,
            isPhoneConfirmed: authUser.phoneConfirmedAt != nil
        )
    }

    // MARK: - Analytics (local logging)

    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any]?) {
        #if DEBUG
        print("📊 Analytics: \(event.rawValue) - \(parameters ?? [:])")
        #endif
    }

    func setUserProperty(_ value: String?, forName name: String) {
        #if DEBUG
        print("📊 User Property: \(name) = \(value ?? "nil")")
        #endif
    }

    func setUserId(_ userId: String?) {
        #if DEBUG
        print("📊 User ID: \(userId ?? "nil")")
        #endif
    }

    func logError(_ error: Error, userInfo: [String: Any]? = nil) {
        #if DEBUG
        print("🐛 Error logged: \(error.localizedDescription)")
        #endif
    }

    func trackScreen(_ screenName: String) {
        logEvent(.screenView, parameters: [
            "screen_name": screenName,
            "screen_class": screenName
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

// MARK: - Supabase Config
// Supabase anon key is a publishable client key (not a secret).
// Security is enforced by Row Level Security (RLS) policies, not by hiding this key.

enum SupabaseConfig {
    // placeholder: supabase project reference
    private static let projectRef = "bnudqlhzgdjrcboylbzl"
    private static let fallbackURL = "https://\(projectRef).supabase.co"
    // placeholder: supabase publishable anon key (RLS-protected, safe for client)
    private static let fallbackAnonKey = [
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
        "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJudWRxbGh6Z2RqcmNib3lsYnpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3OTQ5NzMsImV4cCI6MjA4OTM3MDk3M30",
        "4XWNYh52aZJpqDJn7tPCErrf9gxnz2fXONOSmNQaWwg"
    ].joined(separator: ".")

    static let url: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           !value.isEmpty, !value.contains("$(") {
            return value
        }
        if let value = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
           !value.isEmpty, !value.contains("$(") {
            return value
        }
        return fallbackURL
    }()

    static let anonKey: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !value.isEmpty, !value.contains("$(") {
            return value
        }
        if let value = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
           !value.isEmpty, !value.contains("$(") {
            return value
        }
        return fallbackAnonKey
    }()
}

// MARK: - Supabase User Model

struct SupabaseUser: Identifiable {
    let id: String
    let email: String
    let phone: String
    let fullName: String
    let avatarURL: URL?
    let isEmailConfirmed: Bool
    let isPhoneConfirmed: Bool

    var firstName: String {
        fullName.components(separatedBy: " ").first ?? fullName
    }
}

// MARK: - Auth Errors

enum SupabaseAuthError: Error, LocalizedError {
    case signUpFailed
    case invalidCredentials
    case invalidOTP
    case networkError
    case sessionExpired
    case unknown

    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Não foi possível criar a conta"
        case .invalidCredentials:
            return "Email ou senha incorretos"
        case .invalidOTP:
            return "Código de verificação inválido"
        case .networkError:
            return "Erro de conexão"
        case .sessionExpired:
            return "Sessão expirada, faça login novamente"
        case .unknown:
            return "Erro desconhecido"
        }
    }
}

// MARK: - Analytics Events

enum AnalyticsEvent: String {
    case login = "login"
    case logout = "logout"
    case signUp = "sign_up"
    case accountDeleted = "account_deleted"
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"
    case onboardingStepCompleted = "onboarding_step_completed"
    case questionAnswered = "question_answered"
    case questionSetStarted = "question_set_started"
    case questionSetCompleted = "question_set_completed"
    case flashcardReviewed = "flashcard_reviewed"
    case flashcardCreated = "flashcard_created"
    case flashcardSessionStarted = "flashcard_session_started"
    case flashcardSessionCompleted = "flashcard_session_completed"
    case examStarted = "exam_started"
    case examCompleted = "exam_completed"
    case examAbandoned = "exam_abandoned"
    case studySessionStarted = "study_session_started"
    case studySessionEnded = "study_session_ended"
    case dailyGoalReached = "daily_goal_reached"
    case levelUp = "level_up"
    case badgeUnlocked = "badge_unlocked"
    case streakMilestone = "streak_milestone"
    case xpEarned = "xp_earned"
    case greyMessageSent = "grey_message_sent"
    case greyResponseReceived = "grey_response_received"
    case screenView = "screen_view"
    case tabSelected = "tab_selected"
    case featureUsed = "feature_used"
    case paywallViewed = "paywall_viewed"
    case subscriptionStarted = "subscription_started"
    case subscriptionCancelled = "subscription_cancelled"
    case trialStarted = "trial_started"
    case errorOccurred = "error_occurred"
    case apiError = "api_error"
}

// MARK: - String Value Helper

private extension AnyJSON {
    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }
}
