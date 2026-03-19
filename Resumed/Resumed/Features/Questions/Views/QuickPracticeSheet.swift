//
//  QuickPracticeSheet.swift
//  Resumed
//
//  Quick practice and subject drill mode pickers
//

import SwiftUI

// MARK: - Quick Practice Sheet

struct QuickPracticeSheet: View {
    let subjects: [String]

    @Environment(\.dismiss) var dismiss
    @State private var selectedSubject: String? = nil
    @State private var questionCount = 10
    @State private var showSession = false

    private let countOptions = [5, 10, 20]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Count picker
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Quantidade")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        HStack(spacing: Spacing.sm) {
                            ForEach(countOptions, id: \.self) { count in
                                Button {
                                    questionCount = count
                                    HapticManager.shared.selection()
                                } label: {
                                    Text("\(count)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(questionCount == count ? .resumed.black : .resumed.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.md)
                                        .background(questionCount == count ? Color.resumed.gold : Color.resumed.blackSecondary)
                                        .cornerRadius(CornerRadius.md)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                                .stroke(
                                                    questionCount == count ? Color.resumed.gold : Color.resumed.border,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                            }
                        }
                    }

                    // Subject picker
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Matéria")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        // "Todas" pill
                        Button {
                            selectedSubject = nil
                            HapticManager.shared.selection()
                        } label: {
                            Text("Todas as matérias")
                                .font(.resumed.body)
                                .foregroundColor(selectedSubject == nil ? .resumed.black : .resumed.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(selectedSubject == nil ? Color.resumed.gold : Color.resumed.blackSecondary)
                                .cornerRadius(CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(
                                            selectedSubject == nil ? Color.resumed.gold : Color.resumed.border,
                                            lineWidth: 1
                                        )
                                )
                        }

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: Spacing.sm
                        ) {
                            ForEach(subjects, id: \.self) { subj in
                                Button {
                                    selectedSubject = subj
                                    HapticManager.shared.selection()
                                } label: {
                                    Text(subj)
                                        .font(.resumed.bodySmall)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(selectedSubject == subj ? .resumed.black : .resumed.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.sm)
                                        .background(selectedSubject == subj ? Color.resumed.gold : Color.resumed.blackSecondary)
                                        .cornerRadius(CornerRadius.md)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                                .stroke(
                                                    selectedSubject == subj ? Color.resumed.gold : Color.resumed.border,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.resumed.black)
            .safeAreaInset(edge: .bottom) {
                ResumedButton(
                    title: "Iniciar (\(questionCount) questões)",
                    style: .primary,
                    action: { showSession = true },
                    icon: "play.fill",
                    fullWidth: true
                )
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .background(Color.resumed.black)
            }
            .navigationTitle("Prática Rápida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
            .fullScreenCover(isPresented: $showSession) {
                let questions = loadQuestions(subject: selectedSubject, count: questionCount)
                ExamQuestionsView(
                    questions: questions,
                    title: selectedSubject ?? "Prática Rápida"
                )
            }
        }
    }

    private func loadQuestions(subject: String?, count: Int) -> [Question] {
        if let subject {
            return QuestionBankLoader.shared.questions(for: subject, count: count)
        } else {
            return Array(QuestionBankLoader.shared.allQuestions().shuffled().prefix(count))
        }
    }
}

// MARK: - Subject Drill Sheet

struct SubjectDrillSheet: View {
    let subjects: [String]

    @Environment(\.dismiss) var dismiss
    @State private var selectedSubject: String = "Clínica Médica"
    @State private var withTimer = false
    @State private var questionCount = 20
    @State private var showSession = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Subject list
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Matéria")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        ForEach(subjects, id: \.self) { subj in
                            let count = QuestionBankLoader.shared.questions(for: subj, count: 9999).count
                            Button {
                                selectedSubject = subj
                                HapticManager.shared.selection()
                            } label: {
                                HStack {
                                    Text(subj)
                                        .font(.resumed.body)
                                        .foregroundColor(selectedSubject == subj ? .resumed.black : .resumed.white)
                                    Spacer()
                                    Text("\(count) questões")
                                        .font(.resumed.caption)
                                        .foregroundColor(selectedSubject == subj ? Color.resumed.black.opacity(0.7) : .resumed.gray)
                                }
                                .padding(Spacing.md)
                                .background(selectedSubject == subj ? Color.resumed.gold : Color.resumed.blackSecondary)
                                .cornerRadius(CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(
                                            selectedSubject == subj ? Color.resumed.gold : Color.resumed.border,
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }

                    // Timer toggle
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.resumed.gold)
                        Text("Com cronômetro")
                            .font(.resumed.body)
                            .foregroundColor(.resumed.white)
                        Spacer()
                        Toggle("", isOn: $withTimer)
                            .tint(.resumed.gold)
                    }
                    .padding(Spacing.md)
                    .background(Color.resumed.blackSecondary)
                    .cornerRadius(CornerRadius.md)

                    if withTimer {
                        Text("3 minutos por questão")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.resumed.black)
            .safeAreaInset(edge: .bottom) {
                ResumedButton(
                    title: "Iniciar Simulado",
                    style: .primary,
                    action: { showSession = true },
                    icon: "play.fill",
                    fullWidth: true
                )
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .background(Color.resumed.black)
            }
            .navigationTitle("Simulado por Matéria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
            .fullScreenCover(isPresented: $showSession) {
                let questions = QuestionBankLoader.shared.questions(for: selectedSubject, count: questionCount)
                if withTimer {
                    ExamQuestionsView(
                        questions: questions,
                        title: selectedSubject,
                        durationSeconds: questions.count * 180
                    )
                } else {
                    ExamQuestionsView(
                        questions: questions,
                        title: selectedSubject
                    )
                }
            }
        }
    }
}
