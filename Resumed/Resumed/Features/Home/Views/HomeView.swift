//
//  HomeView.swift
//  Resumed
//
//  Home View - Dashboard
//

import SwiftUI
import Combine
import WidgetKit

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()

    enum HomeDestination: Hashable {
        case settings
        case studyPlan
        case exams
        case dailyChallenges
        case studyGroups
        case questionsHub
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                HomeHeader(
                    userName: appState.user?.name
                        ?? SupabaseManager.shared.currentUser?.firstName
                        ?? "Estudante",
                    targetExam: viewModel.targetExam,
                    streak: viewModel.streak
                )

                // Exam countdown or reminder
                if viewModel.hasNoExams {
                    NavigationLink(value: HomeDestination.settings) {
                        SetExamReminderContent()
                    }
                } else {
                    ForEach(viewModel.userExams) { exam in
                        ExamCountdownCard(
                            daysRemaining: exam.daysRemaining,
                            targetExam: exam.name
                        )
                    }
                }

                // Quick stats
                QuickStatsSection(stats: viewModel.quickStats)

                // Continue studying — primary CTA
                ContinueStudyingCard(
                    pendingCards: viewModel.pendingCards,
                    pendingReviews: viewModel.pendingReviewsToday
                )

                // Smart shortcuts — only features NOT on the tab bar
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Atalhos")
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)

                    HStack(spacing: Spacing.md) {
                        NavigationLink(value: HomeDestination.studyPlan) {
                            SmartShortcutLabel(title: "Meu Plano", icon: "calendar", color: .resumed.gold)
                        }
                        NavigationLink(value: HomeDestination.exams) {
                            SmartShortcutLabel(title: "Provas", icon: "doc.text.fill", color: .resumed.info)
                        }
                        NavigationLink(value: HomeDestination.questionsHub) {
                            SmartShortcutLabel(title: "Questões", icon: "pencil.and.list.clipboard", color: .resumed.success)
                        }
                        NavigationLink(value: HomeDestination.dailyChallenges) {
                            SmartShortcutLabel(title: "Desafios", icon: "flame.fill", color: .resumed.warning)
                        }
                    }
                }

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
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: HomeDestination.settings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(.resumed.gray)
                }
            }
        }
        .navigationDestination(for: HomeDestination.self) { destination in
            switch destination {
            case .settings: SettingsView()
            case .studyPlan: StudyPlanView()
            case .exams: PastExamsView()
            case .dailyChallenges: DailyChallengesView()
            case .studyGroups: StudyGroupView()
            case .questionsHub: QuestionsHubView()
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
    @Published var daysRemaining: Int?
    @Published var examDateValue: Date?
    @Published var userExams: [UserExam] = []
    @Published var hasNoExams = false
    @Published var pendingReviewsToday = 0

    struct QuickStat: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
    }

    func loadData() async {
        // Load exams from multi-exam store
        userExams = UserExamStore.load().filter { $0.isFuture }.sorted { $0.date < $1.date }
        hasNoExams = userExams.isEmpty
        StudyWidgetDataBridge.syncExamCountdown()

        // Use nearest future exam for countdown
        if let nearest = userExams.first {
            daysRemaining = nearest.daysRemaining
            examDateValue = nearest.date
            targetExam = nearest.name
        } else if let exam = UserDefaults.standard.string(forKey: "targetExam"), !exam.isEmpty {
            targetExam = exam
        }

        // Count today's pending spaced reviews
        let todayReviews = SpacedReviewStore.reviewsForDate(Date())
        pendingReviewsToday = todayReviews.count
        // Always read real local stats first
        let snapshot = ProgressTracker.shared.snapshot()
        let localQuestions = snapshot.totalQuestions
        let localAccuracy: Int = snapshot.totalQuestions > 0
            ? Int(Double(snapshot.totalCorrect) / Double(snapshot.totalQuestions) * 100)
            : 0
        let localMinutes = snapshot.studyMinutes
        let localHours = localMinutes / 60

        do {
            let stats: UserStats
            if APIClient.mode == .mock {
                stats = try await MockAPIClient.shared.getUserStats()
            } else {
                stats = try await APIClient.shared.getUserStats()
            }
            self.streak = stats.streak

            // Prefer local real data; fall back to API mock only when local has 0
            let questionsValue = localQuestions > 0 ? localQuestions : stats.totalQuestionsAnswered
            let accuracyValue = localQuestions > 0 ? "\(localAccuracy)%" : stats.accuracyPercentage
            let timeValue = localMinutes > 0 ? (localHours > 0 ? "\(localHours)h" : "\(localMinutes)min") : stats.studyTimeFormatted

            self.quickStats = [
                QuickStat(title: "Questões", value: "\(questionsValue)", icon: "checkmark.circle"),
                QuickStat(title: "Acurácia", value: accuracyValue, icon: "chart.bar"),
                QuickStat(title: "Tempo", value: timeValue, icon: "clock")
            ]
        } catch {
            // Use real local data; only use hardcoded mock if everything is zero
            if localQuestions > 0 || localMinutes > 0 {
                self.quickStats = [
                    QuickStat(title: "Questões", value: "\(localQuestions)", icon: "checkmark.circle"),
                    QuickStat(title: "Acurácia", value: "\(localAccuracy)%", icon: "chart.bar"),
                    QuickStat(title: "Tempo", value: localHours > 0 ? "\(localHours)h" : "\(localMinutes)min", icon: "clock")
                ]
            } else {
                loadMockData()
            }
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

// MARK: - Continue Studying Card (primary CTA)

struct ContinueStudyingCard: View {
    @EnvironmentObject var appState: AppState
    let pendingCards: Int
    var pendingReviews: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Continuar Estudando")
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)

            if pendingReviews > 0 {
                NavigationLink(value: HomeView.HomeDestination.studyPlan) {
                    ResumedCard {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.resumed.info.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: IconSize.lg))
                                    .foregroundColor(.resumed.info)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Revisões Espaçadas")
                                    .font(.resumed.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.resumed.white)
                                Text("\(pendingReviews) revisões pendentes para hoje")
                                    .font(.resumed.caption)
                                    .foregroundColor(.resumed.gray)
                            }

                            Spacer()

                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: IconSize.lg))
                                .foregroundColor(.resumed.info)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(Color.resumed.info.opacity(0.2), lineWidth: 1)
                    )
                }
            }

            if pendingCards > 0 {
                Button {
                    appState.navigateTo(.cards)
                } label: {
                    ResumedCard {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.resumed.gold.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "rectangle.stack.fill")
                                    .font(.system(size: IconSize.lg))
                                    .foregroundColor(.resumed.gold)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Revisar ResuCards")
                                    .font(.resumed.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.resumed.white)
                                Text("\(pendingCards) cards pendentes para hoje")
                                    .font(.resumed.caption)
                                    .foregroundColor(.resumed.gray)
                            }

                            Spacer()

                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: IconSize.lg))
                                .foregroundColor(.resumed.gold)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(Color.resumed.gold.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - Smart Shortcut Label (used inside NavigationLink)

struct SmartShortcutLabel: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(color.opacity(0.1))
                    .frame(height: 56)

                Image(systemName: icon)
                    .font(.system(size: IconSize.lg))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Exam Countdown Card

struct ExamCountdownCard: View {
    let daysRemaining: Int
    let targetExam: String

    private var urgencyColor: Color {
        switch daysRemaining {
        case ..<30: return .resumed.error
        case 30..<90: return .resumed.gold
        default: return .resumed.success
        }
    }

    private var urgencyMessage: String {
        switch daysRemaining {
        case 0: return "Hoje é o dia!"
        case 1: return "Amanhã é o grande dia!"
        case ..<30: return "Reta final! Foco total."
        case 30..<90: return "Mantenha o ritmo!"
        default: return "Tempo a seu favor. Aproveite!"
        }
    }

    var body: some View {
        ResumedCard {
            HStack(spacing: Spacing.md) {
                VStack(spacing: Spacing.xs) {
                    Text("\(daysRemaining)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(urgencyColor)
                    Text("dias")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
                .frame(width: 72)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Faltam para o \(targetExam)")
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)

                    Text(urgencyMessage)
                        .font(.resumed.bodySmall)
                        .foregroundColor(.resumed.gray)
                }

                Spacer()

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: IconSize.lg))
                    .foregroundColor(urgencyColor.opacity(0.6))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(urgencyColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Set Exam Reminder Content (no navigation — parent handles it)

struct SetExamReminderContent: View {
    var body: some View {
        ResumedCard {
            HStack(spacing: Spacing.md) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: IconSize.xl))
                    .foregroundColor(.resumed.warning)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Configure suas provas")
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)

                    Text("Adicione as datas das provas que vai prestar para acompanhar a contagem regressiva.")
                        .font(.resumed.bodySmall)
                        .foregroundColor(.resumed.gray)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.resumed.gray)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.resumed.warning.opacity(0.3), lineWidth: 1)
        )
    }
}
