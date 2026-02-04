//
//  ResumedButton.swift
//  Resumed
//
//  Design System - Button Components
//

import SwiftUI

// MARK: - Button Style

enum ResumedButtonStyle {
    case primary
    case secondary
    case ghost
    case danger

    var backgroundColor: Color {
        switch self {
        case .primary: return .resumed.gold
        case .secondary: return .resumed.blackSecondary
        case .ghost: return .clear
        case .danger: return .resumed.error
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary: return .resumed.black
        case .secondary: return .resumed.gold
        case .ghost: return .resumed.gold
        case .danger: return .resumed.white
        }
    }

    var borderColor: Color {
        switch self {
        case .secondary: return .resumed.gold
        case .ghost: return .clear
        default: return .clear
        }
    }
}

// MARK: - Button Size

enum ResumedButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        }
    }

    var font: Font {
        switch self {
        case .small: return .resumed.bodySmall
        case .medium: return .resumed.body
        case .large: return .resumed.button
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
}

// MARK: - Resumed Button

struct ResumedButton: View {
    let title: String
    let style: ResumedButtonStyle
    let action: () -> Void
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let fullWidth: Bool
    let size: ResumedButtonSize

    init(
        title: String,
        style: ResumedButtonStyle = .primary,
        action: @escaping () -> Void,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        fullWidth: Bool = false,
        size: ResumedButtonSize = .medium
    ) {
        self.title = title
        self.style = style
        self.action = action
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.size = size
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize))
                    }
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, Spacing.lg)
            .background(style.backgroundColor)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(style.borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Chip Button

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.resumed.bodySmall)
                .foregroundColor(isSelected ? .resumed.black : .resumed.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.resumed.gold : Color.resumed.blackSecondary)
                .cornerRadius(CornerRadius.round)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.round)
                        .stroke(isSelected ? Color.clear : Color.resumed.border, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let action: () -> Void
    let size: CGFloat
    let color: Color

    init(icon: String, action: @escaping () -> Void, size: CGFloat = 44, color: Color = .resumed.gold) {
        self.icon = icon
        self.action = action
        self.size = size
        self.color = color
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(color.opacity(0.1))
                .cornerRadius(size / 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Rating Button (for SM-2)

struct RatingButton: View {
    let quality: SM2Algorithm.Quality
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                // SF Symbol icon ao invés de emoji
                Image(systemName: quality.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(quality.color)

                Text(quality.displayName)
                    .font(.resumed.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.resumed.white)

                // Mostrar XP reward
                Text("+\(quality.xpReward) XP")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(quality.color.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)  // Aumentado para facilitar toque
            .background(quality.color.opacity(0.15))
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(quality.color, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
