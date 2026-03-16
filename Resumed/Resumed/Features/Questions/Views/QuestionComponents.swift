//
//  QuestionComponents.swift
//  Resumed
//
//  Shared UI for question sessions
//

import SwiftUI

struct QuestionCard: View {
    let question: Question
    let selectedOptionId: String?
    let isAnswered: Bool
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(question.subject)
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gold)
                Spacer()
            }

            Text(question.statement)
                .font(.resumed.body)
                .foregroundColor(.resumed.white)

            VStack(spacing: Spacing.sm) {
                ForEach(question.options) { option in
                    QuestionOptionRow(
                        option: option,
                        isSelected: selectedOptionId == option.id,
                        isAnswered: isAnswered,
                        isCorrect: option.id == question.correctOptionId,
                        onSelect: { onSelect(option.id) }
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal, Spacing.md)
    }
}

struct QuestionOptionRow: View {
    let option: QuestionOption
    let isSelected: Bool
    let isAnswered: Bool
    let isCorrect: Bool
    let onSelect: () -> Void

    var borderColor: Color {
        if !isAnswered { return isSelected ? .resumed.gold : .resumed.border }
        if isCorrect { return .resumed.success }
        if isSelected { return .resumed.error }
        return .resumed.border
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Text(option.id.uppercased())
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
                Text(option.text)
                    .font(.resumed.bodySmall)
                    .foregroundColor(.resumed.white)
                Spacer()
            }
            .padding(Spacing.sm)
            .background(Color.resumed.blackTertiary)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .disabled(isAnswered)
    }
}

struct FeedbackCard: View {
    let isCorrect: Bool
    let explanation: String
    let socialMessage: String

    private var trimmedExplanation: String {
        let maxChars = 320
        guard explanation.count > maxChars else { return explanation }
        return String(explanation.prefix(maxChars)) + "…"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack(spacing: Spacing.xs) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .resumed.success : .resumed.error)
                Text(isCorrect ? "Resposta certa!" : "Resposta incorreta")
                    .font(.resumed.h4)
                    .foregroundColor(isCorrect ? .resumed.success : .resumed.error)
            }

            // Explanation — only on wrong answers
            if !isCorrect, !explanation.isEmpty {
                Divider()
                    .background(Color.resumed.border)

                Text("Explicação")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gold)

                Text(trimmedExplanation)
                    .font(.resumed.bodySmall)
                    .foregroundColor(.resumed.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Social message — only when non-empty
            if !socialMessage.isEmpty {
                Text(socialMessage)
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }
        }
        .padding(Spacing.md)
        .background(
            (isCorrect ? Color.resumed.success : Color.resumed.error)
                .opacity(0.08)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    isCorrect ? Color.resumed.success : Color.resumed.error,
                    lineWidth: 1
                )
        )
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal, Spacing.md)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
