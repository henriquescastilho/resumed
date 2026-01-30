import Foundation
import SwiftUI

@MainActor
class SessionManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isOnboardingComplete = false
    @Published var isLoading = true
    @Published var currentUser: UserProfile?
    
    init() {
        checkSession()
    }
    
    func checkSession() {
        print("Checking session...")
        if let token = AuthService.shared.getToken() {
            print("Token found. Validating...")
            Task {
                do {
                    // Refresh profile
                    let profile = try await APIClient.shared.getProfile(token: token)
                    self.currentUser = profile
                    self.isOnboardingComplete = profile.is_onboarding_complete
                    self.isAuthenticated = true
                    print("Session valid. User: \(profile.email)")
                } catch {
                    print("Session invalid: \(error)")
                    // Token invalid or network error. If 401, clear.
                    // For safety, clear on error in this MVP loop
                    AuthService.shared.clearToken()
                    self.isAuthenticated = false
                }
                self.isLoading = false
            }
        } else {
            print("No token found.")
            self.isAuthenticated = false
            self.isLoading = false
        }
    }
    
    func login() async {
        do {
            let idToken = try await AuthService.shared.performGoogleLogin()
            // Send to backend
            _ = try await APIClient.shared.login(idToken: idToken)
            // Save token
            AuthService.shared.saveToken(idToken)
            // Refresh state
            checkSession()
        } catch {
            print("Login failed: \(error)")
        }
    }
    
    func completeOnboarding(profileData: APIClient.ProfileUpdatePayload) async {
        guard let token = AuthService.shared.getToken() else { return }
        do {
            let updatedProfile = try await APIClient.shared.updateProfile(token: token, payload: profileData)
            self.currentUser = updatedProfile
            self.isOnboardingComplete = updatedProfile.is_onboarding_complete
        } catch {
            print("Failed to save onboarding: \(error)")
        }
    }
    
    func logout() {
        AuthService.shared.clearToken()
        isAuthenticated = false
        isOnboardingComplete = false
        currentUser = nil
    }
}
