//
//  AdaptiveLayout.swift
//  Resumed
//
//  iPad adaptive layout support — constrains content width and provides
//  responsive containers that work on both iPhone and iPad.
//

import SwiftUI

// MARK: - Adaptive Content Modifier

/// Constrains content to a max width on iPad while keeping full width on iPhone.
/// Centers the content horizontally when constrained.
struct AdaptiveContentModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var maxWidth: CGFloat

    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}

extension View {
    /// Constrains content width on iPad. No-op on iPhone.
    func adaptiveWidth(_ maxWidth: CGFloat = 600) -> some View {
        modifier(AdaptiveContentModifier(maxWidth: maxWidth))
    }
}

// MARK: - Adaptive Navigation (Tab Bar vs Sidebar)

/// On iPhone: standard custom tab bar at the bottom.
/// On iPad: sidebar navigation on the leading edge.
struct AdaptiveTabView: View {
    @Binding var selectedTab: Tab
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPhone (custom tab bar)

    private var iPhoneLayout: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    NavigationStack {
                        tabContent(for: tab)
                    }
                    .tag(tab)
                }
            }

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            UITabBar.appearance().isHidden = true
        }
    }

    // MARK: - iPad (sidebar + detail)

    private var iPadLayout: some View {
        NavigationSplitView {
            sidebar
                .navigationTitle("Resumed")
                .navigationBarTitleDisplayMode(.large)
        } detail: {
            NavigationStack {
                tabContent(for: selectedTab)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebar: some View {
        List(Tab.allCases, id: \.rawValue, selection: Binding(
            get: { selectedTab.rawValue },
            set: { if let raw = $0, let tab = Tab(rawValue: raw) { selectedTab = tab } }
        )) { tab in
            Label {
                Text(tab.rawValue)
                    .font(.resumed.body)
            } icon: {
                Image(systemName: selectedTab == tab ? tab.icon : tab.iconOutline)
                    .foregroundColor(selectedTab == tab ? .resumed.gold : .resumed.gray)
            }
            .tag(tab.rawValue)
            .listRowBackground(
                selectedTab == tab
                    ? Color.resumed.gold.opacity(0.1)
                    : Color.clear
            )
        }
        .scrollContentBackground(.hidden)
        .background(Color.resumed.black)
        .tint(.resumed.gold)
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        Group {
            switch tab {
            case .home: HomeView()
            case .focus: FocusView()
            case .grey: GreyComingSoonView()
            case .cards: ResuCardsView()
            case .performance: PerformanceView()
            }
        }
        .adaptiveWidth()
    }
}
