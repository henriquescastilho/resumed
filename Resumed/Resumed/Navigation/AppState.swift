//
//  AppState.swift
//  Resumed
//
//  Global App State
//

import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    @Published var hasCompletedPlacementTest = false
    @Published var user: User?
    @Published var isLoading = true
    @Published var selectedTab: Tab = .home

    private var cancellables = Set<AnyCancellable>()

    init() {
        checkInitialState()
        observeAuthManager()
        observeSupabaseManager()
    }

    func navigateTo(_ tab: Tab) {
        selectedTab = tab
        HapticManager.shared.selection()
    }

    private func checkInitialState() {
        // Check both legacy AuthManager and SupabaseManager for auth state
        isAuthenticated = AuthManager.shared.accessToken != nil || SupabaseManager.shared.isAuthenticated
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        hasCompletedPlacementTest = UserDefaults.standard.bool(forKey: PlacementTestStore.hasTakenTestKey)
        isLoading = false
    }

    private func observeAuthManager() {
        AuthManager.shared.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] authed in
                guard let self else { return }
                if !authed && self.isAuthenticated && !SupabaseManager.shared.isAuthenticated {
                    self.isAuthenticated = false
                    self.hasCompletedOnboarding = false
                    self.hasCompletedPlacementTest = false
                    self.user = nil
                }
            }
            .store(in: &cancellables)
    }

    private func observeSupabaseManager() {
        SupabaseManager.shared.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] authed in
                guard let self else { return }
                if authed && !self.isAuthenticated {
                    // Supabase session restored (e.g. on app relaunch)
                    self.isAuthenticated = true
                    self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                    self.hasCompletedPlacementTest = UserDefaults.standard.bool(forKey: PlacementTestStore.hasTakenTestKey)
                } else if !authed && self.isAuthenticated {
                    // Supabase signed out
                    self.isAuthenticated = false
                    self.hasCompletedOnboarding = false
                    self.hasCompletedPlacementTest = false
                    self.user = nil
                }
            }
            .store(in: &cancellables)

        // Keep appState.user in sync with SupabaseManager.currentUser
        SupabaseManager.shared.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] supaUser in
                guard let self else { return }
                if let supaUser {
                    self.user = User(
                        id: supaUser.id,
                        email: supaUser.email,
                        name: supaUser.fullName,
                        avatar: nil,
                        targetExam: nil,
                        examDate: nil,
                        studyHoursPerDay: UserDefaults.standard.integer(forKey: "studyHoursPerDay"),
                        createdAt: Date(),
                        onboardingCompleted: UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                    )
                } else {
                    self.user = nil
                }
            }
            .store(in: &cancellables)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func completePlacementTest() {
        hasCompletedPlacementTest = true
        UserDefaults.standard.set(true, forKey: PlacementTestStore.hasTakenTestKey)
    }

    func signOut() async {
        await AuthManager.shared.signOut()
        try? await SupabaseManager.shared.signOut()
        isAuthenticated = false
        hasCompletedOnboarding = false
        hasCompletedPlacementTest = false
        user = nil
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }

    func clearLocalData() {
        hasCompletedOnboarding = false
        hasCompletedPlacementTest = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        PlacementTestStore.shared.clearResult()
        CoreDataManager.shared.clearAllData()
    }
}
