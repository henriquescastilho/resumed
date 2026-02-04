//
//  TestHelpers.swift
//  ResumedTests
//
//  Test Utilities and Extensions
//

import XCTest

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Check if element is selected
    var isSelected: Bool {
        return (value as? String) == "1"
    }

    /// Tap element if it exists
    func tapIfExists() {
        if exists {
            tap()
        }
    }

    /// Wait for element and tap
    func waitForExistenceAndTap(timeout: TimeInterval = 5) {
        if waitForExistence(timeout: timeout) {
            tap()
        }
    }

    /// Check if element contains text
    func containsText(_ text: String) -> Bool {
        return label.contains(text)
    }

    /// Swipe to element
    func swipeToElement(_ element: XCUIElement, direction: SwipeDirection = .up, maxSwipes: Int = 5) {
        var count = 0
        while !element.exists && count < maxSwipes {
            switch direction {
            case .up:
                swipeUp()
            case .down:
                swipeDown()
            case .left:
                swipeLeft()
            case .right:
                swipeRight()
            }
            count += 1
        }
    }

    enum SwipeDirection {
        case up, down, left, right
    }
}

// MARK: - XCTestCase Extensions

extension XCTestCase {
    /// Wait for a specific duration
    func wait(for duration: TimeInterval) {
        let waitExpectation = expectation(description: "Waiting for \(duration) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            waitExpectation.fulfill()
        }
        waitForExpectations(timeout: duration + 1)
    }

    /// Take screenshot and attach to test report
    func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Verify element exists with custom message
    func assertExists(_ element: XCUIElement, message: String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(element.exists, message.isEmpty ? "Element should exist" : message, file: file, line: line)
    }

    /// Verify element does not exist
    func assertNotExists(_ element: XCUIElement, message: String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(element.exists, message.isEmpty ? "Element should not exist" : message, file: file, line: line)
    }
}

// MARK: - Test App Configuration

struct TestConfiguration {
    static let defaultTimeout: TimeInterval = 5
    static let animationTimeout: TimeInterval = 1
    static let networkTimeout: TimeInterval = 10

    /// Launch arguments for UI testing
    enum LaunchArgument: String {
        case uiTesting = "UI-TESTING"
        case mockFlashcards = "MOCK_FLASHCARDS"
        case mockQuestions = "MOCK_QUESTIONS"
        case newUser = "NEW_USER"
        case skipOnboarding = "SKIP_ONBOARDING"
        case resetState = "RESET_STATE"
    }

    /// Launch environments
    enum LaunchEnvironment: String {
        case isNewUser = "IS_NEW_USER"
        case mockAPIDelay = "MOCK_API_DELAY"
        case disableAnimations = "DISABLE_ANIMATIONS"
    }
}

// MARK: - Accessibility Identifiers

struct AccessibilityID {
    // Tab Bar
    static let tabBarHome = "tab-home"
    static let tabBarExercises = "tab-exercises"
    static let tabBarResuCards = "tab-resucards"
    static let tabBarPerformance = "tab-performance"

    // Home
    static let homeHeader = "home-header"
    static let xpProgressBar = "xp-progress-bar"
    static let streakCounter = "streak-counter"
    static let dailyChallenge = "daily-challenge"
    static let modulesGrid = "modules-grid"

    // ResuCards
    static let flashcardView = "flashcard-view"
    static let flashcardFront = "flashcard-front"
    static let flashcardBack = "flashcard-back"
    static let ratingButtonErrei = "rating-errei"
    static let ratingButtonDificil = "rating-dificil"
    static let ratingButtonBom = "rating-bom"
    static let ratingButtonFacil = "rating-facil"
    static let xpBadge = "xp-badge"
    static let progressBar = "cards-progress-bar"

    // Exercises
    static let filterButton = "filter-button"
    static let questionCard = "question-card"
    static let subjectChip = "subject-chip"

    // Performance
    static let radarChart = "radar-chart"
    static let lineChart = "line-chart"
    static let periodSelector = "period-selector"
    static let tabBySubject = "tab-by-subject"
    static let tabByPeriod = "tab-by-period"
}
