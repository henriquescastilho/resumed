//
//  ProgressBar.swift
//  Resumed
//
//  Design System - Progress Components
//

import SwiftUI

// MARK: - Progress Bar

struct ProgressBar: View {
    let current: Int
    let total: Int
    let showLabel: Bool
    let color: Color

    init(current: Int, total: Int, showLabel: Bool = true, color: Color = .resumed.gold) {
        self.current = current
        self.total = total
        self.showLabel = showLabel
        self.color = color
    }

    var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(current) / Double(total), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if showLabel {
                HStack {
                    Text("\(current)/\(total)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.resumed.caption)
                        .foregroundColor(color)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.resumed.blackTertiary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - XP Progress Bar

struct XPProgressBar: View {
    let currentXP: Int
    let totalXP: Int
    let level: Int

    var progress: Double {
        guard totalXP > 0 else { return 0 }
        return min(Double(currentXP) / Double(totalXP), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("\(currentXP) / \(totalXP) XP")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)

                Spacer()

                Text("Level \(level + 1)")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.resumed.blackTertiary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.resumed.gold, .resumed.goldLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let showPercentage: Bool
    let color: Color

    init(
        progress: Double,
        size: CGFloat = 60,
        lineWidth: CGFloat = 6,
        showPercentage: Bool = true,
        color: Color = .resumed.gold
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
        self.color = color
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.resumed.blackTertiary, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.resumed.bodySmall)
                    .fontWeight(.bold)
                    .foregroundColor(.resumed.white)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Streak Display

struct StreakDisplay: View {
    let streak: Int
    let size: StreakSize

    enum StreakSize {
        case small
        case medium
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }

        var font: Font {
            switch self {
            case .small: return .resumed.caption
            case .medium: return .resumed.body
            case .large: return .resumed.h4
            }
        }
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "flame.fill")
                .font(.system(size: size.iconSize))
                .foregroundColor(.orange)

            Text("\(streak)")
                .font(size.font)
                .fontWeight(.bold)
                .foregroundColor(.resumed.white)

            if size == .large {
                Text("dias")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }
        }
        .padding(.horizontal, size == .small ? Spacing.sm : Spacing.md)
        .padding(.vertical, size == .small ? Spacing.xs : Spacing.sm)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(CornerRadius.round)
    }
}
