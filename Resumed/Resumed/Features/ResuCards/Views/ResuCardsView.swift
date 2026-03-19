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

                ResuCardFilterBar(
                    selectedSubject: $viewModel.selectedSubject,
                    subjects: viewModel.subjects
                )
                .padding(.horizontal, Spacing.md)

                if viewModel.mode == .review {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ReviewPackCard(
                                title: "Essencial ENAMED",
                                cardCount: viewModel.essentialPackCount,
                                icon: "star.fill",
                                color: .resumed.gold,
                                isSelected: viewModel.selectedPack == .essential,
                                action: { viewModel.selectPack(.essential) }
                            )

                            ReviewPackCard(
                                title: "Revisao Rapida",
                                cardCount: viewModel.quickReviewPackCount,
                                icon: "bolt.fill",
                                color: .resumed.info,
                                isSelected: viewModel.selectedPack == .quickReview,
                                action: { viewModel.selectPack(.quickReview) }
                            )

                            ReviewPackCard(
                                title: "Todos os Cards",
                                cardCount: viewModel.allCardsCount,
                                icon: "rectangle.stack.fill",
                                color: .resumed.gray,
                                isSelected: viewModel.selectedPack == nil,
                                action: { viewModel.selectPack(nil) }
                            )
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }

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
                            cards: viewModel.filteredMyCards,
                            onCreate: { viewModel.showCreateCard = true },
                            onEdit: { viewModel.startEdit(card: $0) }
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
        .sheet(isPresented: $viewModel.showEditCard) {
            if let card = viewModel.editingCard {
                EditCardSheet(viewModel: viewModel, card: card)
            }
        }
    }
}

@MainActor
class ResuCardsViewModel: ObservableObject {
    enum State { case loading, empty, reviewing, completed }
    enum Mode { case review, myCards }
    enum ReviewPack {
        case essential
        case quickReview
    }

    @Published var state: State = .loading
    @Published var mode: Mode = .review
    @Published var cards: [FlashCard] = []
    @Published var myCards: [FlashCard] = []
    @Published var selectedSubject: String = "Todas"
    @Published var currentIndex = 0
    @Published var isFlipped = false
    @Published var cardsReviewed = 0
    @Published var xpEarned = 0
    @Published var showCreateCard = false
    @Published var showEditCard = false
    @Published var editingCard: FlashCard?
    @Published var errorMessage: String?
    @Published var selectedPack: ReviewPack? = nil

    private var allCards: [FlashCard] = []

    private let coreData = CoreDataManager.shared
    private let userTag = "user"
    private let defaultSubjects = [
        "Clínica Médica",
        "Cirurgia Geral",
        "Pediatria",
        "Ginecologia e Obstetrícia",
        "Medicina Preventiva",
        "Psiquiatria"
    ]

    var essentialPackCount: Int {
        let essentialSubjects = ["Clínica Médica", "Cirurgia Geral", "Pediatria", "Ginecologia e Obstetrícia"]
        return allCards.filter { essentialSubjects.contains($0.subject) }.prefix(20).count
    }

    var quickReviewPackCount: Int {
        min(10, allCards.count)
    }

    var allCardsCount: Int {
        allCards.count
    }

    func selectPack(_ pack: ReviewPack?) {
        selectedPack = pack
        filterCardsByPack()
    }

    private func filterCardsByPack() {
        switch selectedPack {
        case .essential:
            let essentialSubjects = ["Clínica Médica", "Cirurgia Geral", "Pediatria", "Ginecologia e Obstetrícia"]
            var filtered = allCards.filter { essentialSubjects.contains($0.subject) }
            if filtered.count > 20 { filtered = Array(filtered.prefix(20)) }
            cards = filtered
        case .quickReview:
            let snapshot = ProgressTracker.shared.snapshot()
            let worstSubjects = snapshot.subjectStats
                .sorted { $0.value.accuracy < $1.value.accuracy }
                .prefix(3)
                .map { $0.key }
            var filtered = allCards.filter { worstSubjects.contains($0.subject) }
            if filtered.count > 10 { filtered = Array(filtered.prefix(10)) }
            cards = filtered
        case nil:
            cards = allCards
        }
        currentIndex = 0
        isFlipped = false
        state = cards.isEmpty ? .empty : .reviewing
    }

    var subjects: [String] {
        let availableSubjects = Set((cards + myCards).map(\.subject).filter { !$0.isEmpty })
        let mergedSubjects = availableSubjects.union(defaultSubjects)
        return ["Todas"] + mergedSubjects.sorted()
    }

    var currentCard: FlashCard? {
        guard currentIndex < filteredCards.count else { return nil }
        return filteredCards[currentIndex]
    }

    var filteredCards: [FlashCard] {
        if selectedSubject == "Todas" { return cards }
        return cards.filter { $0.subject == selectedSubject }
    }

    var filteredMyCards: [FlashCard] {
        if selectedSubject == "Todas" { return myCards }
        return myCards.filter { $0.subject == selectedSubject }
    }

    func loadCards() async {
        state = .loading
        loadMyCards()

        do {
            let dueLocal = coreData.fetchDueFlashCards()
            if !dueLocal.isEmpty {
                cards = dueLocal.shuffled()
            } else if APIClient.mode == .mock {
                let response = try await MockAPIClient.shared.getFlashCardsDue()
                let loadedCards = response.flashcards.map { $0.toFlashCard() }
                cards = loadedCards.shuffled()
                loadedCards.forEach { coreData.saveOrUpdateFlashCard($0) }
            } else {
                let response = try await APIClient.shared.getFlashCardsDue()
                cards = response.flashcards.map { $0.toFlashCard() }.shuffled()
                cards.forEach { coreData.saveOrUpdateFlashCard($0) }
            }
        } catch {
            cards = []
        }

        loadMyCards()

        // Store the full unfiltered set for pack filtering
        allCards = cards

        state = filteredCards.isEmpty ? .empty : .reviewing
        currentIndex = 0
        if state == .reviewing {
            cardsReviewed = 0
        }
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
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        }
        coreData.saveOrUpdateFlashCard(card)
        loadMyCards()
        xpEarned += quality.xpReward
        cardsReviewed += 1

        if cardsReviewed >= filteredCards.count {
            withAnimation { state = .completed }
            HapticManager.shared.celebration()
        } else {
            isFlipped = false
            currentIndex = min(currentIndex + 1, max(filteredCards.count - 1, 0))
            HapticManager.shared.selection()
        }
    }

    func restart() {
        currentIndex = 0
        cardsReviewed = 0
        xpEarned = 0
        isFlipped = false
        cards.shuffle()
        state = filteredCards.isEmpty ? .empty : .reviewing
    }

    func goToNext() {
        guard !filteredCards.isEmpty else { return }
        isFlipped = false
        currentIndex = min(currentIndex + 1, filteredCards.count - 1)
        HapticManager.shared.selection()
    }

    func goToPrevious() {
        guard !filteredCards.isEmpty else { return }
        isFlipped = false
        currentIndex = max(currentIndex - 1, 0)
        HapticManager.shared.selection()
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

    func startEdit(card: FlashCard) {
        editingCard = card
        showEditCard = true
    }

    func updateCard(_ card: FlashCard, front: String, back: String, subject: String) {
        var updated = card
        updated.front = front
        updated.back = back
        updated.subject = subject
        coreData.saveOrUpdateFlashCard(updated)
        loadMyCards()
        if let index = cards.firstIndex(where: { $0.id == updated.id }) {
            cards[index] = updated
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
                ProgressBar(current: viewModel.cardsReviewed, total: max(viewModel.filteredCards.count, 1), showLabel: false)

                HStack {
                    Text("Card \(viewModel.cardsReviewed + 1) de \(viewModel.filteredCards.count)")
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
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            if value.translation.width < -40 {
                                viewModel.goToNext()
                            } else if value.translation.width > 40 {
                                viewModel.goToPrevious()
                            }
                        }
                )
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
                .padding(.bottom, Layout.tabBarHeight + Spacing.md)
            } else {
                Text("Toque para ver a resposta")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
                    .padding(.bottom, Layout.tabBarHeight + Spacing.md)
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

    private func markdownString(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

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
                Text(markdownString(content))
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
    private var subjects: [String] { viewModel.subjects.filter { $0 != "Todas" } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Categoria")
                            .font(.resumed.body)
                            .foregroundColor(.resumed.gray)

                        Picker("Categoria", selection: $subject) {
                            ForEach(subjects, id: \.self) { item in
                                Text(item).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                        .background(Color.resumed.blackSecondary)
                        .cornerRadius(CornerRadius.md)
                    }

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

private struct EditCardSheet: View {
    @ObservedObject var viewModel: ResuCardsViewModel
    let card: FlashCard
    @Environment(\.dismiss) var dismiss
    @State private var front: String
    @State private var back: String
    @State private var subject: String
    private var subjects: [String]

    init(viewModel: ResuCardsViewModel, card: FlashCard) {
        self.viewModel = viewModel
        self.card = card
        _front = State(initialValue: card.front)
        _back = State(initialValue: card.back)
        _subject = State(initialValue: card.subject)
        self.subjects = viewModel.subjects.filter { $0 != "Todas" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Categoria")
                            .font(.resumed.body)
                            .foregroundColor(.resumed.gray)

                        Picker("Categoria", selection: $subject) {
                            ForEach(subjects, id: \.self) { item in
                                Text(item).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                        .background(Color.resumed.blackSecondary)
                        .cornerRadius(CornerRadius.md)
                    }

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
            .navigationTitle("Editar ResuCard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        viewModel.updateCard(card, front: front, back: back, subject: subject)
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
    let onEdit: (FlashCard) -> Void

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

                            HStack {
                                Spacer()
                                IconButton(icon: "pencil", action: { onEdit(card) }, size: 36, color: .resumed.gold)
                            }
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

private struct ReviewPackCard: View {
    let title: String
    let cardCount: Int
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticManager.shared.selection()
        }) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    Text("\(cardCount)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? color : .resumed.white)
                }
                Text(title)
                    .font(.resumed.caption)
                    .foregroundColor(isSelected ? .resumed.white : .resumed.gray)
                    .lineLimit(1)
            }
            .padding(Spacing.sm)
            .frame(width: 130)
            .background(isSelected ? color.opacity(0.15) : Color.resumed.blackSecondary)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? color.opacity(0.4) : Color.resumed.border, lineWidth: 1)
            )
        }
    }
}

private struct ResuCardFilterBar: View {
    @Binding var selectedSubject: String
    let subjects: [String]

    var body: some View {
        HStack {
            Text("Categoria")
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)

            Spacer()

            Menu {
                ForEach(subjects, id: \.self) { subject in
                    Button(subject) { selectedSubject = subject }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedSubject)
                        .font(.resumed.bodySmall)
                        .foregroundColor(.resumed.white)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.resumed.gold)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.resumed.blackSecondary)
                .cornerRadius(CornerRadius.round)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.round)
                        .stroke(Color.resumed.border, lineWidth: 1)
                )
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
