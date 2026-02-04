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
    @Published var user: User?
    @Published var isLoading = true
    @Published var selectedTab: Tab = .home

    init() {
        checkInitialState()
    }

    func navigateTo(_ tab: Tab) {
        selectedTab = tab
        HapticManager.shared.selection()
    }

    private func checkInitialState() {
        isAuthenticated = AuthManager.shared.accessToken != nil
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        isLoading = false
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func signOut() async {
        await AuthManager.shared.signOut()
        isAuthenticated = false
        hasCompletedOnboarding = false
        user = nil
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}
