//
//  ExamTimerView.swift
//  Resumed
//
//  Exam timer for practice
//

import SwiftUI

struct ExamTimerView: View {
    let exam: Exam
    @Environment(\.dismiss) var dismiss

    @State private var remainingSeconds: Int
    @State private var isRunning = false
    @State private var isFinished = false
    @State private var timer: Timer?

    @State private var correctAnswers = 0
    @State private var wrongAnswers = 0

    init(exam: Exam) {
        self.exam = exam
        _remainingSeconds = State(initialValue: exam.durationMinutes * 60)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Text(exam.name)
                    .font(.resumed.h3)
                    .foregroundColor(.resumed.white)
                    .multilineTextAlignment(.center)

                Text(timeString)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.resumed.gold)
                    .monospacedDigit()

                HStack(spacing: Spacing.md) {
                    if !isRunning {
                        ResumedButton(title: "Iniciar", style: .primary, action: start)
                    } else {
                        ResumedButton(title: "Pausar", style: .ghost, action: pause)
                    }

                    ResumedButton(title: "Parar", style: .ghost, action: stop)
                }

                if isFinished {
                    ResultEntryCard(
                        totalQuestions: exam.questionCount,
                        correctAnswers: $correctAnswers,
                        wrongAnswers: $wrongAnswers
                    )

                    ResumedButton(title: "Salvar resultado", style: .primary, action: saveResult)
                }

                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .background(Color.resumed.black)
            .navigationTitle("Simulado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
            .onDisappear { timer?.invalidate() }
        }
    }

    private var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func start() {
        guard !isFinished else { return }
        isRunning = true
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                }
                if remainingSeconds <= 0 {
                    finish()
                }
            }
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func stop() {
        pause()
        remainingSeconds = exam.durationMinutes * 60
    }

    private func finish() {
        pause()
        isFinished = true
        HapticManager.shared.success()
    }

    private func saveResult() {
        let total = max(exam.questionCount, 0)
        let correct = max(min(correctAnswers, total), 0)
        _ = max(min(wrongAnswers, total - correct), 0)

        ProgressTracker.shared.recordExamResult(totalQuestions: total, correctAnswers: correct)
        GamificationManager.shared.recordExamComplete(accuracy: total > 0 ? (Double(correct) / Double(total)) * 100 : 0)

        HapticManager.shared.notification(.success)
        dismiss()
    }
}

private struct ResultEntryCard: View {
    let totalQuestions: Int
    @Binding var correctAnswers: Int
    @Binding var wrongAnswers: Int

    var body: some View {
        ResumedCard {
            VStack(spacing: Spacing.md) {
                Text("Resultados")
                    .font(.resumed.h4)
                    .foregroundColor(.resumed.white)

                Stepper(value: $correctAnswers, in: 0...totalQuestions) {
                    Text("Acertos: \(correctAnswers)")
                        .font(.resumed.body)
                        .foregroundColor(.resumed.white)
                }

                Stepper(value: $wrongAnswers, in: 0...totalQuestions) {
                    Text("Erros: \(wrongAnswers)")
                        .font(.resumed.body)
                        .foregroundColor(.resumed.white)
                }

                Text("Total: \(totalQuestions)")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }
        }
    }
}
