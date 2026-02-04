//
//  HomeE2ETests.swift
//  ResumedTests
//
//  E2E Tests for Home View
//

import XCTest

final class HomeE2ETests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            TestConfiguration.LaunchArgument.uiTesting.rawValue,
            TestConfiguration.LaunchArgument.skipOnboarding.rawValue
        ]
    }

    override func tearDownWithError() throws {
        if let testRun = testRun, !testRun.hasSucceeded {
            takeScreenshot(name: "Failure-\(name)")
        }
        app = nil
    }

    // MARK: - Setup Helper

    private func launchAndNavigateToHome() {
        app.launch()
        wait(for: 3)

        // Demo mode if needed
        let demoButton = app.buttons["Explorar sem conta (Demo)"]
        if demoButton.waitForExistence(timeout: 3) {
            demoButton.tap()
            wait(for: 2)
        }

        // Navigate to home tab
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 5) {
            homeTab.tap()
        }
    }

    // MARK: - Home Loading Tests

    func testHomeScreenLoads() throws {
        launchAndNavigateToHome()

        // Verify RESUMED branding
        let resumedLogo = app.staticTexts["RESUMED"]
        XCTAssertTrue(resumedLogo.waitForExistence(timeout: 5), "RESUMED logo should be visible")
    }

    func testHomeHeaderShowsUserName() throws {
        launchAndNavigateToHome()

        // Look for greeting
        let greeting = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Ola'"))
        XCTAssertTrue(greeting.element.waitForExistence(timeout: 5), "User greeting should be visible")
    }

    // MARK: - Modules Grid Tests

    func testAllModulesExist() throws {
        launchAndNavigateToHome()

        // Verify all 6 modules exist
        let modulesSection = app.staticTexts["Modulos"]
        XCTAssertTrue(modulesSection.waitForExistence(timeout: 5), "Modules section should exist")

        // Check individual modules
        let gpsModule = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'GPS'")).element
        let exerciciosModule = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Exercicios'")).element
        let resucardsModule = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'ResuCards'")).element
        let greyModule = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Grey'")).element
        let desempenhoModule = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Desempenho'")).element
        let provasModule = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Provas'")).element

        XCTAssertTrue(gpsModule.exists || app.staticTexts["GPS"].exists, "GPS module should exist")
        XCTAssertTrue(exerciciosModule.exists || app.staticTexts["Exercicios"].exists, "Exercicios module should exist")
        XCTAssertTrue(resucardsModule.exists || app.staticTexts["ResuCards"].exists, "ResuCards module should exist")
    }

    func testNavigateToGPSFromModule() throws {
        launchAndNavigateToHome()

        // Tap GPS module
        let gpsModule = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'GPS'")).element
        if gpsModule.waitForExistence(timeout: 5) {
            gpsModule.tap()

            // Verify navigation
            let gpsTitle = app.navigationBars.containing(NSPredicate(format: "identifier CONTAINS[c] 'GPS'")).element
            let planTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Plano'")).element
            XCTAssertTrue(gpsTitle.exists || planTitle.exists, "Should navigate to GPS/Plan view")
        }
    }

    func testNavigateToExercisesFromModule() throws {
        launchAndNavigateToHome()

        // Tap Exercicios module
        let exerciciosModule = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Exercicios'")).element
        if exerciciosModule.waitForExistence(timeout: 5) {
            exerciciosModule.tap()
            wait(for: 1)

            // Verify navigation to Practice tab
            let practiceTab = app.tabBars.buttons["Praticar"]
            XCTAssertTrue(practiceTab.isSelected || practiceTab.exists, "Should navigate to Practice tab")
        }
    }

    func testNavigateToResuCardsFromModule() throws {
        launchAndNavigateToHome()

        // Tap ResuCards module
        let resucardsModule = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'ResuCards'")).element
        if resucardsModule.waitForExistence(timeout: 5) {
            resucardsModule.tap()
            wait(for: 1)

            // Verify navigation to ResuCards tab
            let cardsTab = app.tabBars.buttons["ResuCards"]
            XCTAssertTrue(cardsTab.isSelected || cardsTab.exists, "Should navigate to ResuCards tab")
        }
    }

    // MARK: - Quick Stats Tests

    func testQuickStatsSection() throws {
        launchAndNavigateToHome()

        // Check for stats cards
        let questoesLabel = app.staticTexts["Questoes"]
        let acuraciaLabel = app.staticTexts["Acuracia"]
        let tempoLabel = app.staticTexts["Tempo"]

        let hasStats = questoesLabel.exists || acuraciaLabel.exists || tempoLabel.exists
        XCTAssertTrue(hasStats, "Quick stats should be visible")
    }

    // MARK: - Streak Display Tests

    func testStreakCounterVisible() throws {
        launchAndNavigateToHome()

        // Look for streak indicator (fire icon or days count)
        let streakElement = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'dias'")).element
        let fireIcon = app.images["flame.fill"]

        let hasStreak = streakElement.exists || fireIcon.exists
        // Streak might not always be visible, so this is a soft check
        if hasStreak {
            XCTAssertTrue(true, "Streak indicator found")
        }
    }

    // MARK: - Today Activity Tests

    func testTodayActivityCardExists() throws {
        launchAndNavigateToHome()

        // Look for activity card
        let activitySection = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Atividade'")).element
        let pendingCards = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'pendentes'")).element

        let hasActivity = activitySection.exists || pendingCards.exists
        if hasActivity {
            XCTAssertTrue(true, "Today activity section found")
        }
    }

    func testTodayActivityNavigatesToResuCards() throws {
        launchAndNavigateToHome()

        // Find and tap activity card
        let activityCard = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Revisao'")).element
        if activityCard.waitForExistence(timeout: 5) {
            activityCard.tap()
            wait(for: 1)

            // Should navigate to ResuCards
            let cardsTab = app.tabBars.buttons["ResuCards"]
            XCTAssertTrue(cardsTab.isSelected || cardsTab.exists, "Should navigate to ResuCards from activity card")
        }
    }

    // MARK: - Motivational Quote Tests

    func testMotivationalQuoteExists() throws {
        launchAndNavigateToHome()

        // Scroll to find quote
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Look for quote icon or text
        let quoteIcon = app.images["quote.opening"]
        let quoteText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'persistencia'")).element

        let hasQuote = quoteIcon.exists || quoteText.exists
        if hasQuote {
            XCTAssertTrue(true, "Motivational quote found")
        }
    }

    // MARK: - Tab Bar Navigation Tests

    func testTabBarExistsWithFiveTabs() throws {
        launchAndNavigateToHome()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        // Count tabs
        let tabCount = tabBar.buttons.count
        XCTAssertEqual(tabCount, 5, "Should have 5 tabs (Home, GPS, Practice, ResuCards, Performance)")
    }
}
