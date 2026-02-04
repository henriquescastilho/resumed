//
//  PastExamsView.swift
//  Resumed
//
//  Past Exams View - Simulados
//

import SwiftUI
import Combine

struct PastExamsView: View {
    @StateObject private var viewModel = PastExamsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    FilterChip(title: "Todas", isSelected: viewModel.selectedInstitution == nil) {
                        viewModel.selectedInstitution = nil
                    }
                    ForEach(viewModel.institutions, id: \.self) { institution in
                        FilterChip(title: institution, isSelected: viewModel.selectedInstitution == institution) {
                            viewModel.selectedInstitution = institution
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .background(Color.resumed.blackSecondary)

            // Exams list
            if viewModel.isLoading {
                LoadingView(message: "Carregando provas...")
            } else if viewModel.filteredExams.isEmpty {
                EmptyState(icon: "doc.text", title: "Nenhuma prova", subtitle: "Ajuste os filtros")
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(viewModel.filteredExams) { exam in
                            ExamCard(exam: exam) {
                                viewModel.selectedExam = exam
                                viewModel.showExamDetail = true
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
                }
            }
        }
        .background(Color.resumed.black)
        .navigationTitle("Provas Anteriores")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadExams()
        }
        .sheet(isPresented: $viewModel.showExamDetail) {
            if let exam = viewModel.selectedExam {
                ExamDetailSheet(exam: exam, onStart: {
                    viewModel.showExamDetail = false
                })
            }
        }
    }
}

@MainActor
class PastExamsViewModel: ObservableObject {
    @Published var exams: [Exam] = []
    @Published var selectedInstitution: String?
    @Published var selectedExam: Exam?
    @Published var showExamDetail = false
    @Published var isLoading = false

    var institutions: [String] {
        Array(Set(exams.map { $0.institution })).sorted()
    }

    var filteredExams: [Exam] {
        guard let institution = selectedInstitution else { return exams }
        return exams.filter { $0.institution == institution }
    }

    func loadExams() async {
        isLoading = true
        loadMockExams()
        isLoading = false
    }

    private func loadMockExams() {
        exams = [
            Exam(id: "1", institution: "USP", name: "USP - Clínica Médica", year: 2023, subjects: ["Clínica Médica"], questionCount: 100, durationMinutes: 240, difficulty: "Difícil"),
            Exam(id: "2", institution: "UNICAMP", name: "UNICAMP - Geral", year: 2023, subjects: ["Clínica", "Cirurgia", "Pediatria"], questionCount: 120, durationMinutes: 300, difficulty: "Difícil"),
            Exam(id: "3", institution: "ENARE", name: "ENARE 2023", year: 2023, subjects: ["Todas"], questionCount: 100, durationMinutes: 300, difficulty: "Médio"),
            Exam(id: "4", institution: "SUS-SP", name: "SUS-SP 2022", year: 2022, subjects: ["Clínica", "Preventiva"], questionCount: 80, durationMinutes: 180, difficulty: "Médio"),
            Exam(id: "5", institution: "UNIFESP", name: "UNIFESP - Cirurgia", year: 2022, subjects: ["Cirurgia"], questionCount: 60, durationMinutes: 150, difficulty: "Difícil")
        ]
    }
}

struct Exam: Identifiable, Codable {
    let id: String
    let institution: String
    let name: String
    let year: Int
    let subjects: [String]
    let questionCount: Int
    let durationMinutes: Int
    let difficulty: String

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)min" : "\(minutes)min"
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.resumed.bodySmall)
                .foregroundColor(isSelected ? .resumed.black : .resumed.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.resumed.gold : Color.resumed.blackTertiary)
                .cornerRadius(CornerRadius.round)
        }
    }
}

struct ExamCard: View {
    let exam: Exam
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ResumedCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text(exam.institution)
                            .font(.resumed.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.resumed.gold)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.resumed.gold.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)

                        Spacer()

                        Text(String(exam.year))
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }

                    Text(exam.name)
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)

                    HStack(spacing: Spacing.lg) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "doc.text")
                            Text("\(exam.questionCount)")
                        }
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "clock")
                            Text(exam.formattedDuration)
                        }
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "chart.bar")
                            Text(exam.difficulty)
                        }
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                    }
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ExamDetailSheet: View {
    let exam: Exam
    let onStart: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text(exam.institution)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gold)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.resumed.gold.opacity(0.1))
                            .cornerRadius(CornerRadius.md)

                        Text(exam.name)
                            .font(.resumed.h2)
                            .foregroundColor(.resumed.white)
                    }
                    .padding(.top, Spacing.lg)

                    // Stats
                    HStack(spacing: Spacing.md) {
                        StatBox(icon: "doc.text", value: "\(exam.questionCount)", label: "Questões")
                        StatBox(icon: "clock", value: exam.formattedDuration, label: "Duração")
                    }

                    // Subjects
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Matérias")
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                            ForEach(exam.subjects, id: \.self) { subject in
                                Text(subject)
                                    .font(.resumed.bodySmall)
                                    .foregroundColor(.resumed.white)
                                    .padding(Spacing.sm)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.resumed.blackSecondary)
                                    .cornerRadius(CornerRadius.md)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: Spacing.xl)

                    ResumedButton(
                        title: "Iniciar Prova",
                        style: .primary,
                        action: onStart,
                        icon: "play.fill",
                        fullWidth: true
                    )
                }
                .padding(Spacing.md)
            }
            .background(Color.resumed.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.resumed.gold)
                }
            }
        }
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        ResumedCard {
            VStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: IconSize.lg))
                    .foregroundColor(.resumed.gold)

                Text(value)
                    .font(.resumed.h3)
                    .foregroundColor(.resumed.white)

                Text(label)
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
