//
//  HomeView.swift
//  Resumed
//
//  Home View - Dashboard
//

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                HomeHeader(
                    userName: appState.user?.name ?? "Estudante",
                    targetExam: viewModel.targetExam,
                    streak: viewModel.streak
                )

                // Quick stats
                QuickStatsSection(stats: viewModel.quickStats)

                // Modules grid
                ModulesGrid()

                // Today's activity
                TodayActivityCard(pendingCards: viewModel.pendingCards)

                // Quote
                if let quote = viewModel.dailyQuote {
                    MotivationalQuote(quote: quote)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
        }
        .background(Color.resumed.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundColor(.resumed.gold)

                    Text("RESUMED")
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.gold)
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var streak = 7
    @Published var targetExam = "ENAMED"
    @Published var pendingCards = 15
    @Published var quickStats: [QuickStat] = []
    @Published var dailyQuote: String? = "A persistência é o caminho do êxito."

    struct QuickStat: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
    }

    func loadData() async {
        do {
            let stats: UserStats
            if APIClient.mode == .mock {
                stats = try await MockAPIClient.shared.getUserStats()
            } else {
                stats = try await APIClient.shared.getUserStats()
            }
            self.streak = stats.streak
            self.quickStats = [
                QuickStat(title: "Questões", value: "\(stats.totalQuestionsAnswered)", icon: "checkmark.circle"),
                QuickStat(title: "Acurácia", value: stats.accuracyPercentage, icon: "chart.bar"),
                QuickStat(title: "Tempo", value: stats.studyTimeFormatted, icon: "clock")
            ]
        } catch {
            loadMockData()
        }
    }

    private func loadMockData() {
        quickStats = [
            QuickStat(title: "Questões", value: "1.247", icon: "checkmark.circle"),
            QuickStat(title: "Acurácia", value: "78%", icon: "chart.bar"),
            QuickStat(title: "Tempo", value: "42h", icon: "clock")
        ]
    }
}

struct HomeHeader: View {
    let userName: String
    let targetExam: String
    let streak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Olá, \(userName.components(separatedBy: " ").first ?? userName)")
                .font(.resumed.h2)
                .foregroundColor(.resumed.white)

            HStack(spacing: Spacing.sm) {
                Text(targetExam)
                    .font(.resumed.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.resumed.gold)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.resumed.gold.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)

                StreakDisplay(streak: streak, size: .medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.md)
    }
}

struct QuickStatsSection: View {
    let stats: [HomeViewModel.QuickStat]

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(stats) { stat in
                ResumedCard {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: stat.icon)
                            .font(.system(size: IconSize.md))
                            .foregroundColor(.resumed.gold)

                        Text(stat.value)
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)

                        Text(stat.title)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct ModulesGrid: View {
    @EnvironmentObject var appState: AppState
    @State private var showGrey = false
    @State private var showExams = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Módulos")
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ModuleCard(title: "GPS", subtitle: "Meu Plano", icon: "calendar") {
                    appState.navigateTo(.plan)
                }
                ModuleCard(title: "ResuCard", subtitle: "Revisar", icon: "rectangle.stack.fill") {
                    appState.navigateTo(.cards)
                }
                ModuleCard(title: "Grey", subtitle: "Dúvidas", icon: "brain.head.profile") {
                    showGrey = true
                }
                ModuleCard(title: "Progresso", subtitle: "Analytics", icon: "chart.bar.fill") {
                    appState.navigateTo(.performance)
                }
                ModuleCard(title: "Provas", subtitle: "Simulados", icon: "doc.text.fill") {
                    showExams = true
                }
            }
        }
        .navigationDestination(isPresented: $showGrey) {
            GreyView()
        }
        .navigationDestination(isPresented: $showExams) {
            PastExamsView()
        }
    }
}

struct TodayActivityCard: View {
    @EnvironmentObject var appState: AppState
    let pendingCards: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Atividade para Hoje")
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)

            FeatureCard(
                icon: "brain",
                title: "Revisão Diária",
                subtitle: "\(pendingCards) ResuCards pendentes",
                action: {
                    appState.navigateTo(.cards)
                }
            )
        }
    }
}

struct MotivationalQuote: View {
    let quote: String

    var body: some View {
        ResumedCard(background: Color.resumed.blackTertiary) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: IconSize.lg))
                    .foregroundColor(.resumed.gold.opacity(0.5))

                Text(quote)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gray)
                    .italic()

                Spacer()
            }
        }
    }
}
