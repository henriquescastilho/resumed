//
//  EndlessQuestionsView.swift
//  Resumed
//
//  "Treinar até Morrer" — infinite question practice mode
//

import SwiftUI

struct EndlessQuestionsView: View {
    var subjectFilter: String? = nil

    @StateObject private var session = QuestionSessionManager()
    @Environment(\.dismiss) var dismiss

    @State private var totalAnswered = 0
    @State private var totalCorrect = 0
    @State private var currentStreak = 0
    @State private var bestStreak = 0
    @State private var seenIds: Set<String> = []
    @State private var showSummary = false
    @State private var showQuitAlert = false
    @State private var greyContext = ""
    @State private var showGreySheet = false

    private var accuracy: Double {
        totalAnswered > 0 ? Double(totalCorrect) / Double(totalAnswered) * 100 : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Running stats bar
            HStack(spacing: 0) {
                endlessStat(value: "\(totalAnswered)", label: "Respondidas", icon: "doc.text.fill")
                endlessStat(value: "\(Int(accuracy))%", label: "Acurácia", icon: "chart.bar.fill")
                endlessStat(value: "\(currentStreak)", label: "Streak", icon: "flame.fill")
                endlessStat(value: "\(bestStreak)", label: "Melhor", icon: "trophy.fill")
            }
            .padding(.vertical, Spacing.sm)
            .background(Color.resumed.blackSecondary)

            if session.isLoading {
                Spacer()
                ProgressView()
                    .tint(.resumed.gold)
                Text("Carregando questões...")
                    .font(.resumed.bodySmall)
                    .foregroundColor(.resumed.gray)
                    .padding(.top, Spacing.sm)
                Spacer()
            } else if session.questions.isEmpty {
                Spacer()
                EmptyState(
                    icon: "checkmark.seal.fill",
                    title: "Acabaram as questões!",
                    subtitle: "Você respondeu todas as \(totalAnswered) questões disponíveis."
                )
                Spacer()
            } else if let question = session.currentQuestion {
                HStack {
                    Text("Questão \(session.currentIndex + 1) de \(session.questions.count)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                    Spacer()
                    XPBadge(xp: session.xpEarned)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        QuestionCard(
                            question: question,
                            selectedOptionId: session.selectedOptionId,
                            isAnswered: session.isAnswered,
                            onSelect: session.selectOption
                        )

                        if session.isAnswered {
                            FeedbackCard(
                                isCorrect: session.isCorrect,
                                explanation: session.explanation,
                                socialMessage: session.socialMessage
                            )

                            if !session.isCorrect {
                                Button(action: askGreyAboutQuestion) {
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "brain.head.profile")
                                        Text("Perguntar à Grey")
                                            .font(.resumed.bodySmall)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.resumed.gold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.sm)
                                    .background(Color.resumed.gold.opacity(0.1))
                                    .cornerRadius(CornerRadius.md)
                                }
                            }
                        }
                    }
                    .padding(Spacing.md)
                }

                // Bottom action button
                HStack {
                    if session.isAnswered {
                        ResumedButton(
                            title: "Próxima",
                            style: .primary,
                            action: handleNext,
                            icon: "arrow.right",
                            fullWidth: true
                        )
                    } else {
                        ResumedButton(
                            title: "Confirmar",
                            style: .primary,
                            action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    session.confirmAnswer()
                                    totalAnswered += 1
                                    if session.isCorrect {
                                        totalCorrect += 1
                                        currentStreak += 1
                                        bestStreak = max(bestStreak, currentStreak)
                                    } else {
                                        currentStreak = 0
                                    }
                                }
                            },
                            isDisabled: session.selectedOptionId == nil,
                            fullWidth: true
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.md)
            }
        }
        .background(Color.resumed.black)
        .navigationTitle("Treinar até Morrer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Parar") {
                    if totalAnswered > 0 {
                        showQuitAlert = true
                    } else {
                        dismiss()
                    }
                }
                .foregroundColor(.resumed.error)
            }
        }
        .alert("Parar treino?", isPresented: $showQuitAlert) {
            Button("Continuar", role: .cancel) {}
            Button("Ver Resultado", role: .destructive) {
                showSummary = true
            }
        } message: {
            Text("Você respondeu \(totalAnswered) questões com \(Int(accuracy))% de acurácia.")
        }
        .fullScreenCover(isPresented: $showSummary) {
            EndlessSummaryView(
                totalAnswered: totalAnswered,
                totalCorrect: totalCorrect,
                bestStreak: bestStreak,
                accuracy: accuracy,
                onDismiss: { dismiss() }
            )
        }
        .sheet(isPresented: $showGreySheet) {
            NavigationStack {
                GreyView(initialContext: greyContext)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Fechar") { showGreySheet = false }
                                .foregroundColor(.resumed.gray)
                        }
                    }
            }
        }
        .overlay(alignment: .bottom) {
            if session.showAutoCardToast {
                EndlessAutoCardToast()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { session.showAutoCardToast = false }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: session.showAutoCardToast)
        .task {
            loadNextBatch()
        }
    }

    // MARK: - Logic

    private func askGreyAboutQuestion() {
        guard let q = session.currentQuestion else { return }
        let selectedText = q.options.first(where: { $0.id == session.selectedOptionId })?.text ?? ""
        let correctText = q.options.first(where: { $0.id == q.correctOptionId })?.text ?? ""
        greyContext = "Questão: \(q.statement)\nMinha resposta: \(selectedText)\nResposta correta: \(correctText)\nExplicação: \(q.explanation)\n\nMe explique por que a resposta correta é essa e por que a minha está errada."
        showGreySheet = true
    }

    private func handleNext() {
        if session.currentIndex + 1 < session.questions.count {
            session.nextQuestion()
        } else {
            loadNextBatch()
        }
    }

    private func loadNextBatch() {
        let allQuestions: [Question]
        if let subject = subjectFilter {
            allQuestions = QuestionBankLoader.shared.allQuestions().filter { $0.subject == subject }
        } else {
            allQuestions = QuestionBankLoader.shared.allQuestions()
        }

        let available = allQuestions.filter { !seenIds.contains($0.id) }

        guard !available.isEmpty else {
            session.questions = []
            return
        }

        let batch = Array(available.shuffled().prefix(10))
        for q in batch { seenIds.insert(q.id) }

        session.questions = batch
        session.currentIndex = 0
        session.selectedOptionId = nil
        session.isAnswered = false
        session.isCorrect = false
        session.xpEarned = 0
    }

    // MARK: - Stats Cell

    private func endlessStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.resumed.gold)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.resumed.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.resumed.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Auto Card Toast (local copy — ExamQuestionsView's version is private)

private struct EndlessAutoCardToast: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "rectangle.stack.fill.badge.plus")
                .foregroundColor(.resumed.gold)
            Text("ResuCard criado automaticamente")
                .font(.resumed.bodySmall)
                .foregroundColor(.resumed.white)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.round)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.round)
                .stroke(Color.resumed.gold.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: - Endless Summary

struct EndlessSummaryView: View {
    let totalAnswered: Int
    let totalCorrect: Int
    let bestStreak: Int
    let accuracy: Double
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.resumed.gold.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: accuracy >= 70 ? "trophy.fill" : "flame.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.resumed.gold)
            }

            Text("Treino Finalizado!")
                .font(.resumed.h2)
                .foregroundColor(.resumed.white)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Spacing.md
            ) {
                summaryCard(value: "\(totalAnswered)", label: "Questões", icon: "doc.text.fill")
                summaryCard(value: "\(totalCorrect)", label: "Acertos", icon: "checkmark.circle.fill")
                summaryCard(value: "\(Int(accuracy))%", label: "Acurácia", icon: "chart.bar.fill")
                summaryCard(value: "\(bestStreak)", label: "Melhor Streak", icon: "flame.fill")
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            ResumedButton(
                title: "Fechar",
                style: .primary,
                action: onDismiss,
                icon: "checkmark",
                fullWidth: true
            )
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.resumed.black)
    }

    private func summaryCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.resumed.gold)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.resumed.white)
            Text(label)
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.lg)
    }
}
