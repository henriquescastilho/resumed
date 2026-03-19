//
//  ExamQuestionsView.swift
//  Resumed
//
//  Exam practice session.
//  Supports two launch modes:
//    1. Legacy — receives an Exam value, fetches from API or mock.
//    2. Bank — receives a pre-loaded [Question] array and a display title
//             (used when launching from PastExamsView with real bank questions).
//

import SwiftUI

struct ExamQuestionsView: View {
    // MARK: - Configuration

    enum Source {
        /// Original flow: fetch questions from API/mock based on Exam metadata.
        case exam(Exam)
        /// Bank flow: questions already loaded from questions_bank.json.
        case bank(questions: [Question], title: String)
        /// Timed exam: pre-loaded questions with a countdown timer.
        case timed(questions: [Question], title: String, durationSeconds: Int)
    }

    let source: Source

    // Convenience init kept for all existing callers (ExamTimerView, ExamDetailSheet, etc.)
    init(exam: Exam) {
        self.source = .exam(exam)
    }

    // Bank init used by PastExamsView.
    init(questions: [Question], title: String) {
        self.source = .bank(questions: questions, title: title)
    }

    // Timed exam init.
    init(questions: [Question], title: String, durationSeconds: Int) {
        self.source = .timed(questions: questions, title: title, durationSeconds: durationSeconds)
    }

    @StateObject private var session = QuestionSessionManager()
    @Environment(\.dismiss) var dismiss
    @State private var showGreySheet = false
    @State private var greyContext: String = ""
    @State private var showQuitConfirmation = false
    @State private var showTimedSummary = false

    private var navigationTitle: String {
        switch source {
        case .exam(let exam): return exam.name
        case .bank(_, let title): return title
        case .timed(_, let title, _): return title
        }
    }

    private var isTimedMode: Bool {
        if case .timed = source { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                if session.isLoading {
                    LoadingView(message: "Carregando questões...")
                } else if let error = session.errorMessage {
                    EmptyState(icon: "wifi.exclamationmark", title: "Erro", subtitle: error)
                } else if let question = session.currentQuestion {
                    // Timer bar for timed mode
                    if session.isTimedMode {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(session.totalTimeRemaining < 600 ? .resumed.error : .resumed.gold)
                            Text(session.formattedTimeRemaining)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(session.totalTimeRemaining < 600 ? .resumed.error : .resumed.white)
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            (session.totalTimeRemaining < 600 ? Color.resumed.error : Color.resumed.gold)
                                .opacity(0.1)
                        )
                        .cornerRadius(CornerRadius.md)
                        .padding(.horizontal, Spacing.md)
                    }

                    HStack {
                        Text("Questão \(session.currentIndex + 1) de \(session.questions.count)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                        Spacer()
                        XPBadge(xp: session.xpEarned)
                    }
                    .padding(.horizontal, Spacing.md)

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
                    }

                    HStack(spacing: Spacing.md) {
                        if session.isAnswered {
                            ResumedButton(
                                title: session.isFinished() ? "Finalizar" : "Próxima",
                                style: .primary,
                                action: handleNext
                            )
                        } else {
                            ResumedButton(
                                title: "Confirmar",
                                style: .primary,
                                action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        session.confirmAnswer()
                                    }
                                },
                                isDisabled: session.selectedOptionId == nil
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                } else {
                    EmptyState(
                        icon: "doc.text",
                        title: "Sem questões",
                        subtitle: "Tente novamente mais tarde."
                    )
                }
            }
            .padding(.top, Spacing.md)
            .background(Color.resumed.black)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if session.isTimedMode {
                        Button("Desistir") { showQuitConfirmation = true }
                            .foregroundColor(.resumed.error)
                    } else {
                        Button("Fechar") { dismiss() }
                            .foregroundColor(.resumed.gray)
                    }
                }
            }
            .alert("Desistir do Simulado?", isPresented: $showQuitConfirmation) {
                Button("Continuar", role: .cancel) { }
                Button("Desistir", role: .destructive) {
                    session.stopTimer()
                    showTimedSummary = true
                }
            } message: {
                Text("Seu progresso será salvo, mas o simulado será encerrado.")
            }
            .onChange(of: session.timedExamFinished) { _, finished in
                if finished {
                    session.awardExamXPOnce()
                    showTimedSummary = true
                }
            }
            .fullScreenCover(isPresented: $showTimedSummary) {
                TimedExamSummaryView(
                    correctCount: session.correctCount,
                    totalCount: session.questions.count,
                    elapsedFormatted: session.totalElapsedFormatted,
                    durationFormatted: session.totalDurationFormatted,
                    perSubjectResults: session.perSubjectResults,
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
            .task {
                await startSession()
            }
            .overlay(alignment: .bottom) {
                if session.showAutoCardToast {
                    AutoCardToast()
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
        }
    }

    // MARK: - Session Start

    private func askGreyAboutQuestion() {
        guard let q = session.currentQuestion else { return }
        let selectedText = q.options.first(where: { $0.id == session.selectedOptionId })?.text ?? ""
        let correctText = q.options.first(where: { $0.id == q.correctOptionId })?.text ?? ""
        greyContext = "Questão: \(q.statement)\nMinha resposta: \(selectedText)\nResposta correta: \(correctText)\nExplicação: \(q.explanation)\n\nMe explique por que a resposta correta é essa e por que a minha está errada."
        showGreySheet = true
    }

    private func startSession() async {
        switch source {
        case .exam(let exam):
            await startExamSession(exam)
        case .bank(let questions, _):
            await startBankSession(questions)
        case .timed(let questions, _, let duration):
            await startBankSession(questions)
            session.startTimedMode(durationSeconds: duration)
        }
    }

    private func startExamSession(_ exam: Exam) async {
        if APIClient.mode == .mock {
            await session.start(
                subject: exam.subjectNames.first ?? "Clínica Médica",
                count: exam.questionCount
            )
            return
        }
        session.isLoading = true
        do {
            let questions = try await APIClient.shared.getExamQuestions(examId: exam.id)
            session.questions = questions
            session.currentIndex = 0
            session.isLoading = false
        } catch {
            session.errorMessage = "Não foi possível carregar a prova."
            session.isLoading = false
        }
    }

    private func startBankSession(_ questions: [Question]) async {
        guard !questions.isEmpty else {
            session.errorMessage = "Esta prova não possui questões disponíveis."
            return
        }
        session.questions = questions
        session.currentIndex = 0
        session.selectedOptionId = nil
        session.isAnswered = false
        session.isCorrect = false
        session.xpEarned = 0
        session.correctCount = 0
    }

    // MARK: - Navigation

    private func handleNext() {
        if session.isFinished() {
            if session.isTimedMode {
                session.stopTimer()
                session.awardExamXPOnce()
                showTimedSummary = true
            } else {
                dismiss()
            }
        } else {
            session.nextQuestion()
        }
    }
}

// MARK: - Auto Card Toast

private struct AutoCardToast: View {
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
