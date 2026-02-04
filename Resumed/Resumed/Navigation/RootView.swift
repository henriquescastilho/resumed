//
//  RootView.swift
//  Resumed
//
//  Root Navigation Coordinator
//

import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            // Main content
            Group {
                if !appState.isAuthenticated {
                    LoginView()
                } else if !appState.hasCompletedOnboarding {
                    OnboardingView()
                } else {
                    TabBarView()
                }
            }
            .environmentObject(appState)
            .opacity(splashFinished ? 1 : 0)

            // Splash overlay
            if !splashFinished {
                SplashView(isFinished: $splashFinished)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Configure Firebase
            FirebaseManager.shared.configure()
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.resumed.black.ignoresSafeArea()

            // Background gradient
            RadialGradient(
                colors: [Color.resumed.gold.opacity(0.1), Color.resumed.black],
                center: .top,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Logo
                VStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.resumed.gold.opacity(0.1))
                            .frame(width: 140, height: 140)
                            .scaleEffect(showContent ? 1 : 0.5)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.resumed.gold, Color.resumed.goldLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(showContent ? 1 : 0)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)

                    Text("RESUMED")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.resumed.gold)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    Text("Sua aprovação na residência médica")
                        .font(.resumed.body)
                        .foregroundColor(.resumed.gray)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)

                Spacer()

                // Features highlights
                VStack(spacing: Spacing.md) {
                    FeatureHighlight(icon: "brain.head.profile", text: "IA personalizada para seu estudo")
                    FeatureHighlight(icon: "rectangle.stack.fill", text: "Flashcards com repetição espaçada")
                    FeatureHighlight(icon: "chart.line.uptrend.xyaxis", text: "Analytics detalhados")
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)

                Spacer()

                // Login buttons
                VStack(spacing: Spacing.md) {
                    // Google Sign In Button
                    Button {
                        signInWithGoogle()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .resumed.black))
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 24))
                            }

                            Text("Entrar com Google")
                                .font(.resumed.button)
                        }
                        .foregroundColor(.resumed.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.buttonHeight)
                        .background(Color.resumed.white)
                        .cornerRadius(CornerRadius.md)
                        .shadow(color: Color.white.opacity(0.1), radius: 10, y: 5)
                    }
                    .disabled(isLoading)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.6), value: showContent)

                    // Apple Sign In placeholder
                    Button {
                        // Apple Sign In - to be implemented
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))

                            Text("Entrar com Apple")
                                .font(.resumed.button)
                        }
                        .foregroundColor(.resumed.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.buttonHeight)
                        .background(Color.resumed.blackSecondary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.resumed.border, lineWidth: 1)
                        )
                    }
                    .disabled(isLoading)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.7), value: showContent)

                    // Demo mode
                    Button {
                        enterDemoMode()
                    } label: {
                        Text("Explorar sem conta (Demo)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                    .padding(.top, Spacing.sm)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.8), value: showContent)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
        .onAppear {
            showContent = true
        }
        .alert("Erro", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func signInWithGoogle() {
        isLoading = true
        HapticManager.shared.impact(.medium)

        Task {
            do {
                _ = try await FirebaseManager.shared.signInWithGoogle()

                // Create or update user in backend
                let idToken = "mock_id_token" // In production, get from Firebase
                let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

                // Try to authenticate with backend
                if APIClient.mode == .mock {
                    let response = try await MockAPIClient.shared.login(with: idToken, deviceId: deviceId)
                    appState.user = response.user
                }

                appState.isAuthenticated = true
                isLoading = false

                FirebaseManager.shared.trackScreen("login_success")

            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.shared.error()

                FirebaseManager.shared.logError(error, userInfo: ["screen": "login"])
            }
        }
    }

    private func enterDemoMode() {
        HapticManager.shared.selection()

        // Create demo user
        appState.user = User(
            id: "demo_user",
            email: "demo@resumed.app",
            name: "Estudante Demo",
            avatar: nil,
            targetExam: nil,
            examDate: nil,
            studyHoursPerDay: 4,
            createdAt: Date(),
            onboardingCompleted: false
        )
        appState.isAuthenticated = true

        FirebaseManager.shared.logEvent(.login, parameters: ["method": "demo"])
    }
}

// MARK: - Feature Highlight

struct FeatureHighlight: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.resumed.gold)
                .frame(width: 32)

            Text(text)
                .font(.resumed.bodySmall)
                .foregroundColor(.resumed.gray)

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Preview

#Preview {
    RootView()
}
