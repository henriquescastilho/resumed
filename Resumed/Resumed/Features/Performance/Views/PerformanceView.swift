//
//  PerformanceView.swift
//  Resumed
//
//  Performance View - Analytics Dashboard
//

import SwiftUI
import Charts
import Combine

struct PerformanceView: View {
    @StateObject private var viewModel = PerformanceViewModel()
    @State private var showAccuracyBreakdown = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                PerformanceIntroCard()

                // Level section
                LevelSection(
                    level: viewModel.level,
                    currentXP: viewModel.currentXP,
                    totalXP: viewModel.xpToNextLevel,
                    title: viewModel.levelTitle
                )

                // Stats cards
                StatsCardsSection(
                    stats: viewModel.stats,
                    onAccuracyTap: viewModel.subjectStats.isEmpty ? nil : {
                        showAccuracyBreakdown = true
                    }
                )

                // Subject performance
                SubjectPerformanceSection(subjects: viewModel.subjectStats)

                // Weak topics
                WeakTopicsSection(topics: viewModel.weakTopics)

                // Badges
                BadgesSection(badges: Badge.allCases, unlockedBadges: viewModel.unlockedBadges)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
        }
        .background(Color.resumed.black)
        .navigationTitle("Progresso")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showAccuracyBreakdown) {
            AccuracyBreakdownSheet(subjects: viewModel.subjectStats)
        }
    }
}

private struct PerformanceIntroCard: View {
    var body: some View {
        ResumedCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Como funciona o Progresso")
                    .font(.resumed.h4)
                    .foregroundColor(.resumed.white)

                Text("Aqui você acompanha sua evolução por matéria, o nível de XP e os pontos a melhorar. As métricas vêm das suas questões, ResuCards e sessões de estudo.")
                    .font(.resumed.bodySmall)
                    .foregroundColor(.resumed.gray)

                HStack(spacing: Spacing.sm) {
                    Label("XP e nível", systemImage: "star.fill")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gold)
                    Label("Matérias", systemImage: "chart.bar")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
            }
        }
    }
}

@MainActor
class PerformanceViewModel: ObservableObject {
    @Published var level = 12
    @Published var currentXP = 1240
    @Published var xpToNextLevel = 2000
    @Published var levelTitle = "Residente Sênior"
    @Published var stats: [StatItem] = []
    @Published var subjectStats: [SubjectPerformance] = []
    @Published var weakTopics: [WeakTopic] = []
    @Published var unlockedBadges: Set<Badge> = []

    struct StatItem: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let trend: String?
        let trendPositive: Bool
    }

    struct SubjectPerformance: Identifiable {
        let id = UUID()
        let subject: String
        let score: Double
        let questionsAnswered: Int
        let correctAnswers: Int
        let color: Color
    }

    struct WeakTopic: Identifiable {
        let id = UUID()
        let subject: String
        let topic: String
        let accuracy: Double
    }

    func loadData() async {
        do {
            let userStats: UserStats
            if APIClient.mode == .mock {
                userStats = try await MockAPIClient.shared.getUserStats()
            } else {
                userStats = try await APIClient.shared.getUserStats()
            }
            apply(userStats: userStats)
        } catch {
            loadMockData()
        }
    }

    private func apply(userStats: UserStats) {
        level = userStats.level
        currentXP = userStats.xp
        xpToNextLevel = userStats.xpToNextLevel
        levelTitle = LevelSystem.titleForLevel(level)

        stats = [
            StatItem(title: "Questões", value: "\(userStats.totalQuestionsAnswered)", trend: nil, trendPositive: true),
            StatItem(title: "Acurácia", value: userStats.accuracyPercentage, trend: nil, trendPositive: true),
            StatItem(title: "Streak", value: "\(userStats.streak) dias", trend: nil, trendPositive: true),
            StatItem(title: "Tempo", value: userStats.studyTimeFormatted, trend: nil, trendPositive: true)
        ]

        subjectStats = userStats.subjectStats
            .map { stat in
                SubjectPerformance(
                    subject: stat.subject,
                    score: stat.accuracy,
                    questionsAnswered: stat.questionsAnswered,
                    correctAnswers: stat.correctAnswers,
                    color: subjectColor(for: stat.subject)
                )
            }
            .sorted { $0.subject < $1.subject }

        weakTopics = userStats.subjectStats
            .filter { $0.questionsAnswered > 0 }
            .map { stat in
                WeakTopic(subject: stat.subject, topic: "Revisão prioritária", accuracy: stat.accuracy)
            }
            .sorted { $0.accuracy < $1.accuracy }

        unlockedBadges = Set(userStats.badges.compactMap(Badge.init(rawValue:)))
    }

    private func loadMockData() {
        let snapshot = ProgressTracker.shared.snapshot()
        let totalQuestions = snapshot.totalQuestions
        guard totalQuestions > 0 else {
            apply(userStats: MockData.userStats)
            return
        }
        let accuracy = totalQuestions > 0 ? Int((Double(snapshot.totalCorrect) / Double(totalQuestions)) * 100) : 0
        let studyHours = Double(snapshot.studyMinutes) / 60.0

        stats = [
            StatItem(title: "Questões", value: "\(totalQuestions)", trend: nil, trendPositive: true),
            StatItem(title: "Acurácia", value: "\(accuracy)%", trend: nil, trendPositive: true),
            StatItem(title: "Streak", value: "\(GamificationManager.shared.streak) dias", trend: nil, trendPositive: true),
            StatItem(title: "Tempo", value: String(format: "%.1fh", studyHours), trend: nil, trendPositive: true)
        ]

        subjectStats = snapshot.subjectStats.map { subject, progress in
            SubjectPerformance(
                subject: subject,
                score: progress.accuracy,
                questionsAnswered: progress.questionsAnswered,
                correctAnswers: progress.correctAnswers,
                color: subjectColor(for: subject)
            )
        }.sorted { $0.subject < $1.subject }

        weakTopics = snapshot.subjectStats
            .filter { $0.value.questionsAnswered > 0 }
            .map { subject, progress in
                WeakTopic(subject: subject, topic: "Revisão prioritária", accuracy: progress.accuracy)
            }
            .sorted { $0.accuracy < $1.accuracy }

        unlockedBadges = GamificationManager.shared.unlockedBadges
    }

    private func subjectColor(for subject: String) -> Color {
        switch subject {
        case "Clínica Médica": return .resumed.clinicaMedica
        case "Cirurgia Geral": return .resumed.cirurgia
        case "Pediatria": return .resumed.pediatria
        case "Ginecologia e Obstetrícia": return .resumed.ginecologia
        case "MFC": return .resumed.preventiva
        case "Saúde Mental": return .resumed.warning
        case "Saúde Coletiva": return .resumed.gray
        default: return .resumed.gray
        }
    }
}

struct LevelSection: View {
    let level: Int
    let currentXP: Int
    let totalXP: Int
    let title: String

    var body: some View {
        ResumedCard {
            VStack(spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Level \(level)")
                            .font(.resumed.h2)
                            .foregroundColor(.resumed.gold)
                        Text(title)
                            .font(.resumed.body)
                            .foregroundColor(.resumed.gray)
                    }

                    Spacer()

                    ProgressRing(progress: Double(currentXP) / Double(totalXP), size: 80, lineWidth: 8, showPercentage: false)
                        .overlay {
                            Image(systemName: "star.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.resumed.gold)
                        }
                }

                XPProgressBar(currentXP: currentXP, totalXP: totalXP, level: level)
            }
        }
    }
}

struct StatsCardsSection: View {
    let stats: [PerformanceViewModel.StatItem]
    let onAccuracyTap: (() -> Void)?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            ForEach(stats) { stat in
                Button {
                    if stat.title == "Acurácia" {
                        onAccuracyTap?()
                    }
                } label: {
                    ResumedCard {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack(alignment: .top) {
                                Text(stat.title)
                                    .font(.resumed.caption)
                                    .foregroundColor(.resumed.gray)

                                Spacer()

                                if stat.title == "Acurácia", onAccuracyTap != nil {
                                    Image(systemName: "chevron.right")
                                        .font(.resumed.caption)
                                        .foregroundColor(.resumed.gray)
                                }
                            }

                            HStack(alignment: .bottom, spacing: Spacing.xs) {
                                Text(stat.value)
                                    .font(.resumed.h3)
                                    .foregroundColor(.resumed.white)

                                if let trend = stat.trend {
                                    Text(trend)
                                        .font(.resumed.caption)
                                        .foregroundColor(stat.trendPositive ? .resumed.success : .resumed.error)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AccuracyBreakdownSheet: View {
    let subjects: [PerformanceViewModel.SubjectPerformance]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Acurácia por matéria")
                        .font(.resumed.h3)
                        .foregroundColor(.resumed.white)

                    ForEach(subjects) { subject in
                        ResumedCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    Text(subject.subject)
                                        .font(.resumed.body)
                                        .foregroundColor(.resumed.white)

                                    Spacer()

                                    Text("\(Int(subject.score))%")
                                        .font(.resumed.h4)
                                        .foregroundColor(subject.color)
                                }

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.resumed.blackTertiary)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(subject.color)
                                            .frame(width: geometry.size.width * (subject.score / 100))
                                    }
                                }
                                .frame(height: 12)

                                Text("\(subject.correctAnswers) acertos em \(subject.questionsAnswered) questões")
                                    .font(.resumed.caption)
                                    .foregroundColor(.resumed.gray)
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.resumed.black)
            .navigationTitle("Acurácia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.resumed.gold)
                }
            }
        }
    }
}

struct SubjectPerformanceSection: View {
    let subjects: [PerformanceViewModel.SubjectPerformance]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Competência por Matéria")
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)

            ResumedCard {
                VStack(spacing: Spacing.md) {
                    ForEach(subjects) { subject in
                        HStack(spacing: Spacing.sm) {
                            Text(subject.subject)
                                .font(.resumed.bodySmall)
                                .foregroundColor(.resumed.gray)
                                .frame(width: 70, alignment: .leading)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.resumed.blackTertiary)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(subject.color)
                                        .frame(width: geometry.size.width * (subject.score / 100))
                                }
                            }
                            .frame(height: 20)

                            Text("\(Int(subject.score))%")
                                .font(.resumed.bodySmall)
                                .foregroundColor(.resumed.white)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}

struct WeakTopicsSection: View {
    let topics: [PerformanceViewModel.WeakTopic]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Pontos a Melhorar")
                    .font(.resumed.h4)
                    .foregroundColor(.resumed.white)
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.resumed.warning)
            }

            ForEach(topics) { topic in
                ResumedCard(background: Color.resumed.warning.opacity(0.1)) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(topic.topic)
                                .font(.resumed.body)
                                .foregroundColor(.resumed.white)
                            Text(topic.subject)
                                .font(.resumed.caption)
                                .foregroundColor(.resumed.gray)
                        }

                        Spacer()

                        Text("\(Int(topic.accuracy))%")
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.warning)
                    }
                }
            }
        }
    }
}

struct BadgesSection: View {
    let badges: [Badge]
    let unlockedBadges: Set<Badge>

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Conquistas")
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: Spacing.md) {
                ForEach(badges, id: \.rawValue) { badge in
                    BadgeItem(badge: badge, isUnlocked: unlockedBadges.contains(badge))
                }
            }
        }
    }
}

struct BadgeItem: View {
    let badge: Badge
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.resumed.gold.opacity(0.2) : Color.resumed.blackSecondary)
                    .frame(width: 60, height: 60)

                Image(systemName: badge.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? .resumed.gold : .resumed.gray)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.resumed.gray)
                        .offset(x: 20, y: 20)
                }
            }

            Text(badge.title)
                .font(.resumed.caption)
                .foregroundColor(isUnlocked ? .resumed.white : .resumed.gray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
    }
}
