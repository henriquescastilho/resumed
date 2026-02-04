//
//  ResumedTypography.swift
//  Resumed
//
//  Design System - Typography
//

import SwiftUI

// MARK: - Font Extension

extension Font {
    static let resumed = ResumedTypography()
}

// MARK: - Resumed Typography

struct ResumedTypography {
    // Headers
    let h1 = Font.system(size: 32, weight: .bold, design: .default)
    let h2 = Font.system(size: 24, weight: .bold, design: .default)
    let h3 = Font.system(size: 20, weight: .semibold, design: .default)
    let h4 = Font.system(size: 18, weight: .semibold, design: .default)

    // Body
    let body = Font.system(size: 16, weight: .regular, design: .default)
    let bodyMedium = Font.system(size: 16, weight: .medium, design: .default)
    let bodySmall = Font.system(size: 14, weight: .regular, design: .default)

    // Caption
    let caption = Font.system(size: 12, weight: .regular, design: .default)
    let captionMedium = Font.system(size: 12, weight: .medium, design: .default)

    // Special
    let stat = Font.system(size: 28, weight: .bold, design: .rounded)
    let statSmall = Font.system(size: 20, weight: .bold, design: .rounded)
    let button = Font.system(size: 16, weight: .semibold, design: .default)
    let tabBar = Font.system(size: 10, weight: .medium, design: .default)
}

// MARK: - Text Styles

extension View {
    func headingStyle() -> some View {
        self
            .font(.resumed.h2)
            .foregroundColor(.resumed.white)
    }

    func bodyStyle() -> some View {
        self
            .font(.resumed.body)
            .foregroundColor(.resumed.white)
    }

    func captionStyle() -> some View {
        self
            .font(.resumed.caption)
            .foregroundColor(.resumed.gray)
    }

    func goldAccent() -> some View {
        self.foregroundColor(.resumed.gold)
    }
}
