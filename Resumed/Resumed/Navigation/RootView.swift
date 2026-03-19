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
                } else if !appState.hasCompletedPlacementTest {
                    PlacementTestView {
                        appState.completePlacementTest()
                    }
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
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showContent = false
    @State private var emailText = ""
    @State private var passwordText = ""

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

                        Image("ResumedLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
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

                // Login form
                VStack(spacing: Spacing.md) {
                    // Email field
                    TextField("Email", text: $emailText)
                        .font(.resumed.body)
                        .foregroundColor(.resumed.white)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(Spacing.md)
                        .background(Color.resumed.blackSecondary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.resumed.border, lineWidth: 1)
                        )

                    // Password field
                    SecureField("Senha", text: $passwordText)
                        .font(.resumed.body)
                        .foregroundColor(.resumed.white)
                        .textContentType(.password)
                        .padding(Spacing.md)
                        .background(Color.resumed.blackSecondary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.resumed.border, lineWidth: 1)
                        )

                    // Email login button
                    Button {
                        signInWithEmail()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .resumed.black))
                            } else {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 20))
                            }
                            Text("Entrar")
                                .font(.resumed.button)
                        }
                        .foregroundColor(.resumed.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.buttonHeight)
                        .background(Color.resumed.gold)
                        .cornerRadius(CornerRadius.md)
                    }
                    .disabled(isLoading || emailText.isEmpty || passwordText.isEmpty)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.6), value: showContent)

                    // Apple Sign In
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

    private func signInWithEmail() {
        isLoading = true
        HapticManager.shared.impact(.medium)

        Task {
            do {
                try await SupabaseManager.shared.signIn(
                    email: emailText.trimmingCharacters(in: .whitespaces),
                    password: passwordText
                )
                appState.isAuthenticated = true
                appState.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                isLoading = false
                HapticManager.shared.success()
            } catch {
                isLoading = false
                errorMessage = "Email ou senha incorretos. Tente novamente."
                showError = true
                HapticManager.shared.error()
            }
        }
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
