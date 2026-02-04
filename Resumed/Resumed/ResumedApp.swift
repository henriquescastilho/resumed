//
//  ResumedApp.swift
//  Resumed
//
//  Medical Residency Preparation App
//

import SwiftUI
import Combine

@main
struct ResumedApp: App {
    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        // Navigation Bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.resumed.black)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.resumed.white)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.resumed.white)]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.resumed.gold)

        // Tab Bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.resumed.blackSecondary)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
