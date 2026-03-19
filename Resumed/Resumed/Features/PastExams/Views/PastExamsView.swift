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
                            .contextMenu {
                                Button {
                                    viewModel.generateAndSharePDF(exam: exam)
                                } label: {
                                    Label("Baixar PDF da Prova", systemImage: "arrow.down.doc.fill")
                                }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Como estudar") { viewModel.showHowToStudy = true }
                    .foregroundColor(.resumed.gold)
            }
        }
        .task {
            await viewModel.loadExams()
        }
        .sheet(isPresented: $viewModel.showExamDetail) {
            if let exam = viewModel.selectedExam {
                ExamDetailSheet(
                    exam: exam,
                    canStart: true,
                    onStart: {
                        viewModel.showExamDetail = false
                        viewModel.startExam(exam)
                    },
                    onPrint: {
                        viewModel.printExam(exam)
                    },
                    onDownloadPDF: {
                        viewModel.showExamDetail = false
                        viewModel.generateAndSharePDF(exam: exam)
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showExamSession) {
            if let exam = viewModel.selectedExam {
                ExamTimerView(exam: exam)
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $viewModel.showHowToStudy) {
            HowToStudySheet()
        }
    }
}

@MainActor
class PastExamsViewModel: ObservableObject {
    @Published var exams: [Exam] = []
    @Published var selectedInstitution: String?
    @Published var selectedExam: Exam?
    @Published var showExamDetail = false
    @Published var showExamSession = false
    @Published var isLoading = false
    @Published var showShareSheet = false
    @Published var shareURL: URL?
    @Published var isPreparingPrint = false
    @Published var showHowToStudy = false

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

    func startExam(_ exam: Exam) {
        selectedExam = exam
        showExamSession = true
    }

    func generateAndSharePDF(exam: Exam) {
        Task {
            if let url = ExamPDFGenerator.shared.generateExamPDF(exam: exam) {
                shareURL = url
                showShareSheet = true
                HapticManager.shared.success()
            } else {
                HapticManager.shared.error()
            }
        }
    }

    func printExam(_ exam: Exam) {
        isPreparingPrint = true
        do {
            let content = buildPrintableExam(exam: exam)
            let url = try writePrintableExam(exam: exam, content: content)
            shareURL = url
            showShareSheet = true
            HapticManager.shared.selection()
        } catch {
            HapticManager.shared.error()
        }
        isPreparingPrint = false
    }

    private func buildPrintableExam(exam: Exam) -> String {
        var lines: [String] = []
        lines.append("RESUMED — FOLHA DE RASCUNHO")
        lines.append("\(exam.name) • \(exam.year)")
        lines.append("Duração: \(exam.formattedDuration) • Questões: \(exam.questionCount)")
        lines.append("")
        lines.append("Nome: ______________________________  Data: ____/____/______")
        lines.append("Instituição: ________________________  Tempo limite: ________")
        lines.append("")
        lines.append("FOLHA DE RESPOSTAS (marque apenas uma alternativa)")
        lines.append("")
        for index in 1...exam.questionCount {
            lines.append(String(format: "%3d  [ ] A   [ ] B   [ ] C   [ ] D   [ ] E", index))
        }
        lines.append("")
        lines.append("ANOTAÇÕES / RASCUNHO")
        lines.append("------------------------------------------------------------------")
        for _ in 0..<24 {
            lines.append("__________________________________________________________________")
        }
        return lines.joined(separator: "\n")
    }

    private func writePrintableExam(exam: Exam, content: String) throws -> URL {
        let fileName = "RESUMED_\(exam.institution)_\(exam.year).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func loadMockExams() {
        exams = ExamCalendar.exams
    }
}

// Exam struct is defined in Core/Models/ExamModels.swift

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
                            Text(exam.difficulty.rawValue)
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
    let canStart: Bool
    let onStart: () -> Void
    let onPrint: () -> Void
    let onDownloadPDF: (() -> Void)?
    @Environment(\.dismiss) var dismiss

    init(
        exam: Exam,
        canStart: Bool,
        onStart: @escaping () -> Void,
        onPrint: @escaping () -> Void,
        onDownloadPDF: (() -> Void)? = nil
    ) {
        self.exam = exam
        self.canStart = canStart
        self.onStart = onStart
        self.onPrint = onPrint
        self.onDownloadPDF = onDownloadPDF
    }

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
                            ForEach(exam.subjectNames, id: \.self) { subject in
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
                        isDisabled: !canStart,
                        fullWidth: true
                    )

                    ResumedButton(
                        title: "Imprimir Rascunho",
                        style: .ghost,
                        action: onPrint,
                        icon: "printer.fill",
                        isDisabled: !canStart,
                        fullWidth: true
                    )

                    if let onDownloadPDF = onDownloadPDF {
                        ResumedButton(
                            title: "Baixar PDF da Prova",
                            style: .secondary,
                            action: onDownloadPDF,
                            icon: "arrow.down.doc.fill",
                            fullWidth: true
                        )
                    }
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
