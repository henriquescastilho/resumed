//
//  EditTaskSheet.swift
//  Resumed
//
//  Sheet for adding or editing a study task
//

import SwiftUI

struct EditTaskSheet: View {
    enum Mode {
        case add(date: Date)
        case edit(task: StudyTask)
    }

    let mode: Mode
    let onSave: (StudyTask) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) var dismiss

    @State private var title: String = ""
    @State private var subject: String = "Clínica Médica"
    @State private var taskType: StudyTask.TaskType = .review
    @State private var estimatedMinutes: Int = 30
    @State private var theme: String = ""
    @State private var showDeleteAlert = false

    private let subjects = [
        "Clínica Médica",
        "Cirurgia Geral",
        "Ginecologia e Obstetrícia",
        "Pediatria",
        "MFC",
        "Saúde Mental",
        "Saúde Coletiva",
        "Medicina Preventiva"
    ]

    private let taskTypes: [StudyTask.TaskType] = [.review, .reading, .practice, .flashcards, .video]

    private let minuteOptions = [15, 20, 30, 45, 60, 90, 120]

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var taskDate: Date {
        switch mode {
        case .add(let date): return date
        case .edit(let task): return task.dueDate
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Title field
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Título (opcional)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        TextField("ex: Assistir aula do cursinho", text: $title)
                            .font(.resumed.body)
                            .foregroundColor(.resumed.white)
                            .padding(Spacing.md)
                            .background(Color.resumed.blackSecondary)
                            .cornerRadius(CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(Color.resumed.border, lineWidth: 1)
                            )
                    }

                    // Subject picker
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Matéria")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                            ForEach(subjects, id: \.self) { subj in
                                Button {
                                    subject = subj
                                    HapticManager.shared.selection()
                                } label: {
                                    Text(subj)
                                        .font(.resumed.bodySmall)
                                        .foregroundColor(subject == subj ? .resumed.black : .resumed.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.sm)
                                        .background(subject == subj ? Color.resumed.gold : Color.resumed.blackSecondary)
                                        .cornerRadius(CornerRadius.md)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                                .stroke(subject == subj ? Color.resumed.gold : Color.resumed.border, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    // Task type picker
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Tipo")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(taskTypes, id: \.rawValue) { type in
                                    Button {
                                        taskType = type
                                        HapticManager.shared.selection()
                                    } label: {
                                        HStack(spacing: Spacing.xs) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 12))
                                            Text(type.displayName)
                                                .font(.resumed.bodySmall)
                                        }
                                        .foregroundColor(taskType == type ? .resumed.black : .resumed.white)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(taskType == type ? Color.resumed.gold : Color.resumed.blackSecondary)
                                        .cornerRadius(CornerRadius.round)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: CornerRadius.round)
                                                .stroke(taskType == type ? Color.resumed.gold : Color.resumed.border, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Duration picker
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Duração")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        HStack(spacing: Spacing.sm) {
                            ForEach(minuteOptions, id: \.self) { mins in
                                Button {
                                    estimatedMinutes = mins
                                    HapticManager.shared.selection()
                                } label: {
                                    VStack(spacing: 2) {
                                        Text("\(mins)")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                        Text("min")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(estimatedMinutes == mins ? .resumed.black : .resumed.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.sm)
                                    .background(estimatedMinutes == mins ? Color.resumed.gold : Color.resumed.blackSecondary)
                                    .cornerRadius(CornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .stroke(estimatedMinutes == mins ? Color.resumed.gold : Color.resumed.border, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    // Theme field
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Tema (opcional)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        TextField("ex: Urgências em pediatria", text: $theme)
                            .font(.resumed.body)
                            .foregroundColor(.resumed.white)
                            .padding(Spacing.md)
                            .background(Color.resumed.blackSecondary)
                            .cornerRadius(CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(Color.resumed.border, lineWidth: 1)
                            )
                    }

                    Spacer(minLength: Spacing.lg)

                    // Save button
                    ResumedButton(
                        title: isEditing ? "Salvar Alterações" : "Adicionar Tarefa",
                        style: .primary,
                        action: saveTask,
                        icon: isEditing ? "checkmark" : "plus",
                        fullWidth: true
                    )

                    // Delete button (edit mode only)
                    if isEditing, let onDelete {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "trash")
                                Text("Remover Tarefa")
                            }
                            .font(.resumed.body)
                            .foregroundColor(.resumed.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                        }
                    }
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.resumed.black)
            .navigationTitle(isEditing ? "Editar Tarefa" : "Nova Tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
            .alert("Remover tarefa?", isPresented: $showDeleteAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Remover", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("Esta tarefa será removida do seu plano.")
            }
            .onAppear {
                if case .edit(let task) = mode {
                    title = task.title
                    subject = task.subject
                    taskType = task.type
                    estimatedMinutes = task.estimatedMinutes
                    theme = task.theme ?? ""
                }
            }
        }
    }

    private func saveTask() {
        let taskTitle = title.trimmingCharacters(in: .whitespaces)
        let taskTheme = theme.trimmingCharacters(in: .whitespaces)

        let task: StudyTask
        if case .edit(let existing) = mode {
            task = StudyTask(
                id: existing.id,
                title: taskTitle.isEmpty ? subject : taskTitle,
                subject: subject,
                type: taskType,
                dueDate: existing.dueDate,
                completed: existing.completed,
                estimatedMinutes: estimatedMinutes,
                theme: taskTheme.isEmpty ? nil : taskTheme,
                topics: nil
            )
        } else {
            task = StudyTask(
                id: "user-\(UUID().uuidString)",
                title: taskTitle.isEmpty ? subject : taskTitle,
                subject: subject,
                type: taskType,
                dueDate: taskDate,
                completed: false,
                estimatedMinutes: estimatedMinutes,
                theme: taskTheme.isEmpty ? nil : taskTheme,
                topics: nil
            )
        }

        onSave(task)
        HapticManager.shared.success()
        dismiss()
    }
}
