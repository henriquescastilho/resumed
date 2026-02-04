//
//  ResuCardsView.swift
//  Resumed
//
//  ResuCards View - Flashcards with SM-2
//

import SwiftUI
import Combine

struct ResuCardsView: View {
    @StateObject private var viewModel = ResuCardsViewModel()

    var body: some View {
        ZStack {
            Color.resumed.black.ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                Picker("Modo", selection: $viewModel.mode) {
                    Text("Revisar").tag(ResuCardsViewModel.Mode.review)
                    Text("Meus Cards").tag(ResuCardsViewModel.Mode.myCards)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                Group {
                    switch viewModel.mode {
                    case .review:
                        switch viewModel.state {
                        case .loading:
                            LoadingView(message: "Carregando cards...")

                        case .empty:
                            EmptyState(
                                icon: "rectangle.stack",
                                title: "Nenhum card para revisar",
                                subtitle: "Crie seus próprios cards para começar a revisar.",
                                action: { viewModel.showCreateCard = true },
                                actionTitle: "Criar Card"
                            )

                        case .reviewing:
                            ReviewingContent(viewModel: viewModel)

                        case .completed:
                            SuccessState(
                                title: "Parabéns!",
                                subtitle: "Você revisou \(viewModel.cardsReviewed) cards!",
                                xpEarned: viewModel.xpEarned,
                                action: { viewModel.restart() },
                                actionTitle: "Revisar novamente"
                            )
                        }
                    case .myCards:
                        MyCardsList(
                            cards: viewModel.myCards,
                            onCreate: { viewModel.showCreateCard = true }
                        )
                    }
                }
            }
        }
        .navigationTitle("ResuCard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showCreateCard = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.resumed.gold)
                }
            }
        }
        .task {
            await viewModel.loadCards()
        }
        .sheet(isPresented: $viewModel.showCreateCard) {
            CreateCardSheet(viewModel: viewModel)
        }
    }
}

@MainActor
class ResuCardsViewModel: ObservableObject {
    enum State { case loading, empty, reviewing, completed }
    enum Mode { case review, myCards }

    @Published var state: State = .loading
    @Published var mode: Mode = .review
    @Published var cards: [FlashCard] = []
    @Published var myCards: [FlashCard] = []
    @Published var currentIndex = 0
    @Published var isFlipped = false
    @Published var cardsReviewed = 0
    @Published var xpEarned = 0
    @Published var showCreateCard = false
    @Published var errorMessage: String?

    private let coreData = CoreDataManager.shared
    private let userTag = "user"

    var currentCard: FlashCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    func loadCards() async {
        state = .loading
        loadMyCards()

        do {
            let dueLocal = coreData.fetchDueFlashCards()
            if !dueLocal.isEmpty {
                cards = dueLocal
            } else if APIClient.mode == .mock {
                cards = []
            } else {
                let response = try await APIClient.shared.getFlashCardsDue()
                cards = response.flashcards.map { $0.toFlashCard() }
                cards.forEach { coreData.saveOrUpdateFlashCard($0) }
            }
        } catch {
            cards = []
        }

        state = cards.isEmpty ? .empty : .reviewing
    }

    func flipCard() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isFlipped.toggle()
        }
        HapticManager.shared.impact(.medium)
    }

    func rateCard(_ quality: SM2Algorithm.Quality) async {
        guard var card = currentCard else { return }

        SM2Algorithm.applyReview(to: &card, quality: quality)
        cards[currentIndex] = card
        coreData.saveOrUpdateFlashCard(card)
        loadMyCards()
        xpEarned += quality.xpReward
        cardsReviewed += 1

        if cardsReviewed >= cards.count {
            withAnimation { state = .completed }
            HapticManager.shared.celebration()
        } else {
            isFlipped = false
            currentIndex += 1
            HapticManager.shared.selection()
        }
    }

    func restart() {
        currentIndex = 0
        cardsReviewed = 0
        xpEarned = 0
        isFlipped = false
        state = .reviewing
    }

    func createCard(front: String, back: String, subject: String) {
        let newCard = FlashCard(front: front, back: back, subject: subject, tags: [userTag])
        coreData.saveFlashCard(newCard)
        loadMyCards()

        if state == .empty {
            cards = [newCard]
            state = .reviewing
        }
    }

    private func loadMyCards() {
        myCards = coreData.fetchFlashCards()
            .filter { $0.tags.contains(userTag) }
    }
}

struct ReviewingContent: View {
    @ObservedObject var viewModel: ResuCardsViewModel

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Progress
            VStack(spacing: Spacing.sm) {
                ProgressBar(current: viewModel.cardsReviewed, total: viewModel.cards.count, showLabel: false)

                HStack {
                    Text("Card \(viewModel.cardsReviewed + 1) de \(viewModel.cards.count)")
                        .font(.resumed.bodySmall)
                        .foregroundColor(.resumed.gray)
                    Spacer()
                    XPBadge(xp: viewModel.xpEarned)
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            // Card
            if let card = viewModel.currentCard {
                FlashCardView(card: card, isFlipped: viewModel.isFlipped) {
                    viewModel.flipCard()
                }
                .padding(.horizontal, Spacing.md)
            }

            Spacer()

            // Rating buttons
            if viewModel.isFlipped {
                VStack(spacing: Spacing.sm) {
                    Text("Como você foi?")
                        .font(.resumed.body)
                        .foregroundColor(.resumed.gray)

                    HStack(spacing: Spacing.sm) {
                        ForEach(SM2Algorithm.Quality.allCases, id: \.rawValue) { quality in
                            RatingButton(quality: quality) {
                                Task { await viewModel.rateCard(quality) }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
            } else {
                Text("Toque para ver a resposta")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
                    .padding(.bottom, Spacing.lg)
            }
        }
        .padding(.top, Spacing.md)
    }
}

struct FlashCardView: View {
    let card: FlashCard
    let isFlipped: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            CardFace(content: card.front, subject: card.subject, isQuestion: true)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            CardFace(content: card.back, subject: card.subject, isQuestion: false)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 350)
        .onTapGesture(perform: onTap)
    }
}

struct CardFace: View {
    let content: String
    let subject: String
    let isQuestion: Bool

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text(subject)
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gold)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.resumed.gold.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)

                Spacer()

                Image(systemName: isQuestion ? "questionmark.circle" : "lightbulb.fill")
                    .foregroundColor(.resumed.gold)
            }

            Spacer()

            ScrollView {
                Text(content)
                    .font(isQuestion ? .resumed.h3 : .resumed.body)
                    .foregroundColor(.resumed.white)
                    .multilineTextAlignment(isQuestion ? .center : .leading)
            }

            Spacer()

            if isQuestion {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "hand.tap")
                    Text("Toque para ver resposta")
                }
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.xl)
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

struct CreateCardSheet: View {
    @ObservedObject var viewModel: ResuCardsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var front = ""
    @State private var back = ""
    @State private var subject = "Clínica Médica"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Frente")
                            .font(.resumed.body)
                            .foregroundColor(.resumed.gray)
                        ResumedTextArea(placeholder: "Pergunta...", text: $front, minHeight: 100)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Verso")
                            .font(.resumed.body)
                            .foregroundColor(.resumed.gray)
                        ResumedTextArea(placeholder: "Resposta...", text: $back, minHeight: 150)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.resumed.black)
            .navigationTitle("Novo ResuCard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        viewModel.createCard(front: front, back: back, subject: subject)
                        dismiss()
                    }
                        .foregroundColor(.resumed.gold)
                        .disabled(front.isEmpty || back.isEmpty)
                }
            }
        }
    }
}

private struct MyCardsList: View {
    let cards: [FlashCard]
    let onCreate: () -> Void

    var body: some View {
        if cards.isEmpty {
            EmptyState(
                icon: "rectangle.stack",
                title: "Sem cards salvos",
                subtitle: "Crie seus próprios cards para montar seu acervo.",
                action: onCreate,
                actionTitle: "Criar Card"
            )
        } else {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(cards) { card in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text(card.subject)
                                    .font(.resumed.caption)
                                    .foregroundColor(.resumed.gold)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(Color.resumed.gold.opacity(0.12))
                                    .cornerRadius(CornerRadius.sm)
                                Spacer()
                                Text(nextReviewLabel(for: card))
                                    .font(.resumed.caption)
                                    .foregroundColor(.resumed.gray)
                            }

                            Text(card.front)
                                .font(.resumed.body)
                                .foregroundColor(.resumed.white)
                                .lineLimit(3)

                            Text(card.back)
                                .font(.resumed.bodySmall)
                                .foregroundColor(.resumed.gray)
                                .lineLimit(2)
                        }
                        .padding(Spacing.md)
                        .background(Color.resumed.blackSecondary)
                        .cornerRadius(CornerRadius.md)
                    }
                }
                .padding(Spacing.md)
            }
        }
    }

    private func nextReviewLabel(for card: FlashCard) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: card.nextReviewDate).day ?? 0
        if days <= 0 {
            return "Revisar hoje"
        }
        return "Revisar em \(days)d"
    }
}
