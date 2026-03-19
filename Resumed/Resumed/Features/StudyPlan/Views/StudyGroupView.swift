//
//  StudyGroupView.swift
//  Resumed
//
//  Phase 4 — Social Hub: grupos de estudo + desafios
//

import SwiftUI

// MARK: - Main View

struct StudyGroupView: View {
    @ObservedObject private var service = StudyGroupService.shared
    @State private var selectedTab: GroupTab = .groups
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var showCreateChallenge = false
    @State private var selectedGroupForChallenge: StudyGroup?

    enum GroupTab: String, CaseIterable {
        case groups = "Meus Grupos"
        case challenges = "Desafios"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(GroupTab.allCases, id: \.rawValue) { tab in
                        FilterChip(
                            title: tab.rawValue,
                            isSelected: selectedTab == tab
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                            HapticManager.shared.selection()
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .background(Color.resumed.blackSecondary)

            ScrollView {
                VStack(spacing: Spacing.md) {
                    switch selectedTab {
                    case .groups:
                        groupsContent
                    case .challenges:
                        challengesContent
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
            }
        }
        .background(Color.resumed.black)
        .navigationTitle("Grupos de Estudo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    Button {
                        HapticManager.shared.selection()
                        showJoinGroup = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.resumed.gold)
                    }

                    Button {
                        HapticManager.shared.selection()
                        showCreateGroup = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.resumed.gold)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupSheet()
        }
        .sheet(isPresented: $showJoinGroup) {
            JoinGroupSheet()
        }
        .sheet(item: $selectedGroupForChallenge) { group in
            CreateChallengeSheet(group: group)
        }
    }

    // MARK: - Groups Tab

    private var groupsContent: some View {
        VStack(spacing: Spacing.md) {
            if service.myGroups.isEmpty {
                EmptyGroupsState(
                    onCreate: { showCreateGroup = true },
                    onJoin: { showJoinGroup = true }
                )
            } else {
                ForEach(service.myGroups) { group in
                    GroupCard(
                        group: group,
                        challenges: service.allChallenges(for: group.id),
                        onNewChallenge: {
                            selectedGroupForChallenge = group
                        },
                        onLeave: {
                            withAnimation { service.leaveGroup(id: group.id) }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Challenges Tab

    private var challengesContent: some View {
        VStack(spacing: Spacing.md) {
            let allChallenges = service.myGroups.flatMap { service.allChallenges(for: $0.id) }

            if allChallenges.isEmpty {
                EmptyState(
                    icon: "flame.fill",
                    title: "Nenhum desafio ativo",
                    subtitle: "Crie um grupo e inicie um desafio para competir com amigos.",
                    action: nil,
                    actionTitle: nil
                )
                .padding(.top, Spacing.xl)
            } else {
                ForEach(allChallenges) { challenge in
                    let group = service.myGroups.first(where: { $0.id == challenge.groupId })
                    ChallengLeaderboardCard(challenge: challenge, groupName: group?.name ?? "Grupo")
                }
            }
        }
    }
}

// MARK: - Group Card

private struct GroupCard: View {
    let group: StudyGroup
    let challenges: [GroupChallenge]
    let onNewChallenge: () -> Void
    let onLeave: () -> Void
    @State private var showLeaveAlert = false
    @State private var codeCopied = false
    @State private var showChallenges = false

    private var activeChallenge: GroupChallenge? {
        challenges.first { $0.isActive && !$0.hasEnded }
    }

    var body: some View {
        ResumedCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(group.name)
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.resumed.gray)
                            Text("\(group.memberIds.count) membro\(group.memberIds.count != 1 ? "s" : "")")
                                .font(.resumed.caption)
                                .foregroundColor(.resumed.gray)
                        }
                    }

                    Spacer()

                    // Challenge count badge
                    if !challenges.isEmpty {
                        Text("\(challenges.count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.resumed.black)
                            .frame(width: 20, height: 20)
                            .background(Color.resumed.gold)
                            .clipShape(Circle())
                    }
                }

                // Active challenge preview
                if let challenge = activeChallenge {
                    ActiveChallengePreview(challenge: challenge)
                }

                // Invite code
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.resumed.gray)

                    Text(group.inviteCode)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.resumed.gold)
                        .tracking(3)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = group.inviteCode
                        HapticManager.shared.success()
                        withAnimation { codeCopied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { codeCopied = false }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12))
                            Text(codeCopied ? "Copiado!" : "Copiar")
                                .font(.resumed.caption)
                        }
                        .foregroundColor(codeCopied ? .resumed.success : .resumed.gold)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(codeCopied ? Color.resumed.success.opacity(0.1) : Color.resumed.gold.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                    }
                }
                .padding(Spacing.sm)
                .background(Color.resumed.blackTertiary)
                .cornerRadius(CornerRadius.md)

                // Action buttons
                HStack(spacing: Spacing.sm) {
                    Button {
                        withAnimation { showChallenges.toggle() }
                        HapticManager.shared.selection()
                    } label: {
                        Label("Ver Desafios", systemImage: "flame.fill")
                            .font(.resumed.bodySmall)
                            .foregroundColor(.resumed.gold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.resumed.gold.opacity(0.1))
                            .cornerRadius(CornerRadius.md)
                    }

                    Button {
                        onNewChallenge()
                    } label: {
                        Label("Novo Desafio", systemImage: "plus")
                            .font(.resumed.bodySmall)
                            .foregroundColor(.resumed.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.resumed.blackTertiary)
                            .cornerRadius(CornerRadius.md)
                    }
                }

                // Expanded challenges list
                if showChallenges {
                    if challenges.isEmpty {
                        Text("Nenhum desafio ainda. Crie o primeiro!")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, Spacing.sm)
                    } else {
                        VStack(spacing: Spacing.sm) {
                            ForEach(challenges) { challenge in
                                ChallengeMiniCard(challenge: challenge)
                            }
                        }
                    }
                }
            }
        }
        .alert("Sair do grupo?", isPresented: $showLeaveAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Sair", role: .destructive) { onLeave() }
        } message: {
            Text("Você perderá acesso ao histórico de desafios deste grupo.")
        }
        .contextMenu {
            Button(role: .destructive) {
                showLeaveAlert = true
            } label: {
                Label("Sair do Grupo", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }
}

// MARK: - Active Challenge Preview

private struct ActiveChallengePreview: View {
    let challenge: GroupChallenge

    private var topEntry: ChallengeEntry? {
        challenge.entries.sorted { $0.score > $1.score }.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: challenge.metric.icon)
                    .font(.system(size: 11))
                    .foregroundColor(metricColor)

                Text(challenge.title)
                    .font(.resumed.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(.resumed.white)
                    .lineLimit(1)

                Spacer()

                Text("\(challenge.daysRemaining)d restantes")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(challenge.daysRemaining <= 2 ? .resumed.error : .resumed.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.resumed.blackTertiary)
                    .cornerRadius(CornerRadius.sm)
            }

            if let top = topEntry {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.resumed.gold)
                    Text("\(top.displayName) lidera com \(top.score)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
            }
        }
        .padding(Spacing.sm)
        .background(metricColor.opacity(0.08))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(metricColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var metricColor: Color {
        switch challenge.metric {
        case .xpEarned: return .resumed.gold
        case .questionsAnswered: return .resumed.info
        case .tasksCompleted: return .resumed.success
        case .studyMinutes: return .resumed.warning
        }
    }
}

// MARK: - Challenge Mini Card

private struct ChallengeMiniCard: View {
    let challenge: GroupChallenge

    private var metricColor: Color {
        switch challenge.metric {
        case .xpEarned: return .resumed.gold
        case .questionsAnswered: return .resumed.info
        case .tasksCompleted: return .resumed.success
        case .studyMinutes: return .resumed.warning
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: challenge.metric.icon)
                .font(.system(size: 14))
                .foregroundColor(metricColor)
                .frame(width: 28, height: 28)
                .background(metricColor.opacity(0.12))
                .cornerRadius(CornerRadius.sm)

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.resumed.bodySmall)
                    .foregroundColor(challenge.hasEnded ? .resumed.gray : .resumed.white)
                    .lineLimit(1)
                Text(challenge.metric.rawValue)
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }

            Spacer()

            if challenge.hasEnded {
                Text("Encerrado")
                    .font(.system(size: 10))
                    .foregroundColor(.resumed.gray)
            } else {
                Text("\(challenge.daysRemaining)d")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(metricColor)
            }
        }
        .padding(Spacing.sm)
        .background(Color.resumed.blackTertiary)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Challenge Leaderboard Card

struct ChallengLeaderboardCard: View {
    let challenge: GroupChallenge
    let groupName: String

    private var currentUserId: String {
        SupabaseManager.shared.currentUser?.id ?? "local_user"
    }

    private var sortedEntries: [ChallengeEntry] {
        challenge.entries.sorted { $0.score > $1.score }
    }

    private var metricColor: Color {
        switch challenge.metric {
        case .xpEarned: return .resumed.gold
        case .questionsAnswered: return .resumed.info
        case .tasksCompleted: return .resumed.success
        case .studyMinutes: return .resumed.warning
        }
    }

    var body: some View {
        ResumedCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(metricColor.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: challenge.metric.icon)
                            .font(.system(size: 16))
                            .foregroundColor(metricColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(challenge.title)
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)
                        Text("\(groupName) • \(challenge.metric.rawValue)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }

                    Spacer()

                    if challenge.hasEnded {
                        Text("Encerrado")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.resumed.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.resumed.blackTertiary)
                            .cornerRadius(CornerRadius.round)
                    } else {
                        VStack(spacing: 1) {
                            Text("\(challenge.daysRemaining)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(challenge.daysRemaining <= 2 ? .resumed.error : metricColor)
                            Text("dias")
                                .font(.system(size: 9))
                                .foregroundColor(.resumed.gray)
                        }
                    }
                }

                Divider().background(Color.resumed.border)

                // Leaderboard
                if sortedEntries.isEmpty {
                    Text("Nenhuma pontuação ainda. Seja o primeiro!")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing.sm)
                } else {
                    VStack(spacing: Spacing.xs) {
                        ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                            ChallengeLeaderboardRow(
                                position: index + 1,
                                entry: entry,
                                isCurrentUser: entry.userId == currentUserId,
                                metric: challenge.metric
                            )
                        }
                    }
                }

                // Description
                if !challenge.description.isEmpty {
                    Text(challenge.description)
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                        .padding(.top, Spacing.xs)
                }
            }
        }
    }
}

// MARK: - Leaderboard Row

private struct ChallengeLeaderboardRow: View {
    let position: Int
    let entry: ChallengeEntry
    let isCurrentUser: Bool
    let metric: GroupChallenge.ChallengeMetric

    private var positionColor: Color {
        switch position {
        case 1: return .resumed.gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return .resumed.gray
        }
    }

    private var formattedScore: String {
        switch metric {
        case .studyMinutes:
            if entry.score >= 60 {
                let h = entry.score / 60
                let m = entry.score % 60
                return m > 0 ? "\(h)h \(m)min" : "\(h)h"
            }
            return "\(entry.score) min"
        default:
            return "\(entry.score)"
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Position
            Text(position <= 3 ? medalEmoji(position) : "\(position)")
                .font(.system(size: position <= 3 ? 18 : 13, weight: .bold))
                .foregroundColor(positionColor)
                .frame(width: 28, alignment: .center)

            // Name
            Text(entry.displayName)
                .font(.resumed.body)
                .foregroundColor(isCurrentUser ? .resumed.gold : .resumed.white)
                .fontWeight(isCurrentUser ? .semibold : .regular)
                .lineLimit(1)

            if isCurrentUser {
                Text("(você)")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gold.opacity(0.7))
            }

            Spacer()

            // Score
            HStack(spacing: 4) {
                Image(systemName: metric.icon)
                    .font(.system(size: 11))
                    .foregroundColor(isCurrentUser ? .resumed.gold : .resumed.gray)
                Text(formattedScore)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(isCurrentUser ? .resumed.gold : .resumed.white)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(isCurrentUser ? Color.resumed.gold.opacity(0.07) : Color.clear)
        .cornerRadius(CornerRadius.sm)
        .overlay(
            isCurrentUser
                ? RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(Color.resumed.gold.opacity(0.2), lineWidth: 1)
                : nil
        )
    }

    private func medalEmoji(_ position: Int) -> String {
        switch position {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(position)"
        }
    }
}

// MARK: - Empty Groups State

private struct EmptyGroupsState: View {
    let onCreate: () -> Void
    let onJoin: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: Spacing.xl)

            ZStack {
                Circle()
                    .fill(Color.resumed.gold.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.resumed.gold.opacity(0.6))
            }

            VStack(spacing: Spacing.sm) {
                Text("Sem grupos ainda")
                    .font(.resumed.h4)
                    .foregroundColor(.resumed.white)
                Text("Crie um grupo com colegas ou entre com um código de convite para estudar juntos e disputar desafios.")
                    .font(.resumed.bodySmall)
                    .foregroundColor(.resumed.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            VStack(spacing: Spacing.sm) {
                ResumedButton(
                    title: "Criar Grupo",
                    style: .primary,
                    action: onCreate,
                    icon: "plus.circle.fill",
                    fullWidth: true
                )
                ResumedButton(
                    title: "Entrar com Código",
                    style: .secondary,
                    action: onJoin,
                    icon: "person.badge.plus",
                    fullWidth: true
                )
            }

            Spacer(minLength: Spacing.xl)
        }
    }
}

// MARK: - Create Group Sheet

struct CreateGroupSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var service = StudyGroupService.shared
    @State private var groupName = ""
    @State private var previewCode = StudyGroupService.generateInviteCode()

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.resumed.gold.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.resumed.gold)
                }
                .padding(.top, Spacing.md)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Nome do Grupo")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)

                    TextField("ex: Turma Residência 2026", text: $groupName)
                        .font(.resumed.body)
                        .foregroundColor(.resumed.white)
                        .padding(Spacing.md)
                        .background(Color.resumed.blackSecondary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.resumed.border, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Código de Convite")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)

                    HStack {
                        Text(previewCode)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.resumed.gold)
                            .tracking(4)

                        Spacer()

                        Button {
                            previewCode = StudyGroupService.generateInviteCode()
                            HapticManager.shared.selection()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.resumed.gray)
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.resumed.blackSecondary)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.resumed.border, lineWidth: 1)
                    )

                    Text("Compartilhe este código com colegas para que entrem no grupo.")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }

                Spacer()

                ResumedButton(
                    title: "Criar Grupo",
                    style: .primary,
                    action: {
                        let trimmed = groupName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        var group = service.createGroup(name: trimmed)
                        group.inviteCode = previewCode
                        // Update stored group with the previewed code
                        if let index = service.myGroups.firstIndex(where: { $0.id == group.id }) {
                            service.myGroups[index] = group
                        }
                        dismiss()
                    },
                    icon: "person.3.fill",
                    fullWidth: true
                )
                .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(Spacing.md)
            .background(Color.resumed.black)
            .navigationTitle("Novo Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
        }
    }
}

// MARK: - Join Group Sheet

struct JoinGroupSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var service = StudyGroupService.shared
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.resumed.info.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 28))
                        .foregroundColor(.resumed.info)
                }
                .padding(.top, Spacing.md)

                VStack(spacing: Spacing.sm) {
                    Text("Entrar em um Grupo")
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)
                    Text("Digite o código de 8 caracteres que o dono do grupo compartilhou com você.")
                        .font(.resumed.bodySmall)
                        .foregroundColor(.resumed.gray)
                        .multilineTextAlignment(.center)
                }

                TextField("Ex: ABCD1234", text: $code)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.resumed.white)
                    .multilineTextAlignment(.center)
                    .tracking(4)
                    .textCase(.uppercase)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .padding(Spacing.md)
                    .background(Color.resumed.blackSecondary)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(errorMessage != nil ? Color.resumed.error : Color.resumed.border, lineWidth: 1)
                    )
                    .onChange(of: code) { _, value in
                        errorMessage = nil
                        code = String(value.uppercased().prefix(8))
                    }

                if let error = errorMessage {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error)
                    }
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.error)
                }

                Spacer()

                ResumedButton(
                    title: isLoading ? "Entrando..." : "Entrar no Grupo",
                    style: .primary,
                    action: {
                        joinGroup()
                    },
                    icon: "person.badge.plus",
                    fullWidth: true
                )
                .disabled(code.count < 8 || isLoading)
            }
            .padding(Spacing.md)
            .background(Color.resumed.black)
            .navigationTitle("Entrar em Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
        }
    }

    private func joinGroup() {
        isLoading = true
        // Small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if service.joinGroup(inviteCode: code) != nil {
                HapticManager.shared.success()
                dismiss()
            } else {
                errorMessage = "Código inválido. Verifique e tente novamente."
                HapticManager.shared.notification(.error)
            }
            isLoading = false
        }
    }
}

// MARK: - Create Challenge Sheet

struct CreateChallengeSheet: View {
    let group: StudyGroup
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var service = StudyGroupService.shared

    @State private var title = ""
    @State private var description = ""
    @State private var selectedMetric: GroupChallenge.ChallengeMetric = .studyMinutes
    @State private var selectedDuration = 7

    private let durationOptions = [3, 7, 14, 30]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color.resumed.warning.opacity(0.12))
                                .frame(width: 64, height: 64)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.resumed.warning)
                        }

                        Text("Criar Desafio")
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)

                        Text("Grupo: \(group.name)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                    .padding(.top, Spacing.md)

                    // Title
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Título do Desafio")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        TextField("ex: Maratona de Questões", text: $title)
                            .font(.resumed.body)
                            .foregroundColor(.resumed.white)
                            .padding(Spacing.md)
                            .background(Color.resumed.blackSecondary)
                            .cornerRadius(CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(Color.resumed.border, lineWidth: 1)
                            )
                    }

                    // Description
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Descrição (opcional)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        TextField("Descreva o desafio...", text: $description, axis: .vertical)
                            .font(.resumed.bodySmall)
                            .foregroundColor(.resumed.white)
                            .lineLimit(3, reservesSpace: true)
                            .padding(Spacing.md)
                            .background(Color.resumed.blackSecondary)
                            .cornerRadius(CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(Color.resumed.border, lineWidth: 1)
                            )
                    }

                    // Metric
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Métrica de Pontuação")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                            ForEach(GroupChallenge.ChallengeMetric.allCases, id: \.rawValue) { metric in
                                MetricOptionButton(
                                    metric: metric,
                                    isSelected: selectedMetric == metric
                                ) {
                                    selectedMetric = metric
                                    HapticManager.shared.selection()
                                }
                            }
                        }
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Duração")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        HStack(spacing: Spacing.sm) {
                            ForEach(durationOptions, id: \.self) { days in
                                Button {
                                    selectedDuration = days
                                    HapticManager.shared.selection()
                                } label: {
                                    VStack(spacing: 2) {
                                        Text("\(days)")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                        Text(days == 1 ? "dia" : "dias")
                                            .font(.system(size: 11))
                                    }
                                    .foregroundColor(selectedDuration == days ? .resumed.black : .resumed.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.sm)
                                    .background(selectedDuration == days ? Color.resumed.gold : Color.resumed.blackSecondary)
                                    .cornerRadius(CornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .stroke(selectedDuration == days ? Color.resumed.gold : Color.resumed.border, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    Spacer(minLength: Spacing.lg)

                    ResumedButton(
                        title: "Criar Desafio",
                        style: .primary,
                        action: {
                            let trimmed = title.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            service.createChallenge(
                                groupId: group.id,
                                title: trimmed,
                                description: description.trimmingCharacters(in: .whitespaces),
                                metric: selectedMetric,
                                durationDays: selectedDuration
                            )
                            dismiss()
                        },
                        icon: "flame.fill",
                        fullWidth: true
                    )
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.bottom, Spacing.md)
                }
                .padding(.horizontal, Spacing.md)
            }
            .background(Color.resumed.black)
            .navigationTitle("Novo Desafio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
        }
    }
}

// MARK: - Metric Option Button

private struct MetricOptionButton: View {
    let metric: GroupChallenge.ChallengeMetric
    let isSelected: Bool
    let action: () -> Void

    private var accentColor: Color {
        switch metric {
        case .xpEarned: return .resumed.gold
        case .questionsAnswered: return .resumed.info
        case .tasksCompleted: return .resumed.success
        case .studyMinutes: return .resumed.warning
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: metric.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? accentColor : .resumed.gray)

                Text(metric.rawValue)
                    .font(.resumed.bodySmall)
                    .foregroundColor(isSelected ? .resumed.white : .resumed.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(Spacing.sm)
            .background(isSelected ? accentColor.opacity(0.1) : Color.resumed.blackSecondary)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? accentColor.opacity(0.4) : Color.resumed.border, lineWidth: 1)
            )
        }
    }
}
