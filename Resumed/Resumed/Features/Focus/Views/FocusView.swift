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

                NeuronNetworkCard(
                    completed: manager.totalPomodorosCompleted,
                    maxCount: FocusSessionManager.neuronGoal
                )

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

private struct NeuronNetworkCard: View {
    let completed: Int
    let maxCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Rede de neurônios")
                    .font(.resumed.h4)
                    .foregroundColor(.resumed.white)
                Spacer()
                Text("\(min(completed, maxCount))/\(maxCount)")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }

            NeuronNetworkView(completed: completed, maxCount: maxCount)
                .frame(height: 190)
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

private struct NeuronNetworkView: View {
    let completed: Int
    let maxCount: Int

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let points = generatePoints(count: maxCount, in: size)
            let connections = buildConnections(points: points)
            let activeNodes = Set(0..<min(completed, maxCount))

            Canvas { context, _ in
                for (i, j) in connections {
                    let isActive = activeNodes.contains(i) && activeNodes.contains(j)
                    let path = Path { path in
                        path.move(to: points[i])
                        path.addLine(to: points[j])
                    }
                    let color = Color(red: 0.24, green: 0.62, blue: 1.0, opacity: isActive ? 0.9 : 0.25)
                    context.stroke(path, with: .color(color), lineWidth: isActive ? 1.2 : 0.7)
                }

                for index in points.indices {
                    let isActive = activeNodes.contains(index)
                    let radius: CGFloat = isActive ? 4.2 : 3.0
                    let rect = CGRect(
                        x: points[index].x - radius,
                        y: points[index].y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    let nodeColor = isActive ? Color.white : Color(red: 0.74, green: 0.86, blue: 1.0, opacity: 0.65)
                    context.fill(Path(ellipseIn: rect), with: .color(nodeColor))

                    if isActive {
                        let glowRect = CGRect(
                            x: points[index].x - radius * 2,
                            y: points[index].y - radius * 2,
                            width: radius * 4,
                            height: radius * 4
                        )
                        context.fill(Path(ellipseIn: glowRect), with: .color(Color.white.opacity(0.25)))
                        context.fill(Path(ellipseIn: rect), with: .color(Color.white))
                    }
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    Color(red: 0.05, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.resumed.border.opacity(0.4), lineWidth: 1)
        )
    }

    private func buildConnections(points: [CGPoint]) -> [(Int, Int)] {
        var pairs = Set<String>()
        var result: [(Int, Int)] = []

        for i in points.indices {
            let distances = points.indices
                .filter { $0 != i }
                .map { j in
                    let dx = points[i].x - points[j].x
                    let dy = points[i].y - points[j].y
                    return (j, sqrt(dx * dx + dy * dy))
                }
                .sorted { $0.1 < $1.1 }
                .prefix(3)

            for (j, _) in distances {
                let a = min(i, j)
                let b = max(i, j)
                let key = "\(a)-\(b)"
                if !pairs.contains(key) {
                    pairs.insert(key)
                    result.append((a, b))
                }
            }
        }
        return result
    }

    private func generatePoints(count: Int, in size: CGSize) -> [CGPoint] {
        var generator = SeededRandomNumberGenerator(seed: 42)
        var points: [CGPoint] = []

        for _ in 0..<count {
            let x = CGFloat(Double.random(in: 0.05...0.95, using: &generator)) * size.width
            let y = CGFloat(Double.random(in: 0.08...0.92, using: &generator)) * size.height
            points.append(CGPoint(x: x, y: y))
        }

        return points
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
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
