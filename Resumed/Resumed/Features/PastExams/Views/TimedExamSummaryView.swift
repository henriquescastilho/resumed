//
//  TimedExamSummaryView.swift
//  Resumed
//
//  Post-exam summary for timed exam mode.
//

import SwiftUI

struct TimedExamSummaryView: View {
    let correctCount: Int
    let totalCount: Int
    let elapsedFormatted: String
    let durationFormatted: String
    let perSubjectResults: [String: (correct: Int, total: Int)]
    let onDismiss: () -> Void

    private var scorePercentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int(Double(correctCount) / Double(totalCount) * 100)
    }

    private var scoreColor: Color {
        switch scorePercentage {
        case 70...: return .resumed.success
        case 50..<70: return .resumed.warning
        default: return .resumed.error
        }
    }

    private var sortedSubjects: [(key: String, value: (correct: Int, total: Int))] {
        perSubjectResults.sorted { $0.value.total > $1.value.total }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Score Header
                    VStack(spacing: Spacing.md) {
                        Text("Resultado do Simulado")
                            .font(.resumed.h3)
                            .foregroundColor(.resumed.white)

                        Text("\(correctCount)/\(totalCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor)

                        Text("\(scorePercentage)%")
                            .font(.resumed.h4)
                            .foregroundColor(scoreColor)

                        // Time
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "clock")
                                .foregroundColor(.resumed.gray)
                            Text("\(elapsedFormatted) / \(durationFormatted)")
                                .font(.resumed.body)
                                .foregroundColor(.resumed.gray)
                        }
                    }
                    .padding(.top, Spacing.xl)

                    // Subject Breakdown
                    if !perSubjectResults.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Desempenho por Matéria")
                                .font(.resumed.h4)
                                .foregroundColor(.resumed.white)

                            ForEach(sortedSubjects, id: \.key) { subject, result in
                                SubjectResultRow(
                                    subject: subject,
                                    correct: result.correct,
                                    total: result.total
                                )
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color.resumed.blackSecondary)
                        .cornerRadius(CornerRadius.lg)
                    }

                    // XP Earned
                    ResumedCard {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.resumed.gold)
                            Text("+\(XPReward.examComplete) XP")
                                .font(.resumed.h4)
                                .foregroundColor(.resumed.gold)
                            Spacer()
                            Text("Simulado completo!")
                                .font(.resumed.bodySmall)
                                .foregroundColor(.resumed.gray)
                        }
                    }

                    // Action Buttons
                    VStack(spacing: Spacing.md) {
                        ResumedButton(
                            title: "Voltar",
                            style: .primary,
                            action: onDismiss,
                            fullWidth: true
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.resumed.black)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Subject Result Row

private struct SubjectResultRow: View {
    let subject: String
    let correct: Int
    let total: Int

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    private var barColor: Color {
        switch percentage {
        case 0.7...: return .resumed.success
        case 0.5..<0.7: return .resumed.warning
        default: return .resumed.error
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(subject)
                    .font(.resumed.bodySmall)
                    .foregroundColor(.resumed.white)
                Spacer()
                Text("\(correct)/\(total) (\(Int(percentage * 100))%)")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.resumed.blackTertiary)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geo.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
