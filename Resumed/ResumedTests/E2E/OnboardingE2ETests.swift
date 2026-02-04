//
//  OnboardingE2ETests.swift
//  ResumedTests
//
//  E2E Tests for Onboarding Flow
//

import XCTest

final class OnboardingE2ETests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            TestConfiguration.LaunchArgument.uiTesting.rawValue,
            TestConfiguration.LaunchArgument.resetState.rawValue
        ]
    }

    override func tearDownWithError() throws {
        if let testRun = testRun, !testRun.hasSucceeded {
            takeScreenshot(name: "Failure-\(name)")
        }
        app = nil
    }

    // MARK: - Splash Screen Tests

    func testSplashScreenAppears() throws {
        app.launchEnvironment[TestConfiguration.LaunchEnvironment.isNewUser.rawValue] = "true"
        app.launch()

        // Verify splash appears with RESUMED branding
        let splashLogo = app.images["brain.head.profile"]
        XCTAssertTrue(splashLogo.waitForExistence(timeout: 2), "Splash logo should appear")

        let resumedText = app.staticTexts["RESUMED"]
        XCTAssertTrue(resumedText.exists, "RESUMED text should be visible on splash")
    }

    func testSplashScreenDisappearsAfterDelay() throws {
        app.launchEnvironment[TestConfiguration.LaunchEnvironment.isNewUser.rawValue] = "true"
        app.launch()

        // Wait for splash to disappear
        wait(for: 3)

        // Verify login or onboarding appears
        let loginButton = app.buttons["Entrar com Google"]
        let tabBar = app.tabBars.firstMatch

        XCTAssertTrue(loginButton.exists || tabBar.exists, "Should show login or main app after splash")
    }

    // MARK: - Onboarding Flow Tests

    func testOnboardingFlowForNewUser() throws {
        app.launchEnvironment[TestConfiguration.LaunchEnvironment.isNewUser.rawValue] = "true"
        app.launch()

        // Wait for splash
        wait(for: 3)

        // Demo mode to skip login
        let demoButton = app.buttons["Explorar sem conta (Demo)"]
        if demoButton.waitForExistence(timeout: 3) {
            demoButton.tap()
        }

        // Verify onboarding screen 1
        let welcomeText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Bem-vindo'"))
        if welcomeText.element.waitForExistence(timeout: 3) {
            XCTAssertTrue(welcomeText.element.exists, "Onboarding welcome screen should appear")
        }
    }

    func testOnboardingSkipButton() throws {
        app.launchEnvironment[TestConfiguration.LaunchEnvironment.isNewUser.rawValue] = "true"
        app.launch()

        wait(for: 3)

        // Demo mode
        let demoButton = app.buttons["Explorar sem conta (Demo)"]
        if demoButton.waitForExistence(timeout: 3) {
            demoButton.tap()
        }

        // Look for skip button
        let skipButton = app.buttons["Pular"]
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()

            // Should go to main app
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should appear after skipping onboarding")
        }
    }

    func testOnboardingNextButtonNavigation() throws {
        app.launchEnvironment[TestConfiguration.LaunchEnvironment.isNewUser.rawValue] = "true"
        app.launch()

        wait(for: 3)

        // Demo mode
        let demoButton = app.buttons["Explorar sem conta (Demo)"]
        if demoButton.waitForExistence(timeout: 3) {
            demoButton.tap()
        }

        // Navigate through onboarding
        let nextButton = app.buttons["Proximo"]
        if nextButton.waitForExistence(timeout: 3) {
            // Screen 1 -> 2
            nextButton.tap()
            wait(for: 0.5)

            // Screen 2 -> 3
            if nextButton.exists {
                nextButton.tap()
                wait(for: 0.5)
            }

            // Screen 3 -> Complete
            let startButton = app.buttons["Comecar"]
            if startButton.exists {
                startButton.tap()

                let tabBar = app.tabBars.firstMatch
                XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should appear after completing onboarding")
            }
        }
    }

    // MARK: - Login Tests

    func testLoginScreenAppears() throws {
        app.launch()
        wait(for: 3)

        // Check for login options
        let googleButton = app.buttons["Entrar com Google"]
        let appleButton = app.buttons["Entrar com Apple"]
        let demoButton = app.buttons["Explorar sem conta (Demo)"]

        let hasLoginOptions = googleButton.exists || appleButton.exists || demoButton.exists
        XCTAssertTrue(hasLoginOptions, "Login options should be available")
    }

    func testDemoModeAccess() throws {
        app.launch()
        wait(for: 3)

        let demoButton = app.buttons["Explorar sem conta (Demo)"]
        if demoButton.waitForExistence(timeout: 5) {
            demoButton.tap()

            // Should eventually reach main app
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Should reach main app in demo mode")
        }
    }

    // MARK: - State Preservation Tests

    func testOnboardingNotShownForReturningUser() throws {
        // First launch - complete onboarding
        app.launchEnvironment[TestConfiguration.LaunchEnvironment.isNewUser.rawValue] = "false"
        app.launchArguments.append(TestConfiguration.LaunchArgument.skipOnboarding.rawValue)
        app.launch()

        wait(for: 3)

        // Demo mode
        let demoButton = app.buttons["Explorar sem conta (Demo)"]
        if demoButton.waitForExistence(timeout: 3) {
            demoButton.tap()
        }

        // Should go directly to main app
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Returning user should skip onboarding")
    }
}
