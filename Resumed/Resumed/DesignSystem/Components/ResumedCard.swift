//
//  ResumedCard.swift
//  Resumed
//
//  Design System - Card Components
//

import SwiftUI

// MARK: - Resumed Card

struct ResumedCard<Content: View>: View {
    let background: Color
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        background: Color = Color.resumed.blackSecondary,
        padding: CGFloat = Spacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.background = background
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(background)
            .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String?
    let trend: String?
    let trendPositive: Bool

    init(title: String, value: String, icon: String? = nil, trend: String? = nil, trendPositive: Bool = true) {
        self.title = title
        self.value = value
        self.icon = icon
        self.trend = trend
        self.trendPositive = trendPositive
    }

    var body: some View {
        ResumedCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: IconSize.md))
                            .foregroundColor(.resumed.gold)
                    }

                    Text(title)
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }

                HStack(alignment: .bottom, spacing: Spacing.xs) {
                    Text(value)
                        .font(.resumed.stat)
                        .foregroundColor(.resumed.white)

                    if let trend = trend {
                        Text(trend)
                            .font(.resumed.caption)
                            .foregroundColor(trendPositive ? .resumed.success : .resumed.error)
                    }
                }
            }
        }
    }
}

// MARK: - Module Card

struct ModuleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ResumedCard {
                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.resumed.gold.opacity(0.1))
                            .frame(width: 48, height: 48)

                        Image(systemName: icon)
                            .font(.system(size: IconSize.lg))
                            .foregroundColor(.resumed.gold)
                    }

                    VStack(spacing: Spacing.xs) {
                        Text(title)
                            .font(.resumed.bodyMedium)
                            .foregroundColor(.resumed.white)

                        Text(subtitle)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ResumedCard {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.resumed.gold.opacity(0.1))
                            .frame(width: 56, height: 56)

                        Image(systemName: icon)
                            .font(.system(size: IconSize.lg))
                            .foregroundColor(.resumed.gold)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(title)
                            .font(.resumed.bodyMedium)
                            .foregroundColor(.resumed.white)

                        Text(subtitle)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: IconSize.sm))
                        .foregroundColor(.resumed.gray)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
