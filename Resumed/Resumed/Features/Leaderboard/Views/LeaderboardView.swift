//
//  LeaderboardView.swift
//  Resumed
//
//  Leaderboards - Rankings & Competition
//

import SwiftUI
import Combine

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Period Selector
            LeaderboardPeriodPicker(selectedPeriod: $viewModel.selectedPeriod)

            // Category Selector
            LeaderboardCategoryPicker(selectedCategory: $viewModel.selectedCategory)

            // Content
            if viewModel.isLoading {
                LoadingView(message: "Carregando ranking...")
            } else if viewModel.entries.isEmpty {
                EmptyState(
                    icon: "trophy",
                    title: "Nenhum ranking",
                    subtitle: "Seja o primeiro a entrar!"
                )
            } else {
                LeaderboardContent(viewModel: viewModel)
            }
        }
        .background(Color.resumed.black)
        .navigationTitle("Ranking")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadLeaderboard()
        }
        .onChange(of: viewModel.selectedPeriod) { _, _ in
            Task { await viewModel.loadLeaderboard() }
        }
        .onChange(of: viewModel.selectedCategory) { _, _ in
            Task { await viewModel.loadLeaderboard() }
        }
    }
}

// MARK: - View Model

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntryModel] = []
    @Published var currentUserEntry: LeaderboardEntryModel?
    @Published var selectedPeriod: LeaderboardPeriod = .weekly
    @Published var selectedCategory: LeaderboardCategory = .xp
    @Published var isLoading = false

    func loadLeaderboard() async {
        isLoading = true

        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Load mock data
        entries = generateMockLeaderboard()
        currentUserEntry = entries.first { $0.isCurrentUser }

        isLoading = false
    }

    private func generateMockLeaderboard() -> [LeaderboardEntryModel] {
        let names = [
            "Ana Carolina", "Pedro Henrique", "Maria Luísa", "João Gabriel",
            "Beatriz Santos", "Lucas Oliveira", "Fernanda Lima", "Rafael Costa",
            "Juliana Alves", "Bruno Ferreira", "Camila Souza", "Diego Mendes",
            "Amanda Rocha", "Thiago Martins", "Larissa Pereira", "Você"
        ]

        var entries: [LeaderboardEntryModel] = []

        for (index, name) in names.enumerated() {
            let isCurrentUser = name == "Você"
            let baseScore = selectedCategory == .xp ? 15000 : 1000

            entries.append(LeaderboardEntryModel(
                id: "user_\(index)",
                rank: index + 1,
                name: name,
                avatar: nil,
                score: baseScore - (index * (selectedCategory == .xp ? 800 : 50)) + Int.random(in: -100...100),
                isCurrentUser: isCurrentUser,
                badge: index < 3 ? Badge.allCases.randomElement() : nil,
                change: Int.random(in: -5...5)
            ))
        }

        // Sort by score
        entries.sort { $0.score > $1.score }

        // Update ranks
        for i in entries.indices {
            entries[i].rank = i + 1
        }

        return entries
    }
}

// MARK: - Models

struct LeaderboardEntryModel: Identifiable {
    let id: String
    var rank: Int
    let name: String
    let avatar: String?
    let score: Int
    let isCurrentUser: Bool
    let badge: Badge?
    let change: Int // Position change from last period

    var formattedScore: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: score)) ?? "\(score)"
    }
}

enum LeaderboardPeriod: String, CaseIterable {
    case weekly = "Semanal"
    case monthly = "Mensal"
    case allTime = "Geral"

    var icon: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .allTime: return "trophy.fill"
        }
    }
}

enum LeaderboardCategory: String, CaseIterable {
    case xp = "XP"
    case questions = "Questões"
    case accuracy = "Acurácia"
    case streak = "Streak"

    var icon: String {
        switch self {
        case .xp: return "star.fill"
        case .questions: return "checkmark.circle.fill"
        case .accuracy: return "target"
        case .streak: return "flame.fill"
        }
    }

    var unit: String {
        switch self {
        case .xp: return "XP"
        case .questions: return "questões"
        case .accuracy: return "%"
        case .streak: return "dias"
        }
    }
}

// MARK: - Period Picker

struct LeaderboardPeriodPicker: View {
    @Binding var selectedPeriod: LeaderboardPeriod

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                    HapticManager.shared.selection()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: period.icon)
                            .font(.system(size: 16))

                        Text(period.rawValue)
                            .font(.resumed.caption)
                    }
                    .foregroundColor(selectedPeriod == period ? .resumed.gold : .resumed.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(selectedPeriod == period ? Color.resumed.gold.opacity(0.1) : Color.clear)
                    .cornerRadius(CornerRadius.md)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.resumed.blackSecondary)
    }
}

// MARK: - Category Picker

struct LeaderboardCategoryPicker: View {
    @Binding var selectedCategory: LeaderboardCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                        HapticManager.shared.selection()
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))

                            Text(category.rawValue)
                                .font(.resumed.bodySmall)
                        }
                        .foregroundColor(selectedCategory == category ? .resumed.black : .resumed.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(selectedCategory == category ? Color.resumed.gold : Color.resumed.blackTertiary)
                        .cornerRadius(CornerRadius.round)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }
}

// MARK: - Leaderboard Content

struct LeaderboardContent: View {
    @ObservedObject var viewModel: LeaderboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Top 3 Podium
                if viewModel.entries.count >= 3 {
                    PodiumView(entries: Array(viewModel.entries.prefix(3)))
                }

                // Rest of the list
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.entries.dropFirst(3)) { entry in
                        LeaderboardRow(entry: entry, category: viewModel.selectedCategory)
                    }
                }
                .padding(.horizontal, Spacing.md)

                // Current user position (if not in top)
                if let currentUser = viewModel.currentUserEntry,
                   currentUser.rank > 10 {
                    Divider().background(Color.resumed.border)
                        .padding(.vertical, Spacing.sm)

                    LeaderboardRow(entry: currentUser, category: viewModel.selectedCategory, highlighted: true)
                        .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
        }
    }
}

// MARK: - Podium View

struct PodiumView: View {
    let entries: [LeaderboardEntryModel]

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.md) {
            // 2nd Place
            if entries.count > 1 {
                PodiumItem(entry: entries[1], position: 2, height: 100)
            }

            // 1st Place
            PodiumItem(entry: entries[0], position: 1, height: 130)

            // 3rd Place
            if entries.count > 2 {
                PodiumItem(entry: entries[2], position: 3, height: 80)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
    }
}

struct PodiumItem: View {
    let entry: LeaderboardEntryModel
    let position: Int
    let height: CGFloat

    var positionColor: Color {
        switch position {
        case 1: return Color(hex: "FFD700") // Gold
        case 2: return Color(hex: "C0C0C0") // Silver
        case 3: return Color(hex: "CD7F32") // Bronze
        default: return .resumed.gray
        }
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Avatar
            ZStack {
                Circle()
                    .fill(positionColor.opacity(0.2))
                    .frame(width: position == 1 ? 70 : 60, height: position == 1 ? 70 : 60)

                Circle()
                    .stroke(positionColor, lineWidth: 3)
                    .frame(width: position == 1 ? 70 : 60, height: position == 1 ? 70 : 60)

                Text(entry.name.prefix(1).uppercased())
                    .font(.system(size: position == 1 ? 28 : 24, weight: .bold))
                    .foregroundColor(positionColor)

                // Crown for #1
                if position == 1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundColor(positionColor)
                        .offset(y: -45)
                }
            }

            // Name
            Text(entry.name.components(separatedBy: " ").first ?? entry.name)
                .font(.resumed.bodySmall)
                .foregroundColor(.resumed.white)
                .lineLimit(1)

            // Score
            Text(entry.formattedScore)
                .font(.resumed.h4)
                .foregroundColor(positionColor)

            // Podium block
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [positionColor.opacity(0.3), positionColor.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
                .overlay(
                    Text("\(position)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(positionColor)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntryModel
    let category: LeaderboardCategory
    var highlighted: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Rank
            Text("#\(entry.rank)")
                .font(.resumed.body)
                .fontWeight(.bold)
                .foregroundColor(entry.isCurrentUser ? .resumed.gold : .resumed.gray)
                .frame(width: 40, alignment: .leading)

            // Change indicator
            if entry.change != 0 {
                Image(systemName: entry.change > 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 10))
                    .foregroundColor(entry.change > 0 ? .resumed.success : .resumed.error)
            } else {
                Text("—")
                    .font(.system(size: 10))
                    .foregroundColor(.resumed.gray)
            }

            // Avatar
            Circle()
                .fill(entry.isCurrentUser ? Color.resumed.gold.opacity(0.2) : Color.resumed.blackTertiary)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(entry.name.prefix(1).uppercased())
                        .font(.resumed.body)
                        .fontWeight(.semibold)
                        .foregroundColor(entry.isCurrentUser ? .resumed.gold : .resumed.white)
                )

            // Name & Badge
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(entry.name)
                        .font(.resumed.body)
                        .foregroundColor(entry.isCurrentUser ? .resumed.gold : .resumed.white)

                    if entry.isCurrentUser {
                        Text("(você)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                }

                if let badge = entry.badge {
                    HStack(spacing: 4) {
                        Image(systemName: badge.icon)
                            .font(.system(size: 10))
                        Text(badge.title)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.resumed.gold.opacity(0.7))
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedScore)
                    .font(.resumed.h4)
                    .foregroundColor(entry.isCurrentUser ? .resumed.gold : .resumed.white)

                Text(category.unit)
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }
        }
        .padding(Spacing.md)
        .background(highlighted || entry.isCurrentUser ? Color.resumed.gold.opacity(0.1) : Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(entry.isCurrentUser ? Color.resumed.gold.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
