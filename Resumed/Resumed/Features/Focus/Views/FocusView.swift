//
//  FocusView.swift
//  Resumed
//
//  Pomodoro Focus View
//

import SwiftUI

struct FocusView: View {
    @StateObject private var manager = FocusSessionManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.resumed.black.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                FocusHeader(remaining: manager.remainingSeconds, phase: manager.phase)

                if manager.pomodorosCompletedToday >= 4 && manager.pomodorosCompletedToday < 8 {
                    FocusBanner(text: "Pausa recomendada. Seu foco rende mais com descanso.")
                }

                if manager.isLimitReached {
                    FocusBanner(text: "Limite diário atingido. Volte amanhã.")
                }

                FocusDurationControls(
                    focusMinutes: Binding(
                        get: { manager.focusDurationSeconds / 60 },
                        set: { manager.focusDurationSeconds = $0 * 60 }
                    ),
                    breakMinutes: Binding(
                        get: { manager.breakDurationSeconds / 60 },
                        set: { manager.breakDurationSeconds = $0 * 60 }
                    ),
                    isDisabled: manager.isRunning
                )

                FocusControls(
                    isRunning: manager.isRunning,
                    isPaused: manager.isPaused,
                    isLimitReached: manager.isLimitReached,
                    onStart: { manager.start() },
                    onPause: { manager.pause() },
                    onResume: { manager.resume() },
                    onStop: { manager.stop() }
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
        }
        .navigationTitle("Foco")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                manager.pause()
            }
        }
    }
}

private struct FocusHeader: View {
    let remaining: Int
    let phase: FocusSessionManager.Phase

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(phase == .focus ? "Foco" : "Pausa")
                .font(.resumed.h3)
                .foregroundColor(.resumed.gold)

            Text(timeString)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(.resumed.white)
                .monospacedDigit()
        }
    }

    private var timeString: String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct FocusDurationControls: View {
    @Binding var focusMinutes: Int
    @Binding var breakMinutes: Int
    let isDisabled: Bool

    var body: some View {
        VStack(spacing: Spacing.md) {
            DurationRow(
                title: "Foco",
                value: focusMinutes,
                range: 10...90
            ) { focusMinutes = $0 }

            DurationRow(
                title: "Pausa",
                value: breakMinutes,
                range: 5...30
            ) { breakMinutes = $0 }
        }
        .opacity(isDisabled ? 0.6 : 1)
        .disabled(isDisabled)
    }
}

private struct DurationRow: View {
    let title: String
    let value: Int
    let range: ClosedRange<Int>
    let onChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.white)

                Spacer()

                Text("\(value) min")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { onChange(Int($0)) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(.resumed.gold)
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

private struct FocusControls: View {
    let isRunning: Bool
    let isPaused: Bool
    let isLimitReached: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            if !isRunning {
                ResumedButton(
                    title: "Iniciar",
                    style: .primary,
                    action: onStart,
                    icon: "play.fill",
                    isDisabled: isLimitReached
                )
            } else if isPaused {
                ResumedButton(
                    title: "Retomar",
                    style: .primary,
                    action: onResume,
                    icon: "play.fill"
                )
            } else {
                ResumedButton(
                    title: "Pausar",
                    style: .ghost,
                    action: onPause,
                    icon: "pause.fill"
                )
            }

            if isRunning {
                ResumedButton(
                    title: "Parar",
                    style: .ghost,
                    action: onStop
                )
            }
        }
    }
}

private struct FocusBanner: View {
    let text: String

    var body: some View {
        HStack {
            Image(systemName: "leaf.fill")
                .foregroundColor(.resumed.gold)
            Text(text)
                .font(.resumed.bodySmall)
                .foregroundColor(.resumed.white)
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
    }
}
