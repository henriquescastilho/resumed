//
//  DailyQuestionsView.swift
//  Resumed
//
//  Daily question session (Duolingo-style)
//

import SwiftUI

struct DailyQuestionsView: View {
    let subject: String
    let theme: String?
    let isOnline: Bool

    @StateObject private var session = QuestionSessionManager()
    @Environment(\.dismiss) var dismiss

    @State private var selectedCountOption = 10
    @State private var customCount = 10
    @State private var hasStarted = false

    private var countOptions: [Int] { [5, 10, 20] }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                if !isOnline {
                    OfflineBanner(text: "Sem conexão. Questões exigem internet.")
                }

                if let theme, !theme.isEmpty {
                    HStack {
                        Text("Tema: \(theme)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                }

                if !hasStarted {
                    countPicker
                    ResumedButton(
                        title: "Iniciar",
                        style: .primary,
                        action: startSession,
                        isDisabled: !isOnline
                    )
                    .padding(.horizontal, Spacing.md)

                    Spacer()
                } else if session.isLoading {
                    LoadingView(message: "Carregando questões...")
                } else if let error = session.errorMessage {
                    EmptyState(icon: "wifi.exclamationmark", title: "Erro", subtitle: error)
                } else if let question = session.currentQuestion {
                    HStack {
                        Text("Questão \(session.currentIndex + 1) de \(session.questions.count)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                        Spacer()
                        XPBadge(xp: session.xpEarned)
                    }
                    .padding(.horizontal, Spacing.md)

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
                                action: session.confirmAnswer,
                                isDisabled: session.selectedOptionId == nil
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    Spacer(minLength: 0)
                } else {
                    EmptyState(icon: "doc.text", title: "Sem questões", subtitle: "Tente novamente mais tarde.")
                }
            }
            .padding(.top, Spacing.md)
            .background(Color.resumed.black)
            .navigationTitle("Questões")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
        }
    }

    private var countPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quantas questões?")
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)
                .padding(.horizontal, Spacing.md)

            HStack(spacing: Spacing.sm) {
                ForEach(countOptions, id: \.self) { option in
                    FilterChip(title: "\(option)", isSelected: selectedCountOption == option) {
                        selectedCountOption = option
                        customCount = option
                    }
                }
            }
            .padding(.horizontal, Spacing.md)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Personalizar")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
                Stepper(value: $customCount, in: 5...50, step: 1) {
                    Text("\(customCount) questões")
                        .font(.resumed.bodySmall)
                        .foregroundColor(.resumed.white)
                }
                .onChange(of: customCount) { _, newValue in
                    selectedCountOption = newValue
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    private func startSession() {
        hasStarted = true
        Task { await session.start(subject: subject, count: selectedCountOption) }
    }

    private func handleNext() {
        if session.isFinished() {
            dismiss()
        } else {
            session.nextQuestion()
        }
    }
}


private struct OfflineBanner: View {
    let text: String

    var body: some View {
        HStack {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(.resumed.gold)
            Text(text)
                .font(.resumed.bodySmall)
                .foregroundColor(.resumed.white)
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal, Spacing.md)
    }
}
