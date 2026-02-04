//
//  DailyChallengesView.swift
//  Resumed
//
//  Daily Challenges - Gamification System
//

import SwiftUI
import Combine

struct DailyChallengesView: View {
    @StateObject private var viewModel = DailyChallengesViewModel()
    @State private var selectedChallenge: DailyChallenge?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header with timer
                ChallengeHeader(timeRemaining: viewModel.timeUntilReset)

                // Featured Challenge
                if let featured = viewModel.featuredChallenge {
                    FeaturedChallengeCard(challenge: featured) {
                        selectedChallenge = featured
                    }
                }

                // Today's Challenges
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text("Desafios de Hoje")
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)

                        Spacer()

                        Text("\(viewModel.completedCount)/\(viewModel.challenges.count)")
                            .font(.resumed.body)
                            .foregroundColor(.resumed.gold)
                    }

                    ForEach(viewModel.challenges) { challenge in
                        ChallengeCard(challenge: challenge) {
                            selectedChallenge = challenge
                        }
                    }
                }

                // Streak Bonus
                StreakBonusCard(streak: viewModel.challengeStreak)

                // Weekly Progress
                WeeklyProgressCard(progress: viewModel.weeklyProgress)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
        }
        .background(Color.resumed.black)
        .navigationTitle("Desafios")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedChallenge) { challenge in
            ChallengeDetailSheet(challenge: challenge, viewModel: viewModel)
        }
        .task {
            await viewModel.loadChallenges()
        }
    }
}

// MARK: - View Model

@MainActor
class DailyChallengesViewModel: ObservableObject {
    @Published var challenges: [DailyChallenge] = []
    @Published var featuredChallenge: DailyChallenge?
    @Published var challengeStreak: Int = 0
    @Published var weeklyProgress: [Bool] = []
    @Published var isLoading = false

    var completedCount: Int {
        challenges.filter { $0.isCompleted }.count
    }

    var timeUntilReset: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        return tomorrow.timeIntervalSince(now)
    }

    func loadChallenges() async {
        isLoading = true

        // Simulate API call
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Load mock data
        challenges = [
            DailyChallenge(
                id: "1",
                type: .questions,
                title: "Questões Rápidas",
                description: "Acerte 5 questões de Clínica Médica",
                target: 5,
                current: 3,
                xpReward: 50,
                subject: "Clínica Médica",
                difficulty: .easy,
                icon: "checkmark.circle"
            ),
            DailyChallenge(
                id: "2",
                type: .flashcards,
                title: "Mestre da Memória",
                description: "Revise 10 flashcards",
                target: 10,
                current: 0,
                xpReward: 75,
                subject: nil,
                difficulty: .medium,
                icon: "rectangle.stack"
            ),
            DailyChallenge(
                id: "3",
                type: .time,
                title: "Maratonista",
                description: "Estude por 30 minutos",
                target: 30,
                current: 15,
                xpReward: 100,
                subject: nil,
                difficulty: .medium,
                icon: "clock"
            ),
            DailyChallenge(
                id: "4",
                type: .accuracy,
                title: "Precisão Máxima",
                description: "Acerte 10 questões seguidas",
                target: 10,
                current: 0,
                xpReward: 150,
                subject: nil,
                difficulty: .hard,
                icon: "target"
            ),
            DailyChallenge(
                id: "5",
                type: .subject,
                title: "Explorador",
                description: "Responda questões de 3 matérias diferentes",
                target: 3,
                current: 1,
                xpReward: 80,
                subject: nil,
                difficulty: .easy,
                icon: "books.vertical"
            )
        ]

        featuredChallenge = DailyChallenge(
            id: "featured",
            type: .special,
            title: "Desafio Especial",
            description: "Complete TODOS os desafios de hoje",
            target: 5,
            current: completedCount,
            xpReward: 500,
            subject: nil,
            difficulty: .legendary,
            icon: "star.fill",
            isFeatured: true
        )

        challengeStreak = 7
        weeklyProgress = [true, true, true, true, true, true, false]

        isLoading = false
    }

    func startChallenge(_ challenge: DailyChallenge) {
        // Navigate to appropriate view based on challenge type
        FirebaseManager.shared.logEvent(.featureUsed, parameters: [
            "feature": "daily_challenge",
            "challenge_id": challenge.id,
            "challenge_type": challenge.type.rawValue
        ])
    }

    func completeChallenge(_ challenge: DailyChallenge) {
        if let index = challenges.firstIndex(where: { $0.id == challenge.id }) {
            challenges[index].isCompleted = true
            challenges[index].current = challenges[index].target

            // Add XP
            GamificationManager.shared.addXP(challenge.xpReward, reason: .studySession)

            HapticManager.shared.celebration()

            FirebaseManager.shared.logEvent(.featureUsed, parameters: [
                "feature": "daily_challenge_completed",
                "challenge_id": challenge.id,
                "xp_earned": challenge.xpReward
            ])
        }
    }
}

// MARK: - Models

struct DailyChallenge: Identifiable {
    let id: String
    let type: ChallengeType
    let title: String
    let description: String
    let target: Int
    var current: Int
    let xpReward: Int
    let subject: String?
    let difficulty: ChallengeDifficulty
    let icon: String
    var isCompleted: Bool = false
    var isFeatured: Bool = false

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var progressText: String {
        "\(current)/\(target)"
    }
}

enum ChallengeType: String {
    case questions
    case flashcards
    case time
    case accuracy
    case subject
    case special
}

enum ChallengeDifficulty: String {
    case easy = "Fácil"
    case medium = "Médio"
    case hard = "Difícil"
    case legendary = "Lendário"

    var color: Color {
        switch self {
        case .easy: return .resumed.success
        case .medium: return .resumed.warning
        case .hard: return .resumed.error
        case .legendary: return .resumed.gold
        }
    }
}

// MARK: - Challenge Header

struct ChallengeHeader: View {
    let timeRemaining: TimeInterval
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var currentTime: TimeInterval

    init(timeRemaining: TimeInterval) {
        self.timeRemaining = timeRemaining
        self._currentTime = State(initialValue: timeRemaining)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Desafios Diários")
                    .font(.resumed.h3)
                    .foregroundColor(.resumed.white)

                Text("Novos desafios em \(formattedTime)")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }

            Spacer()

            // Timer
            HStack(spacing: Spacing.xs) {
                Image(systemName: "clock")
                    .foregroundColor(.resumed.gold)

                Text(formattedTime)
                    .font(.resumed.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.resumed.gold)
                    .monospacedDigit()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.resumed.gold.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.lg)
        .onReceive(timer) { _ in
            if currentTime > 0 {
                currentTime -= 1
            }
        }
    }

    var formattedTime: String {
        let hours = Int(currentTime) / 3600
        let minutes = (Int(currentTime) % 3600) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Featured Challenge Card

struct FeaturedChallengeCard: View {
    let challenge: DailyChallenge
    let action: () -> Void

    @State private var animate = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.md) {
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.resumed.gold.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .scaleEffect(animate ? 1.1 : 1)

                        Image(systemName: challenge.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.resumed.gold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("DESAFIO ESPECIAL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.resumed.gold)

                            Spacer()

                            Text("+\(challenge.xpReward) XP")
                                .font(.resumed.body)
                                .fontWeight(.bold)
                                .foregroundColor(.resumed.gold)
                        }

                        Text(challenge.title)
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)

                        Text(challenge.description)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                }

                // Progress
                VStack(spacing: Spacing.xs) {
                    ProgressView(value: challenge.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .resumed.gold))

                    HStack {
                        Text(challenge.progressText)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        Spacer()

                        if challenge.isCompleted {
                            Label("Completo!", systemImage: "checkmark.circle.fill")
                                .font(.resumed.caption)
                                .foregroundColor(.resumed.success)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                LinearGradient(
                    colors: [Color.resumed.gold.opacity(0.15), Color.resumed.blackSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.resumed.gold.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Challenge Card

struct ChallengeCard: View {
    let challenge: DailyChallenge
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(challenge.isCompleted ? Color.resumed.success.opacity(0.2) : Color.resumed.blackTertiary)
                        .frame(width: 44, height: 44)

                    if challenge.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.resumed.success)
                    } else {
                        Image(systemName: challenge.icon)
                            .font(.system(size: 18))
                            .foregroundColor(.resumed.white)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(challenge.title)
                            .font(.resumed.body)
                            .fontWeight(.semibold)
                            .foregroundColor(challenge.isCompleted ? .resumed.gray : .resumed.white)

                        Spacer()

                        // Difficulty badge
                        Text(challenge.difficulty.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(challenge.difficulty.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(challenge.difficulty.color.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Text(challenge.description)
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                        .lineLimit(1)

                    // Progress bar
                    HStack(spacing: Spacing.sm) {
                        ProgressView(value: challenge.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: challenge.isCompleted ? .resumed.success : .resumed.gold))

                        Text(challenge.progressText)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                            .frame(width: 40, alignment: .trailing)
                    }
                }

                // XP Reward
                VStack(spacing: 2) {
                    Text("+\(challenge.xpReward)")
                        .font(.resumed.body)
                        .fontWeight(.bold)
                        .foregroundColor(challenge.isCompleted ? .resumed.gray : .resumed.gold)

                    Text("XP")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
            }
            .padding(Spacing.md)
            .background(Color.resumed.blackSecondary)
            .cornerRadius(CornerRadius.md)
            .opacity(challenge.isCompleted ? 0.7 : 1)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(challenge.isCompleted)
    }
}

// MARK: - Streak Bonus Card

struct StreakBonusCard: View {
    let streak: Int

    var bonusMultiplier: Double {
        1.0 + (Double(min(streak, 30)) * 0.1) // Max 4x at 30 days
    }

    var body: some View {
        ResumedCard(background: Color.resumed.gold.opacity(0.1)) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Bônus de Streak")
                        .font(.resumed.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.resumed.white)

                    Text("\(streak) dias seguidos completando desafios")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "%.1fx", bonusMultiplier))
                        .font(.resumed.h3)
                        .foregroundColor(.resumed.gold)

                    Text("XP")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
            }
        }
    }
}

// MARK: - Weekly Progress Card

struct WeeklyProgressCard: View {
    let progress: [Bool]
    let days = ["S", "T", "Q", "Q", "S", "S", "D"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Progresso Semanal")
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)

            HStack(spacing: Spacing.sm) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(progress.indices.contains(index) && progress[index]
                                      ? Color.resumed.success
                                      : Color.resumed.blackTertiary)
                                .frame(width: 36, height: 36)

                            if progress.indices.contains(index) && progress[index] {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(days[index])
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Challenge Detail Sheet

struct ChallengeDetailSheet: View {
    let challenge: DailyChallenge
    @ObservedObject var viewModel: DailyChallengesViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                // Icon
                ZStack {
                    Circle()
                        .fill(challenge.difficulty.color.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: challenge.icon)
                        .font(.system(size: 40))
                        .foregroundColor(challenge.difficulty.color)
                }

                // Title & Description
                VStack(spacing: Spacing.sm) {
                    Text(challenge.title)
                        .font(.resumed.h2)
                        .foregroundColor(.resumed.white)

                    Text(challenge.description)
                        .font(.resumed.body)
                        .foregroundColor(.resumed.gray)
                        .multilineTextAlignment(.center)
                }

                // Stats
                HStack(spacing: Spacing.xl) {
                    VStack {
                        Text(challenge.difficulty.rawValue)
                            .font(.resumed.h4)
                            .foregroundColor(challenge.difficulty.color)
                        Text("Dificuldade")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }

                    VStack {
                        Text("+\(challenge.xpReward)")
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.gold)
                        Text("XP")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }

                    VStack {
                        Text(challenge.progressText)
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)
                        Text("Progresso")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                }

                // Progress bar
                VStack(spacing: Spacing.xs) {
                    ProgressView(value: challenge.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .resumed.gold))
                        .scaleEffect(y: 2)

                    Text("\(Int(challenge.progress * 100))% completo")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()

                // Action Button
                if challenge.isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Desafio Completo!")
                    }
                    .font(.resumed.button)
                    .foregroundColor(.resumed.success)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.buttonHeight)
                    .background(Color.resumed.success.opacity(0.2))
                    .cornerRadius(CornerRadius.md)
                } else {
                    ResumedButton(
                        title: "Começar Desafio",
                        style: .primary,
                        action: {
                            viewModel.startChallenge(challenge)
                            dismiss()
                        },
                        icon: "play.fill",
                        fullWidth: true
                    )
                }
            }
            .padding(Spacing.md)
            .background(Color.resumed.black)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        DailyChallengesView()
    }
}
