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

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Level section
                LevelSection(
                    level: viewModel.level,
                    currentXP: viewModel.currentXP,
                    totalXP: viewModel.xpToNextLevel,
                    title: viewModel.levelTitle
                )

                // Stats cards
                StatsCardsSection(stats: viewModel.stats)

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
            level = userStats.level
            currentXP = userStats.xp
            xpToNextLevel = userStats.xpToNextLevel
            levelTitle = LevelSystem.titleForLevel(level)
        } catch {
            loadMockData()
        }
    }

    private func loadMockData() {
        stats = [
            StatItem(title: "Questões", value: "1.247", trend: "+42", trendPositive: true),
            StatItem(title: "Acurácia", value: "78%", trend: "+5%", trendPositive: true),
            StatItem(title: "Streak", value: "7 dias", trend: nil, trendPositive: true),
            StatItem(title: "Tempo", value: "42h", trend: "+3h", trendPositive: true)
        ]

        subjectStats = [
            SubjectPerformance(subject: "Clínica", score: 82, color: .resumed.clinicaMedica),
            SubjectPerformance(subject: "Cirurgia", score: 68, color: .resumed.cirurgia),
            SubjectPerformance(subject: "Pediatria", score: 75, color: .resumed.pediatria),
            SubjectPerformance(subject: "GO", score: 71, color: .resumed.ginecologia),
            SubjectPerformance(subject: "Preventiva", score: 85, color: .resumed.preventiva)
        ]

        weakTopics = [
            WeakTopic(subject: "Pediatria", topic: "Neonatologia", accuracy: 42),
            WeakTopic(subject: "Cirurgia", topic: "Trauma", accuracy: 48),
            WeakTopic(subject: "Clínica", topic: "Nefrologia", accuracy: 55)
        ]

        unlockedBadges = [.firstQuestion, .weekStreak, .hundredQuestions]
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

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            ForEach(stats) { stat in
                ResumedCard {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(stat.title)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

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
