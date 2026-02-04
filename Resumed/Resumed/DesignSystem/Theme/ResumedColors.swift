//
//  ResumedColors.swift
//  Resumed
//
//  Design System - Color Palette
//

import SwiftUI

// MARK: - Color Extension

extension Color {
    static let resumed = ResumedColors()
}

// MARK: - Resumed Colors

struct ResumedColors {
    // Primary
    let gold = Color(hex: "FFD700")
    let goldLight = Color(hex: "FFE55C")
    let goldDark = Color(hex: "D4AF37")

    // Backgrounds
    let black = Color(hex: "000000")
    let blackSecondary = Color(hex: "1A1A1A")
    let blackTertiary = Color(hex: "2A2A2A")

    // Text
    let white = Color(hex: "FFFFFF")
    let gray = Color(hex: "888888")
    let grayLight = Color(hex: "AAAAAA")
    let grayDark = Color(hex: "666666")

    // Semantic
    let success = Color(hex: "10B981")
    let error = Color(hex: "EF4444")
    let warning = Color(hex: "F59E0B")
    let info = Color(hex: "3B82F6")

    // Borders
    let border = Color(hex: "333333")
    let borderLight = Color(hex: "444444")

    // Subject Colors
    let clinicaMedica = Color(hex: "3B82F6")  // Blue
    let cirurgia = Color(hex: "EF4444")        // Red
    let pediatria = Color(hex: "10B981")       // Green
    let ginecologia = Color(hex: "EC4899")     // Pink
    let preventiva = Color(hex: "8B5CF6")      // Purple
    let outras = Color(hex: "6B7280")          // Gray
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
