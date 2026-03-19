//
//  QuestionsHubView.swift
//  Resumed
//
//  Central hub for all question practice modes
//

import SwiftUI

struct QuestionsHubView: View {
    @State private var showEndless = false
    @State private var showQuickPractice = false
    @State private var showSubjectDrill = false
    @State private var showErrorReview = false
    @State private var showMarathon = false

    private let subjects = [
        "Clínica Médica", "Cirurgia Geral", "Pediatria",
        "Ginecologia e Obstetrícia", "MFC", "Saúde Coletiva", "Medicina Preventiva"
    ]

    private var totalQuestions: Int {
        QuestionBankLoader.shared.totalCount
    }

    private var todayAnswered: Int {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let todayKey = f.string(from: Date())
        return UserDefaults.standard.integer(forKey: "questions_correct_today_\(todayKey)")
    }

    private var overallAccuracy: Double {
        CoreDataManager.shared.getAccuracy()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {

                // Stats bar
                HStack(spacing: 0) {
                    statItem(value: "\(totalQuestions)", label: "Disponíveis", icon: "doc.text.fill")
                    Divider()
                        .background(Color.resumed.border)
                        .frame(height: 32)
                    statItem(value: "\(todayAnswered)", label: "Hoje", icon: "calendar")
                    Divider()
                        .background(Color.resumed.border)
                        .frame(height: 32)
                    statItem(value: "\(Int(overallAccuracy))%", label: "Acurácia", icon: "chart.bar.fill")
                }
                .padding(Spacing.md)
                .background(Color.resumed.blackSecondary)
                .cornerRadius(CornerRadius.lg)

                // Mode cards
                modeCard(
                    icon: "skull.fill",
                    title: "Treinar até Morrer",
                    subtitle: "Questões infinitas. Sem limite. Até quando aguentar.",
                    accentColor: Color.resumed.gold,
                    action: { showEndless = true }
                )

                modeCard(
                    icon: "bolt.fill",
                    title: "Prática Rápida",
                    subtitle: "5, 10 ou 20 questões. Escolha a matéria e pratique.",
                    accentColor: Color.resumed.info,
                    action: { showQuickPractice = true }
                )

                modeCard(
                    icon: "list.clipboard.fill",
                    title: "Simulado por Matéria",
                    subtitle: "Foque em uma matéria específica com timer opcional.",
                    accentColor: Color.resumed.success,
                    action: { showSubjectDrill = true }
                )

                modeCard(
                    icon: "xmark.circle.fill",
                    title: "Revisão de Erros",
                    subtitle: "Refaça as questões que você errou.",
                    accentColor: Color.resumed.error,
                    action: { showErrorReview = true }
                )

                modeCard(
                    icon: "shuffle",
                    title: "Maratona Aleatória",
                    subtitle: "Mix de todas as matérias. 30 questões surpresa.",
                    accentColor: Color.resumed.warning,
                    action: { showMarathon = true }
                )
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
        }
        .background(Color.resumed.black)
        .navigationTitle("Questões")
        .navigationBarTitleDisplayMode(.inline)
        // Endless mode
        .fullScreenCover(isPresented: $showEndless) {
            NavigationStack {
                EndlessQuestionsView()
            }
        }
        // Quick practice picker
        .sheet(isPresented: $showQuickPractice) {
            QuickPracticeSheet(subjects: subjects)
        }
        // Subject drill
        .sheet(isPresented: $showSubjectDrill) {
            SubjectDrillSheet(subjects: subjects)
        }
        // Error review
        .fullScreenCover(isPresented: $showErrorReview) {
            ErrorReviewLauncher(onDismiss: { showErrorReview = false })
        }
        // Marathon
        .fullScreenCover(isPresented: $showMarathon) {
            MarathonLauncher()
        }
    }

    // MARK: - Helpers

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.resumed.gold)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.resumed.white)
            Text(label)
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private func modeCard(
        icon: String,
        title: String,
        subtitle: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)
                    Text(subtitle)
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.resumed.gray)
            }
            .padding(Spacing.md)
            .background(Color.resumed.blackSecondary)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Marathon Launcher

private struct MarathonLauncher: View {
    var body: some View {
        ExamQuestionsView(
            questions: Array(QuestionBankLoader.shared.allQuestions().shuffled().prefix(30)),
            title: "Maratona Aleatória"
        )
    }
}

// MARK: - Error Review Launcher
// Separate view to resolve the wrong-answer loading before presenting

private struct ErrorReviewLauncher: View {
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss

    private var wrongQuestions: [Question] {
        let history = CoreDataManager.shared.fetchQuestionHistory(limit: 500)
        let wrongIds = Set(history.filter { !$0.isCorrect }.compactMap { $0.questionId })
        let allQs = QuestionBankLoader.shared.allQuestions()
        return allQs.filter { wrongIds.contains($0.id) }
    }

    var body: some View {
        let questions = wrongQuestions
        Group {
            if questions.isEmpty {
                NavigationStack {
                    EmptyState(
                        icon: "checkmark.circle.fill",
                        title: "Nenhum erro!",
                        subtitle: "Você não errou nenhuma questão ainda. Continue praticando."
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Fechar") { dismiss() }
                                .foregroundColor(.resumed.gray)
                        }
                    }
                    .background(Color.resumed.black)
                }
            } else {
                ExamQuestionsView(
                    questions: Array(questions.shuffled().prefix(30)),
                    title: "Revisão de Erros"
                )
            }
        }
    }
}
