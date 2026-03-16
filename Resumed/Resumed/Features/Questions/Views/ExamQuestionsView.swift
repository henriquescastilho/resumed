//
//  ExamQuestionsView.swift
//  Resumed
//
//  Exam practice session
//

import SwiftUI

struct ExamQuestionsView: View {
    let exam: Exam

    @StateObject private var session = QuestionSessionManager()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                if session.isLoading {
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

                    Spacer(minLength: 0)
                } else {
                    EmptyState(icon: "doc.text", title: "Sem questões", subtitle: "Tente novamente mais tarde.")
                }
            }
            .padding(.top, Spacing.md)
            .background(Color.resumed.black)
            .navigationTitle(exam.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
            .task {
                await startSession()
            }
        }
    }

    private func startSession() async {
        if APIClient.mode == .mock {
            await session.start(subject: exam.subjectNames.first ?? "Clínica Médica", count: exam.questionCount)
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

    private func handleNext() {
        if session.isFinished() {
            dismiss()
        } else {
            session.nextQuestion()
        }
    }
}
