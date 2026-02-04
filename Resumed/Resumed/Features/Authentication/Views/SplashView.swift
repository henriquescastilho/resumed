//
//  SplashView.swift
//  Resumed
//
//  Animated Splash Screen
//

import SwiftUI
import Combine

struct SplashView: View {
    @Binding var isFinished: Bool

    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color.resumed.black.ignoresSafeArea()

            // Animated gradient background
            RadialGradient(
                colors: [
                    Color.resumed.gold.opacity(0.15),
                    Color.resumed.black
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .scaleEffect(pulseAnimation ? 1.2 : 1)
            .animation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true),
                value: pulseAnimation
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Logo container
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.resumed.gold.opacity(0.5), Color.resumed.gold.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(showLogo ? 1 : 0.3)
                        .opacity(showLogo ? 1 : 0)
                        .rotationEffect(.degrees(rotationAngle))

                    // Middle ring
                    Circle()
                        .stroke(Color.resumed.gold.opacity(0.3), lineWidth: 2)
                        .frame(width: 150, height: 150)
                        .scaleEffect(showLogo ? 1 : 0.5)
                        .opacity(showLogo ? 1 : 0)
                        .rotationEffect(.degrees(-rotationAngle * 0.5))

                    // Inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.resumed.gold.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(showLogo ? 1 : 0)
                        .opacity(showLogo ? 1 : 0)

                    // Brain icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 70, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.resumed.gold, Color.resumed.goldLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showLogo ? 1 : 0)
                        .rotationEffect(.degrees(showLogo ? 0 : -45))
                        .shadow(color: Color.resumed.gold.opacity(0.5), radius: 20)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showLogo)

                // Title
                VStack(spacing: Spacing.sm) {
                    Text("RESUMED")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.resumed.gold, Color.resumed.goldLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.resumed.gold.opacity(0.3), radius: 10)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 30)

                    Text("Sua aprovação, nosso compromisso")
                        .font(.resumed.body)
                        .foregroundColor(.resumed.gray)
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 20)
                }
                .animation(.easeOut(duration: 0.6), value: showTitle)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: showTagline)

                Spacer()

                // Loading indicator
                LoadingDotsView()
                    .opacity(showTagline ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.5), value: showTagline)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            runAnimation()
        }
    }

    private func runAnimation() {
        // Start pulse animation
        pulseAnimation = true

        // Start rotation animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Sequence the appearance animations
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            showLogo = true
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            showTitle = true
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.9)) {
            showTagline = true
        }

        // Finish splash after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isFinished = true
            }
        }
    }
}

// MARK: - Loading Dots Animation

struct LoadingDotsView: View {
    @State private var dotScales: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.resumed.gold)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScales[index])
            }
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(
                    .easeInOut(duration: 0.4)
                    .repeatForever(autoreverses: true)
                ) {
                    dotScales[index] = 1.5
                }
            }
        }
    }
}

// MARK: - Alternative Splash (Simpler Version)

struct SimpleSplashView: View {
    @Binding var isFinished: Bool

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.resumed.black.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(.resumed.gold)

                Text("RESUMED")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.resumed.gold)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1
                opacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFinished = true
                }
            }
        }
    }
}

// MARK: - Launch Screen Animation Controller

@MainActor
class SplashController: ObservableObject {
    @Published var isSplashFinished = false

    func completeSplash() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isSplashFinished = true
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView(isFinished: .constant(false))
}
