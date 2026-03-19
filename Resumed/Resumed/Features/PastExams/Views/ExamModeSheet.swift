//
//  ExamModeSheet.swift
//  Resumed
//
//  Sheet for choosing between study mode and timed exam mode.
//

import SwiftUI

struct ExamModeSheet: View {
    let edition: BankExamEdition
    let questionCount: Int
    let onStudyMode: () -> Void
    let onTimedMode: (Int) -> Void

    @Environment(\.dismiss) var dismiss

    private var defaultDuration: Int {
        // ENAMED = 300 min, default = 3 min/question
        if edition.exam.uppercased().contains("ENAMED") {
            return 300 * 60
        }
        return questionCount * 3 * 60
    }

    private var durationText: String {
        let totalMin = defaultDuration / 60
        let h = totalMin / 60
        let m = totalMin % 60
        if h > 0 && m > 0 {
            return "\(h)h\(String(format: "%02d", m))min"
        } else if h > 0 {
            return "\(h)h"
        }
        return "\(m)min"
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            VStack(spacing: Spacing.sm) {
                Text("Como deseja praticar?")
                    .font(.resumed.h3)
                    .foregroundColor(.resumed.white)

                Text(edition.displayTitle)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gray)
            }
            .padding(.top, Spacing.xl)

            // Study Mode Card
            modeCard(
                icon: "book.fill",
                title: "Modo Estudo",
                subtitle: "Sem timer. Revise no seu ritmo, veja explicações e aprenda.",
                accentColor: .resumed.success,
                action: {
                    onStudyMode()
                    dismiss()
                }
            )

            // Timed Mode Card
            modeCard(
                icon: "timer",
                title: "Simulado Cronometrado",
                subtitle: "\(questionCount) questões · \(durationText)\nSimula condições reais de prova.",
                accentColor: .resumed.gold,
                action: {
                    onTimedMode(defaultDuration)
                    dismiss()
                }
            )

            Spacer()

            Button("Cancelar") { dismiss() }
                .font(.resumed.body)
                .foregroundColor(.resumed.gray)
                .padding(.bottom, Spacing.lg)
        }
        .padding(.horizontal, Spacing.md)
        .background(Color.resumed.black)
        .presentationDetents([.medium])
    }

    private func modeCard(
        icon: String,
        title: String,
        subtitle: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: IconSize.xl))
                    .foregroundColor(accentColor)
                    .frame(width: 48)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)

                    Text(subtitle)
                        .font(.resumed.bodySmall)
                        .foregroundColor(.resumed.gray)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.resumed.gray)
            }
            .padding(Spacing.md)
            .background(Color.resumed.blackSecondary)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
