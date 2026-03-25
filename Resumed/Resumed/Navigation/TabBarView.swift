//
//  TabBarView.swift
//  Resumed
//
//  Main Tab Bar Navigation
//

import SwiftUI
import WidgetKit

enum Tab: String, CaseIterable {
    case home = "Home"
    case focus = "Foco"
    case grey = "Grey"
    case cards = "ResuCard"
    case performance = "Progresso"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .focus: return "timer"
        case .grey: return "brain.head.profile.fill"
        case .cards: return "rectangle.stack.fill"
        case .performance: return "chart.bar.fill"
        }
    }

    var iconOutline: String {
        switch self {
        case .home: return "house"
        case .focus: return "timer"
        case .grey: return "brain.head.profile"
        case .cards: return "rectangle.stack"
        case .performance: return "chart.bar"
        }
    }
}

struct TabBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        AdaptiveTabView(selectedTab: $appState.selectedTab)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    let pending = StudyWidgetDataBridge.pendingCompletions()
                    guard !pending.isEmpty else { return }
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
    }
}

// MARK: - Grey Coming Soon

struct GreyComingSoonView: View {
    @State private var showContent = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            Color.resumed.black.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Animated brain icon
                ZStack {
                    // Outer pulse rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.resumed.gold.opacity(0.08 - Double(i) * 0.02), lineWidth: 1.5)
                            .frame(width: 140 + CGFloat(i) * 50, height: 140 + CGFloat(i) * 50)
                            .scaleEffect(pulseAnimation ? 1.05 : 0.95)
                            .animation(
                                .easeInOut(duration: 2.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                                value: pulseAnimation
                            )
                    }

                    // Inner glow
                    Circle()
                        .fill(Color.resumed.gold.opacity(0.08))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showContent ? 1 : 0.5)

                    // Icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.resumed.gold, Color.resumed.gold.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showContent ? 1 : 0)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: showContent)

                // Text
                VStack(spacing: Spacing.md) {
                    Text("Grey")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.resumed.gold)

                    Text("Sua tutora de medicina com IA")
                        .font(.resumed.body)
                        .foregroundColor(.resumed.white)

                    Text("Estamos treinando a Grey para oferecer a melhor experiência possível na sua preparação para a residência médica.")
                        .font(.resumed.bodySmall)
                        .foregroundColor(.resumed.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.xs)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: showContent)

                // Status pill
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(Color.resumed.gold)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 1).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )

                    Text("Em desenvolvimento")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.resumed.gold)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.resumed.gold.opacity(0.1))
                .cornerRadius(CornerRadius.round)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.7), value: showContent)

                Spacer()
                Spacer()
            }
            .padding(.bottom, Layout.tabBarHeight)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            showContent = true
            pulseAnimation = true
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                    HapticManager.shared.selection()
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Color.resumed.black
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.resumed.border.opacity(0.5))
                        .frame(height: 0.5)
                }
        )
    }
}

// MARK: - Tab Bar Item (uniform for all tabs)

private struct TabBarItem: View {
    let tab: Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.icon : tab.iconOutline)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .resumed.gold : .resumed.gray.opacity(0.5))
                    .frame(height: 24)

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .resumed.gold : .resumed.gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
