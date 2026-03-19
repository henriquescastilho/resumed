//
//  RegisterSimulationSheet.swift
//  Resumed
//
//  Manual registration of external simulation results
//

import SwiftUI

struct RegisterSimulationSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var examName = ""
    @State private var correctCount = ""
    @State private var wrongCount = ""
    @State private var hours = 0
    @State private var minutes = 0
    @State private var totalQuestions = ""
    @State private var selectedDate = Date()
    @State private var showSuccess = false

    private let hourOptions = Array(0...12)
    private let minuteOptions = Array(stride(from: 0, through: 55, by: 5))

    private var isValid: Bool {
        !examName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Int(correctCount) ?? 0) >= 0 &&
        (Int(wrongCount) ?? 0) >= 0 &&
        ((Int(correctCount) ?? 0) + (Int(wrongCount) ?? 0)) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header icon
                    ZStack {
                        Circle()
                            .fill(Color.resumed.gold.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: "doc.text.badge.plus")
                            .font(.system(size: 28))
                            .foregroundColor(.resumed.gold)
                    }
                    .padding(.top, Spacing.md)

                    // Exam name
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Nome da Prova")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        TextField("ex: ENAMED 2025, Simulado Medcel", text: $examName)
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

                    // Date picker
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Data")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.resumed.gold)
                            .environment(\.locale, Locale(identifier: "pt_BR"))
                            .padding(Spacing.sm)
                            .background(Color.resumed.blackSecondary)
                            .cornerRadius(CornerRadius.md)
                    }

                    // Results row
                    HStack(spacing: Spacing.md) {
                        // Correct
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.resumed.success)
                                    .font(.system(size: 14))
                                Text("Acertos")
                                    .font(.resumed.caption)
                                    .foregroundColor(.resumed.gray)
                            }

                            TextField("0", text: $correctCount)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.resumed.success)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .padding(Spacing.md)
                                .background(Color.resumed.success.opacity(0.08))
                                .cornerRadius(CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(Color.resumed.success.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Wrong
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.resumed.error)
                                    .font(.system(size: 14))
                                Text("Erros")
                                    .font(.resumed.caption)
                                    .foregroundColor(.resumed.gray)
                            }

                            TextField("0", text: $wrongCount)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.resumed.error)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .padding(Spacing.md)
                                .background(Color.resumed.error.opacity(0.08))
                                .cornerRadius(CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .stroke(Color.resumed.error.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }

                    // Computed accuracy preview
                    if let correct = Int(correctCount), let wrong = Int(wrongCount), correct + wrong > 0 {
                        let total = correct + wrong
                        let accuracy = Double(correct) / Double(total) * 100

                        HStack {
                            Text("Resultado:")
                                .font(.resumed.body)
                                .foregroundColor(.resumed.gray)
                            Spacer()
                            Text("\(correct)/\(total) (\(Int(accuracy))%)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(accuracy >= 70 ? .resumed.success : accuracy >= 50 ? .resumed.warning : .resumed.error)
                        }
                        .padding(Spacing.md)
                        .background(Color.resumed.blackSecondary)
                        .cornerRadius(CornerRadius.md)
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Duração (opcional)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)

                        HStack(spacing: Spacing.md) {
                            // Hours
                            VStack(spacing: 4) {
                                Picker("Horas", selection: $hours) {
                                    ForEach(hourOptions, id: \.self) { h in
                                        Text("\(h)h").tag(h)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 80)
                                .clipped()
                            }

                            // Minutes
                            VStack(spacing: 4) {
                                Picker("Minutos", selection: $minutes) {
                                    ForEach(minuteOptions, id: \.self) { m in
                                        Text("\(m)min").tag(m)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 80)
                                .clipped()
                            }
                        }
                        .padding(Spacing.sm)
                        .background(Color.resumed.blackSecondary)
                        .cornerRadius(CornerRadius.md)
                    }

                    Spacer(minLength: Spacing.lg)

                    // Save button
                    ResumedButton(
                        title: "Registrar Resultado",
                        style: .primary,
                        action: saveResult,
                        icon: "checkmark.circle.fill",
                        isDisabled: !isValid,
                        fullWidth: true
                    )
                    .padding(.bottom, Spacing.lg)
                }
                .padding(.horizontal, Spacing.md)
            }
            .background(Color.resumed.black)
            .navigationTitle("Registrar Simulado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
        }
    }

    private func saveResult() {
        let correct = Int(correctCount) ?? 0
        let wrong = Int(wrongCount) ?? 0
        let total = correct + wrong
        let durationSeconds = (hours * 3600) + (minutes * 60)

        let log = SimulationLog(
            id: UUID().uuidString,
            date: selectedDate,
            title: examName.trimmingCharacters(in: .whitespaces),
            mode: .study,
            totalQuestions: total,
            correctCount: correct,
            wrongCount: wrong,
            unansweredCount: 0,
            durationSeconds: durationSeconds,
            questions: []
        )

        SimulationLogStore.save(log)
        HapticManager.shared.success()

        withAnimation(.spring(response: 0.4)) {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }

    private var successOverlay: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.resumed.success)

            Text("Resultado registrado!")
                .font(.resumed.h3)
                .foregroundColor(.resumed.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.resumed.black.opacity(0.9))
        .transition(.opacity)
    }
}
