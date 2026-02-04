//
//  EmptyState.swift
//  Resumed
//
//  Design System - State Components
//

import SwiftUI

// MARK: - Empty State

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    let actionTitle: String?

    init(
        icon: String,
        title: String,
        subtitle: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.resumed.gold.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.resumed.gold)
            }

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.resumed.h3)
                    .foregroundColor(.resumed.white)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            if let action = action, let actionTitle = actionTitle {
                ResumedButton(
                    title: actionTitle,
                    style: .primary,
                    action: action
                )
            }

            Spacer()
        }
        .padding(Spacing.md)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String

    init(message: String = "Carregando...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .resumed.gold))
                .scaleEffect(1.5)

            Text(message)
                .font(.resumed.body)
                .foregroundColor(.resumed.gray)

            Spacer()
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.resumed.error)

            VStack(spacing: Spacing.sm) {
                Text("Ops!")
                    .font(.resumed.h3)
                    .foregroundColor(.resumed.white)

                Text(message)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gray)
                    .multilineTextAlignment(.center)
            }

            ResumedButton(
                title: "Tentar novamente",
                style: .primary,
                action: retryAction,
                icon: "arrow.clockwise"
            )

            Spacer()
        }
        .padding(Spacing.md)
    }
}

// MARK: - Success State

struct SuccessState: View {
    let title: String
    let subtitle: String
    let xpEarned: Int
    let action: () -> Void
    let actionTitle: String

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Celebration icon
            ZStack {
                Circle()
                    .fill(Color.resumed.success.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.resumed.success)
            }

            // Text
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.resumed.h2)
                    .foregroundColor(.resumed.white)

                Text(subtitle)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gray)
                    .multilineTextAlignment(.center)
            }

            // XP Earned
            if xpEarned > 0 {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.resumed.gold)

                    Text("+\(xpEarned) XP")
                        .font(.resumed.h3)
                        .foregroundColor(.resumed.gold)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.resumed.gold.opacity(0.1))
                .cornerRadius(CornerRadius.round)
            }

            Spacer()

            ResumedButton(
                title: actionTitle,
                style: .primary,
                action: action,
                fullWidth: true
            )
        }
        .padding(Spacing.md)
    }
}

// MARK: - XP Badge

struct XPBadge: View {
    let xp: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(.resumed.gold)

            Text("+\(xp)")
                .font(.resumed.caption)
                .fontWeight(.bold)
                .foregroundColor(.resumed.gold)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.resumed.gold.opacity(0.1))
        .cornerRadius(CornerRadius.round)
    }
}
