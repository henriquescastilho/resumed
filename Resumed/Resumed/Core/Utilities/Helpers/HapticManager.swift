//
//  HapticManager.swift
//  Resumed
//
//  Utility - Haptic Feedback Manager
//

import UIKit

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    func success() {
        notification(.success)
    }

    func error() {
        notification(.error)
    }

    func warning() {
        notification(.warning)
    }

    func celebration() {
        impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.medium)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.impact(.light)
        }
    }

    func levelUp() {
        impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.notification(.success)
        }
    }

    func cardFlip() {
        impact(.light)
    }
}
