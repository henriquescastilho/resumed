//
//  Spacing.swift
//  Resumed
//
//  Design System - Spacing & Layout Constants
//

import SwiftUI

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 24
    static let round: CGFloat = 100
}

// MARK: - Icon Sizes

enum IconSize {
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Layout

enum Layout {
    static var tabBarHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 0 : 80
    }
    static let navBarHeight: CGFloat = 44
    static let buttonHeight: CGFloat = 52
    static let inputHeight: CGFloat = 48
    static let cardMinHeight: CGFloat = 80
    static let avatarSizeSmall: CGFloat = 32
    static let avatarSizeMedium: CGFloat = 44
    static let avatarSizeLarge: CGFloat = 64
}

// MARK: - Animation Durations

enum AnimationDuration {
    static let quick: Double = 0.15
    static let standard: Double = 0.3
    static let slow: Double = 0.5
}

// MARK: - Device Type

enum DeviceType {
    case iPhone
    case iPadPortrait
    case iPadLandscape

    static var current: DeviceType {
        let idiom = UIDevice.current.userInterfaceIdiom
        if idiom == .pad {
            let orientation = UIDevice.current.orientation
            return orientation.isLandscape ? .iPadLandscape : .iPadPortrait
        }
        return .iPhone
    }

    var maxContentWidth: CGFloat {
        switch self {
        case .iPhone: return .infinity
        case .iPadPortrait: return 600
        case .iPadLandscape: return 800
        }
    }
}
