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
                        .adaptiveWidth(480)
                } else if !appState.hasCompletedOnboarding {
                    OnboardingView()
                        .adaptiveWidth(540)
                } else if !appState.hasCompletedPlacementTest {
                    PlacementTestView {
                        appState.completePlacementTest()
                    }
                    .adaptiveWidth()
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
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showSignUp = false
    @State private var signUpName = ""
    @State private var signUpEmail = ""
    @State private var signUpPassword = ""
    @State private var isSigningUp = false

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

            ScrollView {
                VStack(spacing: Spacing.lg) {
                // Logo
                VStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.resumed.gold.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(showContent ? 1 : 0.5)

                        Image("ResumedLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .scaleEffect(showContent ? 1 : 0)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)

                    Text("RESUMED")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.resumed.gold)
                        .opacity(showContent ? 1 : 0)

                    Text("Sua aprovação na residência médica")
                        .font(.resumed.body)
                        .foregroundColor(.resumed.gray)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                }
                .padding(.top, Spacing.xxl)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)

                // Features highlights
                VStack(spacing: Spacing.sm) {
                    FeatureHighlight(icon: "brain.head.profile", text: "IA personalizada para seu estudo")
                    FeatureHighlight(icon: "rectangle.stack.fill", text: "Flashcards com repetição espaçada")
                    FeatureHighlight(icon: "chart.line.uptrend.xyaxis", text: "Analytics detalhados")
                }
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)

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

                    // Create account
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Criar conta gratuita")
                            .font(.resumed.body)
                            .foregroundColor(.resumed.gold)
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.75), value: showContent)
                }
                // Terms notice
                HStack(spacing: 0) {
                    Text("Ao entrar, você concorda com os ")
                        .font(.system(size: 11))
                        .foregroundColor(.resumed.gray)
                    Button("Termos de Uso") { showTerms = true }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.resumed.gold)
                    Text(" e ")
                        .font(.system(size: 11))
                        .foregroundColor(.resumed.gray)
                    Button("Privacidade") { showPrivacy = true }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.resumed.gold)
                }
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.8), value: showContent)

                Text("Desenvolvido por DME TECHNOLOGY")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.resumed.gray.opacity(0.5))
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.9), value: showContent)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            showContent = true
        }
        .sheet(isPresented: $showTerms) {
            LegalView(type: .termsOfUse)
        }
        .sheet(isPresented: $showPrivacy) {
            LegalView(type: .privacyPolicy)
        }
        .sheet(isPresented: $showSignUp) {
            SignUpSheet(
                appState: appState,
                onDismiss: { showSignUp = false }
            )
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
                _ = try await SupabaseManager.shared.signIn(
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

// MARK: - Sign Up Sheet

struct SignUpSheet: View {
    let appState: AppState
    let onDismiss: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color.resumed.gold.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.resumed.gold)
                        }

                        Text("Criar sua conta")
                            .font(.resumed.h3)
                            .foregroundColor(.resumed.white)

                        Text("Comece sua jornada rumo à residência")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                    .padding(.top, Spacing.md)

                    // Form
                    VStack(spacing: Spacing.md) {
                        ResumedTextField(
                            placeholder: "Nome completo",
                            text: $name,
                            icon: "person"
                        )

                        ResumedTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope",
                            keyboardType: .emailAddress
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        ResumedTextField(
                            placeholder: "Senha (mínimo 6 caracteres)",
                            text: $password,
                            icon: "lock",
                            isSecure: true
                        )

                        ResumedTextField(
                            placeholder: "Confirmar senha",
                            text: $confirmPassword,
                            icon: "lock.fill",
                            isSecure: true
                        )

                        if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                            Text("As senhas não coincidem")
                                .font(.resumed.caption)
                                .foregroundColor(.resumed.error)
                        }
                    }

                    // Sign Up Button
                    ResumedButton(
                        title: isLoading ? "Criando conta..." : "Criar conta",
                        style: .primary,
                        action: signUp,
                        icon: "arrow.right",
                        isDisabled: !isFormValid || isLoading,
                        fullWidth: true
                    )

                    Spacer(minLength: Spacing.xl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.resumed.black)
            .navigationTitle("Nova Conta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
            .alert("Erro", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func signUp() {
        isLoading = true
        HapticManager.shared.impact(.medium)

        Task {
            do {
                _ = try await SupabaseManager.shared.signUp(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password,
                    fullName: name.trimmingCharacters(in: .whitespaces)
                )
                appState.isAuthenticated = true
                appState.hasCompletedOnboarding = false
                isLoading = false
                HapticManager.shared.success()
                dismiss()
            } catch {
                isLoading = false
                errorMessage = "Não foi possível criar a conta. Verifique seus dados e tente novamente."
                showError = true
                HapticManager.shared.error()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
}
