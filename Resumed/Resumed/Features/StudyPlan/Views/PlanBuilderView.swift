//
//  PlanBuilderView.swift
//  Resumed
//
//  Multi-step plan builder — escolha de template, configuração, prioridades e prévia.
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class PlanBuilderViewModel: ObservableObject {
    // Step navigation
    @Published var currentStep: Int = 1
    let totalSteps = 4

    // Step 1 — Template
    @Published var selectedTemplateId: String? = nil  // nil = "Criar do zero"

    // Step 2 — Basics
    @Published var targetExam: String = "ENAMED"
    @Published var dailyHours: Double = 4
    @Published var examDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

    let examOptions = ["ENAMED", "USP", "UNICAMP", "UNIFESP", "SUS-SP", "ENARE", "Revalida", "Outro"]

    // Step 3 — Priorities
    @Published var subjects: [String] = [
        "Clínica Médica",
        "Cirurgia Geral",
        "Ginecologia e Obstetrícia",
        "Pediatria",
        "MFC",
        "Saúde Mental",
        "Saúde Coletiva"
    ]
    @Published var subjectWeights: [String: Double] = [:]

    // Step 4 — Preview (computed on demand)
    @Published var previewDays: [DayPlan] = []

    init() {
        // Initialise weights to 1.0 for all subjects
        for subject in subjects {
            subjectWeights[subject] = 1.0
        }
    }

    // MARK: - Template selection

    func applyTemplate(_ template: StudyPlanTemplate) {
        selectedTemplateId = template.id
        targetExam = template.targetExam
        dailyHours = Double(template.weeklyHours / 7)

        // Apply subject weights from template
        for subject in subjects {
            subjectWeights[subject] = template.subjectWeights[subject] ?? 1.0
        }

        // Reorder subjects by weight (heaviest first)
        subjects = subjects.sorted { (subjectWeights[$0] ?? 1.0) > (subjectWeights[$1] ?? 1.0) }
    }

    func clearTemplate() {
        selectedTemplateId = nil
        for subject in subjects {
            subjectWeights[subject] = 1.0
        }
        subjects = [
            "Clínica Médica",
            "Cirurgia Geral",
            "Ginecologia e Obstetrícia",
            "Pediatria",
            "MFC",
            "Saúde Mental",
            "Saúde Coletiva"
        ]
    }

    // MARK: - Preview generation

    func generatePreview() {
        let calendar = Calendar.current
        let (weekStart, _) = WeekNavigator.weekDateRange(for: 0)

        let weightSum = subjects.reduce(0.0) { $0 + (subjectWeights[$1] ?? 1.0) }
        let totalWeeklyMinutes = Int(dailyHours) * 60 * 7
        let minutesPerUnit = weightSum > 0 ? Double(totalWeeklyMinutes) / weightSum : Double(totalWeeklyMinutes) / Double(subjects.count)

        previewDays = (0..<7).compactMap { offset -> DayPlan? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            var tasks: [StudyTask] = []
            for (i, subject) in subjects.enumerated() {
                let w = subjectWeights[subject] ?? 1.0
                let minutes = max(20, Int((minutesPerUnit * w / 7.0).rounded()))
                tasks.append(StudyTask(
                    id: "preview-\(offset)-\(i)",
                    title: subject,
                    subject: subject,
                    type: .review,
                    dueDate: date,
                    completed: false,
                    estimatedMinutes: minutes,
                    theme: nil,
                    topics: nil
                ))
            }
            let total = tasks.reduce(0) { $0 + $1.estimatedMinutes }
            return DayPlan(date: date, tasks: tasks, totalMinutes: total)
        }
    }

    // MARK: - Apply plan

    func applyPlan() {
        // Save target exam
        UserDefaults.standard.set(targetExam, forKey: "targetExam")
        UserDefaults.standard.set(targetExam, forKey: "selectedExam")
        UserDefaults.standard.set(Int(dailyHours), forKey: "studyHoursPerDay")
        UserDefaults.standard.set(examDate, forKey: "examDate")
        UserDefaults.standard.set(subjects, forKey: "subjectPriority")

        // Persist subject weights for scheduler
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(subjectWeights) {
            UserDefaults.standard.set(data, forKey: "templateSubjectWeights")
        }

        // If a pre-built template was selected, apply it via library
        if let id = selectedTemplateId,
           let template = StudyTemplateLibrary.shared.allTemplates.first(where: { $0.id == id }) {
            StudyTemplateLibrary.shared.apply(template)
        }

        // Invalidate stored weekly plans so they get regenerated
        for offset in -1...1 {
            UserDefaults.standard.removeObject(forKey: "plan_week_\(offset)")
        }

        HapticManager.shared.notification(.success)
    }
}

// MARK: - Main View

struct PlanBuilderView: View {
    @StateObject private var viewModel = PlanBuilderViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                StepProgressBar(current: viewModel.currentStep, total: viewModel.totalSteps)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                // Step content
                Group {
                    switch viewModel.currentStep {
                    case 1: TemplateSelectionStep(viewModel: viewModel)
                    case 2: BasicsConfigStep(viewModel: viewModel)
                    case 3: SubjectPrioritiesStep(viewModel: viewModel)
                    case 4: PlanPreviewStep(viewModel: viewModel)
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Navigation buttons
                stepNavigationButtons
                    .padding(Spacing.md)
            }
            .background(Color.resumed.black)
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        HapticManager.shared.selection()
                        dismiss()
                    }
                    .foregroundColor(.resumed.gray)
                }
            }
        }
    }

    // MARK: - Navigation Buttons

    private var stepNavigationButtons: some View {
        HStack(spacing: Spacing.md) {
            if viewModel.currentStep > 1 {
                ResumedButton(title: "Voltar", style: .ghost, action: {
                    HapticManager.shared.selection()
                    withAnimation { viewModel.currentStep -= 1 }
                }, fullWidth: true)
            }

            if viewModel.currentStep < viewModel.totalSteps {
                ResumedButton(title: "Continuar", style: .primary, action: {
                    HapticManager.shared.selection()
                    if viewModel.currentStep == 3 {
                        viewModel.generatePreview()
                    }
                    withAnimation { viewModel.currentStep += 1 }
                }, fullWidth: true)
            } else {
                ResumedButton(title: "Aplicar Plano", style: .primary, action: {
                    viewModel.applyPlan()
                    dismiss()
                }, icon: "checkmark.circle.fill", fullWidth: true)
            }
        }
    }

    private var stepTitle: String {
        switch viewModel.currentStep {
        case 1: return "Escolher Modelo"
        case 2: return "Configurar Plano"
        case 3: return "Prioridades"
        case 4: return "Prévia do Plano"
        default: return "Criar Plano"
        }
    }
}

// MARK: - Step Progress Bar

private struct StepProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(1...total, id: \.self) { step in
                Capsule()
                    .fill(step <= current ? Color.resumed.gold : Color.resumed.border)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.25), value: current)
            }
        }
    }
}

// MARK: - Step 1: Template Selection

private struct TemplateSelectionStep: View {
    @ObservedObject var viewModel: PlanBuilderViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Escolha um modelo de plano ou comece do zero.")
                    .font(.resumed.bodySmall)
                    .foregroundColor(.resumed.gray)
                    .padding(.horizontal, Spacing.md)

                // "From scratch" option
                BlankTemplateCard(isSelected: viewModel.selectedTemplateId == nil) {
                    viewModel.clearTemplate()
                }
                .padding(.horizontal, Spacing.md)

                // Pre-built templates
                ForEach(StudyTemplateLibrary.shared.prebuiltTemplates) { template in
                    TemplateCard(
                        template: template,
                        isSelected: viewModel.selectedTemplateId == template.id
                    ) {
                        viewModel.applyTemplate(template)
                    }
                    .padding(.horizontal, Spacing.md)
                }

                // Custom templates (if any)
                let customs = StudyTemplateLibrary.shared.customTemplates
                if !customs.isEmpty {
                    Text("Meus modelos")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                        .padding(.horizontal, Spacing.md)

                    ForEach(customs) { template in
                        TemplateCard(
                            template: template,
                            isSelected: viewModel.selectedTemplateId == template.id
                        ) {
                            viewModel.applyTemplate(template)
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
            }
            .padding(.vertical, Spacing.md)
        }
    }
}

private struct BlankTemplateCard: View {
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "plus.square.dashed")
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .resumed.gold : .resumed.gray)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Criar do zero")
                        .font(.resumed.body)
                        .foregroundColor(isSelected ? .resumed.gold : .resumed.white)
                    Text("Personalize todos os detalhes manualmente.")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.resumed.gold)
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.resumed.gold.opacity(0.08) : Color.resumed.blackSecondary)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isSelected ? Color.resumed.gold : Color.resumed.border, lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }
}

private struct TemplateCard: View {
    let template: StudyPlanTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Text(template.name)
                            .font(.resumed.body)
                            .foregroundColor(isSelected ? .resumed.gold : .resumed.white)

                        if !template.createdByUser {
                            Text(template.targetExam)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.resumed.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.resumed.gold)
                                .cornerRadius(CornerRadius.sm)
                        }
                    }

                    Text(template.description)
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                        .lineLimit(2)

                    Text("\(template.weeklyHours / 7)h/dia — \(template.weeklyHours)h/semana")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isSelected ? .resumed.gold : .resumed.gray)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.resumed.gold)
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.resumed.gold.opacity(0.08) : Color.resumed.blackSecondary)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isSelected ? Color.resumed.gold : Color.resumed.border, lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }
}

// MARK: - Step 2: Basics Configuration

private struct BasicsConfigStep: View {
    @ObservedObject var viewModel: PlanBuilderViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Target exam
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Prova alvo")
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)
                        .padding(.horizontal, Spacing.md)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: Spacing.sm
                    ) {
                        ForEach(viewModel.examOptions, id: \.self) { exam in
                            Button {
                                viewModel.targetExam = exam
                                HapticManager.shared.selection()
                            } label: {
                                Text(exam)
                                    .font(.resumed.bodySmall)
                                    .foregroundColor(viewModel.targetExam == exam ? .resumed.black : .resumed.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.sm)
                                    .background(viewModel.targetExam == exam ? Color.resumed.gold : Color.resumed.blackSecondary)
                                    .cornerRadius(CornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .stroke(viewModel.targetExam == exam ? Color.resumed.gold : Color.resumed.border, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }

                // Daily hours
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Horas de estudo por dia")
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)
                        Spacer()
                        Text("\(Int(viewModel.dailyHours))h")
                            .font(.resumed.h3)
                            .foregroundColor(.resumed.gold)
                    }
                    .padding(.horizontal, Spacing.md)

                    Slider(value: $viewModel.dailyHours, in: 1...12, step: 1)
                        .tint(.resumed.gold)
                        .padding(.horizontal, Spacing.md)

                    HStack {
                        Text("1h")
                        Spacer()
                        Text("12h")
                    }
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
                    .padding(.horizontal, Spacing.md)
                }

                // Exam date
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Data da prova")
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)
                        .padding(.horizontal, Spacing.md)

                    DatePicker(
                        "",
                        selection: $viewModel.examDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.resumed.gold)
                    .colorScheme(.dark)
                    .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.vertical, Spacing.md)
        }
    }
}

// MARK: - Step 3: Subject Priorities

private struct SubjectPrioritiesStep: View {
    @ObservedObject var viewModel: PlanBuilderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Arraste para reordenar. Ajuste o peso de cada matéria.")
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

            List {
                ForEach(viewModel.subjects, id: \.self) { subject in
                    SubjectWeightRow(
                        subject: subject,
                        weight: Binding(
                            get: { viewModel.subjectWeights[subject] ?? 1.0 },
                            set: { viewModel.subjectWeights[subject] = $0 }
                        )
                    )
                    .listRowBackground(Color.resumed.blackSecondary)
                    .listRowSeparatorTint(Color.resumed.border)
                }
                .onMove { indices, newOffset in
                    viewModel.subjects.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.resumed.black)
            .environment(\.editMode, .constant(.active))
        }
    }
}

private struct SubjectWeightRow: View {
    let subject: String
    @Binding var weight: Double

    private var weightLabel: String {
        String(format: "%.1fx", weight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(subject)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.white)
                Spacer()
                Text(weightLabel)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(weight > 1.0 ? .resumed.gold : weight < 1.0 ? .resumed.gray : .resumed.white)
            }

            Slider(value: $weight, in: 0.5...2.0, step: 0.1)
                .tint(weight > 1.0 ? .resumed.gold : .resumed.gray)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Step 4: Preview

private struct PlanPreviewStep: View {
    @ObservedObject var viewModel: PlanBuilderViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Prévia da semana")
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)
                    Text("Baseado nas suas configurações. O plano real será gerado ao aplicar.")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
                .padding(.horizontal, Spacing.md)

                // Summary card
                ResumedCard {
                    VStack(spacing: Spacing.sm) {
                        PreviewStatRow(
                            icon: "clock.fill",
                            label: "Horas/dia",
                            value: "\(Int(viewModel.dailyHours))h"
                        )
                        Divider().background(Color.resumed.border)
                        PreviewStatRow(
                            icon: "calendar",
                            label: "Prova",
                            value: viewModel.targetExam
                        )
                        Divider().background(Color.resumed.border)
                        PreviewStatRow(
                            icon: "star.fill",
                            label: "Matéria principal",
                            value: viewModel.subjects.first ?? "—"
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)

                // Mini day previews (first 3 days)
                ForEach(viewModel.previewDays.prefix(3)) { day in
                    MiniDayPreview(day: day)
                        .padding(.horizontal, Spacing.md)
                }

                if viewModel.previewDays.count > 3 {
                    Text("+ \(viewModel.previewDays.count - 3) dias restantes")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                        .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .onAppear { viewModel.generatePreview() }
    }
}

private struct PreviewStatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.resumed.gold)
                .frame(width: 20)
            Text(label)
                .font(.resumed.bodySmall)
                .foregroundColor(.resumed.gray)
            Spacer()
            Text(value)
                .font(.resumed.bodySmall)
                .foregroundColor(.resumed.white)
        }
    }
}

private struct MiniDayPreview: View {
    let day: DayPlan

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(day.dayOfWeek)
                    .font(.resumed.caption)
                    .foregroundColor(day.isToday ? .resumed.gold : .resumed.gray)
                Spacer()
                Text("\(day.totalMinutes) min")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }

            ForEach(day.tasks.prefix(3)) { task in
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(Color.resumed.gold.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Text(task.subject)
                        .font(.system(size: 11))
                        .foregroundColor(.resumed.white)
                    Spacer()
                    Text("\(task.estimatedMinutes)m")
                        .font(.system(size: 11))
                        .foregroundColor(.resumed.gray)
                }
            }

            if day.tasks.count > 3 {
                Text("+ \(day.tasks.count - 3) mais")
                    .font(.system(size: 11))
                    .foregroundColor(.resumed.gray)
            }
        }
        .padding(Spacing.sm)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
    }
}
