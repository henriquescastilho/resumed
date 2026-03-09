//
//  GreyView.swift
//  Resumed
//
//  Grey AI Chat View
//

import SwiftUI
import Combine

struct GreyView: View {
    @StateObject private var viewModel = GreyViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isTyping {
                            TypingIndicator()
                        }
                    }
                    .padding(Spacing.md)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
            }

            // Daily limit banner
            GreyLimitBanner(
                remaining: viewModel.remainingInteractions,
                isLimitReached: viewModel.isLimitReached,
                onSave: { viewModel.saveDraftIfNeeded() },
                canSave: viewModel.canSaveDraft
            )

            // Suggestions
            if !viewModel.suggestedQuestions.isEmpty && viewModel.messages.count <= 1 {
                SuggestionsBar(suggestions: viewModel.suggestedQuestions) { suggestion in
                    viewModel.inputText = suggestion
                    Task { await viewModel.sendMessage() }
                }
            }

            // Input
            ChatInputBar(
                text: $viewModel.inputText,
                onSend: { Task { await viewModel.sendMessage() } },
                isLoading: viewModel.isTyping,
                isDisabled: viewModel.isLimitReached
            )
            .padding(.bottom, Layout.tabBarHeight)
        }
        .background(Color.resumed.black)
        .navigationTitle("Grey")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
class GreyViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isTyping = false
    @Published var suggestedQuestions: [String] = []
    @Published private(set) var remainingInteractions = GreyLimit.maxDailyInteractions

    private var isSameDayKey = "grey_last_interaction_date"
    private var interactionCountKey = "grey_interaction_count"
    private var savedDraftsKey = "grey_saved_drafts"

    init() {
        resetIfNewDay()
        messages = [
            ChatMessage(id: UUID().uuidString, role: .assistant, content: "Oi! Sou a Grey. Tiro dúvidas médicas e explico conteúdos do ENAMED.", timestamp: Date())
        ]
        suggestedQuestions = ["Explique fibrilação atrial", "Como manejar hiponatremia (SIADH)?", "Diferença entre dor mecânica e inflamatória?"]
    }

    var isLimitReached: Bool {
        remainingInteractions <= 0
    }

    var canSaveDraft: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func sendMessage() async {
        resetIfNewDay()
        guard !isLimitReached else { return }

        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        if isOffTopic(userMessage) {
            messages.append(ChatMessage(id: UUID().uuidString, role: .assistant, content: "Eu sou focada em dúvidas médicas. Me envie uma dúvida sobre conteúdos do ENAMED.", timestamp: Date()))
            inputText = ""
            HapticManager.shared.notification(.warning)
            return
        }

        incrementInteractions()
        messages.append(ChatMessage(id: UUID().uuidString, role: .user, content: userMessage, timestamp: Date()))
        inputText = ""
        isTyping = true
        suggestedQuestions = []

        try? await Task.sleep(nanoseconds: 1_500_000_000)

        let response = "Boa pergunta! Posso explicar o tema e resolver dúvidas objetivas. Se quiser, me diga:\n1. **Tema específico**\n2. **O que você já entende**\n3. **Onde travou**"

        messages.append(ChatMessage(id: UUID().uuidString, role: .assistant, content: response, timestamp: Date()))
        isTyping = false
        HapticManager.shared.notification(.success)
    }

    func saveDraftIfNeeded() {
        let draft = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !draft.isEmpty else { return }
        var saved = UserDefaults.standard.stringArray(forKey: savedDraftsKey) ?? []
        saved.append(draft)
        UserDefaults.standard.set(saved, forKey: savedDraftsKey)
        inputText = ""
        HapticManager.shared.selection()
    }

    private func resetIfNewDay() {
        let today = Self.dayKey(from: Date())
        let lastDay = UserDefaults.standard.string(forKey: isSameDayKey)
        if lastDay != today {
            UserDefaults.standard.set(today, forKey: isSameDayKey)
            UserDefaults.standard.set(0, forKey: interactionCountKey)
        }
        updateRemaining()
    }

    private func incrementInteractions() {
        let current = UserDefaults.standard.integer(forKey: interactionCountKey)
        UserDefaults.standard.set(current + 1, forKey: interactionCountKey)
        updateRemaining()
    }

    private func updateRemaining() {
        let current = UserDefaults.standard.integer(forKey: interactionCountKey)
        remainingInteractions = max(GreyLimit.maxDailyInteractions - current, 0)
    }

    private func isOffTopic(_ message: String) -> Bool {
        let text = message.lowercased()
        let allowedKeywords = [
            "medicina", "clinica", "clínica", "cirurgia", "pediatria", "gineco", "obst", "obstetricia",
            "saude", "saúde", "mental", "mfc", "coletiva", "enamed", "revalida", "sus",
            "diagnostico", "diagnóstico", "tratamento", "sintoma", "sinais", "conduta", "protocolos",
            "hipertens", "diabetes", "dengue", "tuberculose", "sifilis", "sífilis", "cad", "arritmia"
        ]

        let blockedKeywords = [
            "agenda", "semana", "cronograma", "plano", "organizar", "prioridade", "priorizar",
            "minha vida", "pessoal", "finanças", "trabalho", "namoro", "relacionamento"
        ]

        if blockedKeywords.contains(where: { text.contains($0) }) {
            return true
        }
        return !allowedKeywords.contains(where: { text.contains($0) })
    }

    private static func dayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date

    enum MessageRole {
        case user, assistant
        var isUser: Bool { self == .user }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.role.isUser ? .trailing : .leading, spacing: Spacing.xs) {
                if !message.role.isUser {
                    Text("Grey")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gold)
                }

                Text(message.content)
                    .font(.resumed.body)
                    .foregroundColor(message.role.isUser ? .resumed.black : .resumed.white)
                    .padding(Spacing.md)
                    .background(message.role.isUser ? Color.resumed.gold : Color.resumed.blackSecondary)
                    .cornerRadius(CornerRadius.lg)

                Text(message.timestamp, style: .time)
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }

            if !message.role.isUser { Spacer(minLength: 60) }
        }
    }
}

struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Grey")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gold)

                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.resumed.gray)
                            .frame(width: 8, height: 8)
                            .offset(y: animate ? -4 : 4)
                            .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.15), value: animate)
                    }
                }
                .padding(Spacing.md)
                .background(Color.resumed.blackSecondary)
                .cornerRadius(CornerRadius.lg)
            }
            Spacer()
        }
        .onAppear { animate = true }
    }
}

struct SuggestionsBar: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button { onSelect(suggestion) } label: {
                        Text(suggestion)
                            .font(.resumed.bodySmall)
                            .foregroundColor(.resumed.white)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.resumed.blackSecondary)
                            .cornerRadius(CornerRadius.round)
                            .overlay(RoundedRectangle(cornerRadius: CornerRadius.round).stroke(Color.resumed.border))
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }
}

// MARK: - Daily Limit Banner

enum GreyLimit {
    static let maxDailyInteractions = 5
}

struct GreyLimitBanner: View {
    let remaining: Int
    let isLimitReached: Bool
    let onSave: () -> Void
    let canSave: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.resumed.gold)
                Text("Interações de hoje: \(GreyLimit.maxDailyInteractions - remaining)/\(GreyLimit.maxDailyInteractions)")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
                Spacer()
                if remaining > 0 {
                    Text("Restam \(remaining)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
            }

            if isLimitReached {
                HStack {
                    Text("Limite diário atingido. Volte amanhã ou salve sua dúvida.")
                        .font(.resumed.bodySmall)
                        .foregroundColor(.resumed.white)
                    Spacer()
                }
                ResumedButton(
                    title: "Salvar dúvida para amanhã",
                    style: .ghost,
                    action: onSave,
                    isDisabled: !canSave
                )
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.resumed.blackSecondary)
    }
}
