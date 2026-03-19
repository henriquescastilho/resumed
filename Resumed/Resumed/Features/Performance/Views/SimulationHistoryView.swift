//
//  SimulationHistoryView.swift
//  Resumed
//
//  History of all practice sessions with per-question review
//

import SwiftUI

struct SimulationHistoryView: View {
    @State private var logs: [SimulationLog] = []
    @State private var selectedLog: SimulationLog?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if logs.isEmpty {
                    EmptyState(
                        icon: "doc.text.magnifyingglass",
                        title: "Nenhum registro",
                        subtitle: "Complete uma sessão de questões para ver seu histórico aqui."
                    )
                    .padding(.top, Spacing.xxl)
                } else {
                    // Summary header
                    HStack(spacing: 0) {
                        summaryItem(
                            value: "\(logs.count)",
                            label: "Sessões",
                            icon: "doc.text.fill"
                        )
                        Divider().background(Color.resumed.border).frame(height: 32)
                        summaryItem(
                            value: "\(averageAccuracy)%",
                            label: "Média",
                            icon: "chart.bar.fill"
                        )
                        Divider().background(Color.resumed.border).frame(height: 32)
                        summaryItem(
                            value: "\(totalQuestions)",
                            label: "Questões",
                            icon: "pencil.and.list.clipboard"
                        )
                    }
                    .padding(Spacing.md)
                    .background(Color.resumed.blackSecondary)
                    .cornerRadius(CornerRadius.lg)

                    // Log list
                    ForEach(logs) { log in
                        Button {
                            selectedLog = log
                            HapticManager.shared.selection()
                        } label: {
                            SimulationLogCard(log: log)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    SimulationLogStore.delete(id: log.id)
                                    logs = SimulationLogStore.loadAll()
                                }
                            } label: {
                                Label("Apagar", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
        }
        .background(Color.resumed.black)
        .navigationTitle("Histórico de Sessões")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { logs = SimulationLogStore.loadAll() }
        .sheet(item: $selectedLog) { log in
            NavigationStack {
                SimulationDetailView(log: log)
            }
        }
    }

    private var averageAccuracy: Int {
        guard !logs.isEmpty else { return 0 }
        let total = logs.reduce(0.0) { $0 + $1.accuracy }
        return Int(total / Double(logs.count))
    }

    private var totalQuestions: Int {
        logs.reduce(0) { $0 + $1.totalQuestions }
    }

    private func summaryItem(value: String, label: String, icon: String) -> some View {
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
}

// MARK: - Log Card

struct SimulationLogCard: View {
    let log: SimulationLog

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: log.date, relativeTo: Date())
    }

    private var durationFormatted: String {
        let m = log.durationSeconds / 60
        if m >= 60 {
            return "\(m / 60)h\(String(format: "%02d", m % 60))min"
        }
        return "\(m)min"
    }

    private var accentColor: Color {
        if log.accuracy >= 80 { return .resumed.success }
        if log.accuracy >= 60 { return .resumed.warning }
        return .resumed.error
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: log.mode.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.resumed.gold)
                    .frame(width: 32, height: 32)
                    .background(Color.resumed.gold.opacity(0.12))
                    .cornerRadius(CornerRadius.sm)

                VStack(alignment: .leading, spacing: 2) {
                    Text(log.title)
                        .font(.resumed.body)
                        .fontWeight(.medium)
                        .foregroundColor(.resumed.white)
                        .lineLimit(1)

                    HStack(spacing: Spacing.xs) {
                        Text(log.mode.rawValue)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                        Text("•")
                            .foregroundColor(.resumed.gray)
                        Text(relativeDate)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                }

                Spacer()

                // Score
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(log.accuracy))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                    Text("\(log.correctCount)/\(log.totalQuestions)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
            }

            // Stats row
            HStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.resumed.success)
                    Text("\(log.correctCount)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.resumed.error)
                    Text("\(log.wrongCount)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }

                if log.durationSeconds > 0 {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(.resumed.gray)
                        Text(durationFormatted)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.resumed.gray)
            }
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Detail View

struct SimulationDetailView: View {
    let log: SimulationLog
    @Environment(\.dismiss) var dismiss
    @State private var showingWrong = true

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Score header
                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .stroke(Color.resumed.border, lineWidth: 6)
                            .frame(width: 100, height: 100)
                        Circle()
                            .trim(from: 0, to: CGFloat(log.accuracy / 100))
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(log.accuracy))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.resumed.white)
                    }

                    Text(log.title)
                        .font(.resumed.h3)
                        .foregroundColor(.resumed.white)

                    Text("\(log.mode.rawValue) • \(dateFormatted)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
                .padding(.top, Spacing.md)

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                    detailStat(value: "\(log.correctCount)", label: "Acertos", color: .resumed.success)
                    detailStat(value: "\(log.wrongCount)", label: "Erros", color: .resumed.error)
                    detailStat(value: durationFormatted, label: "Tempo", color: .resumed.gold)
                }

                // Subject breakdown
                if !log.subjectBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Por Matéria")
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)

                        ForEach(log.subjectBreakdown) { result in
                            HStack {
                                Text(result.subject)
                                    .font(.resumed.bodySmall)
                                    .foregroundColor(.resumed.white)
                                    .lineLimit(1)

                                Spacer()

                                Text("\(result.correct)/\(result.total)")
                                    .font(.resumed.caption)
                                    .foregroundColor(.resumed.gray)

                                Text("\(Int(result.accuracy))%")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(result.accuracy >= 70 ? .resumed.success : .resumed.error)
                                    .frame(width: 44, alignment: .trailing)
                            }
                            .padding(Spacing.sm)
                            .background(Color.resumed.blackSecondary)
                            .cornerRadius(CornerRadius.md)
                        }
                    }
                }

                // Questions toggle
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Button {
                            showingWrong = true
                            HapticManager.shared.selection()
                        } label: {
                            Text("Erros (\(log.wrongQuestions.count))")
                                .font(.resumed.bodySmall)
                                .fontWeight(showingWrong ? .bold : .regular)
                                .foregroundColor(showingWrong ? .resumed.error : .resumed.gray)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(showingWrong ? Color.resumed.error.opacity(0.1) : Color.clear)
                                .cornerRadius(CornerRadius.round)
                        }

                        Button {
                            showingWrong = false
                            HapticManager.shared.selection()
                        } label: {
                            Text("Acertos (\(log.correctQuestions.count))")
                                .font(.resumed.bodySmall)
                                .fontWeight(!showingWrong ? .bold : .regular)
                                .foregroundColor(!showingWrong ? .resumed.success : .resumed.gray)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(!showingWrong ? Color.resumed.success.opacity(0.1) : Color.clear)
                                .cornerRadius(CornerRadius.round)
                        }

                        Spacer()
                    }

                    let displayQuestions = showingWrong ? log.wrongQuestions : log.correctQuestions

                    if displayQuestions.isEmpty {
                        Text(showingWrong ? "Nenhum erro! Parabéns!" : "Nenhum acerto registrado.")
                            .font(.resumed.bodySmall)
                            .foregroundColor(.resumed.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, Spacing.lg)
                    } else {
                        ForEach(displayQuestions) { q in
                            QuestionLogRow(question: q, showingWrong: showingWrong)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.resumed.black)
        .navigationTitle("Detalhes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Fechar") { dismiss() }
                    .foregroundColor(.resumed.gray)
            }
        }
    }

    private var scoreColor: Color {
        if log.accuracy >= 80 { return .resumed.success }
        if log.accuracy >= 60 { return .resumed.warning }
        return .resumed.error
    }

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: log.date)
    }

    private var durationFormatted: String {
        let m = log.durationSeconds / 60
        if m >= 60 { return "\(m / 60)h\(String(format: "%02d", m % 60))" }
        return "\(m)min"
    }

    private func detailStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Question Log Row

private struct QuestionLogRow: View {
    let question: QuestionLog
    let showingWrong: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: question.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(question.isCorrect ? .resumed.success : .resumed.error)

                Text(question.subject)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.resumed.gold)

                Spacer()

                if question.timeSpentSeconds > 0 {
                    Text("\(question.timeSpentSeconds)s")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }
            }

            Text(question.enunciado)
                .font(.resumed.bodySmall)
                .foregroundColor(.resumed.white)
                .lineLimit(3)

            if showingWrong, let selected = question.selectedAnswer {
                HStack(spacing: Spacing.sm) {
                    Text("Sua: \(selected)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.error)
                    Text("Correta: \(question.correctAnswer)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.success)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.resumed.blackTertiary)
        .cornerRadius(CornerRadius.md)
    }
}
