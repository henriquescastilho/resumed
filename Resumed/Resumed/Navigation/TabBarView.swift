//
//  TabBarView.swift
//  Resumed
//
//  Main Tab Bar Navigation
//

import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Home"
    case focus = "Foco"
    case plan = "GPS"
    case cards = "ResuCard"
    case performance = "Progresso"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .focus: return "timer"
        case .plan: return "calendar"
        case .cards: return "rectangle.stack.fill"
        case .performance: return "chart.bar.fill"
        }
    }
}

struct TabBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $appState.selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tag(Tab.home)

                NavigationStack {
                    FocusView()
                }
                .tag(Tab.focus)

                NavigationStack {
                    StudyPlanView()
                }
                .tag(Tab.plan)

                NavigationStack {
                    ResuCardsView()
                }
                .tag(Tab.cards)

                NavigationStack {
                    PerformanceView()
                }
                .tag(Tab.performance)
            }

            CustomTabBar(selectedTab: $appState.selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Spacer()

                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                    HapticManager.shared.selection()
                }

                Spacer()
            }
        }
        .padding(.top, Spacing.sm)
        .padding(.bottom, 30)
        .background(
            Color.resumed.blackSecondary
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
    }
}

struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: isSelected ? 22 : 20))
                    .foregroundColor(isSelected ? .resumed.gold : .resumed.gray)

                Text(tab.rawValue)
                    .font(.resumed.tabBar)
                    .foregroundColor(isSelected ? .resumed.gold : .resumed.gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
