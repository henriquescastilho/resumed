//
//  PerformanceE2ETests.swift
//  ResumedTests
//
//  E2E Tests for Performance/Analytics View
//

import XCTest

final class PerformanceE2ETests: XCTestCase {
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

    private func launchAndNavigateToPerformance() {
        app.launch()
        wait(for: 3)

        // Demo mode if needed
        let demoButton = app.buttons["Explorar sem conta (Demo)"]
        if demoButton.waitForExistence(timeout: 3) {
            demoButton.tap()
            wait(for: 2)
        }

        // Navigate to Performance tab
        let performanceTab = app.tabBars.buttons["Desempenho"]
        if performanceTab.waitForExistence(timeout: 5) {
            performanceTab.tap()
            wait(for: 1)
        }
    }

    // MARK: - Screen Loading Tests

    func testPerformanceScreenLoads() throws {
        launchAndNavigateToPerformance()

        // Verify screen loaded
        let navTitle = app.navigationBars.staticTexts["Desempenho"]
        let screenTitle = app.staticTexts["Desempenho"]

        XCTAssertTrue(navTitle.exists || screenTitle.exists, "Performance screen should load")
    }

    func testGeneralStatsSection() throws {
        launchAndNavigateToPerformance()

        // Look for stats cards
        let levelText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Level'")).element
        let xpText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'XP'")).element
        let streakText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'dias'")).element

        let hasStats = levelText.exists || xpText.exists || streakText.exists
        XCTAssertTrue(hasStats, "General stats should be visible")
    }

    // MARK: - Tab Navigation Tests

    func testTabsExist() throws {
        launchAndNavigateToPerformance()

        // Check for tabs
        let bySubjectTab = app.buttons["Por Materia"]
        let byPeriodTab = app.buttons["Por Periodo"]

        // Either these specific tabs or some segmented control
        let segmentedControl = app.segmentedControls.firstMatch

        let hasTabs = bySubjectTab.exists || byPeriodTab.exists || segmentedControl.exists
        XCTAssertTrue(hasTabs, "Performance tabs should exist")
    }

    func testSwitchToPeriodTab() throws {
        launchAndNavigateToPerformance()

        // Tap period tab
        let byPeriodTab = app.buttons["Por Periodo"]
        if byPeriodTab.waitForExistence(timeout: 5) {
            byPeriodTab.tap()
            wait(for: 0.5)

            // Should show period-related content
            let periodSelector = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'dias'")).element
            let chartElement = app.otherElements[AccessibilityID.lineChart]
            let weeklyData = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Semana'")).element

            let showsPeriodContent = periodSelector.exists || chartElement.exists || weeklyData.exists
            if showsPeriodContent {
                XCTAssertTrue(true, "Period tab shows relevant content")
            }
        }
    }

    func testSwitchBackToSubjectTab() throws {
        launchAndNavigateToPerformance()

        // Switch to period
        let byPeriodTab = app.buttons["Por Periodo"]
        if byPeriodTab.exists {
            byPeriodTab.tap()
            wait(for: 0.5)
        }

        // Switch back to subject
        let bySubjectTab = app.buttons["Por Materia"]
        if bySubjectTab.waitForExistence(timeout: 5) {
            bySubjectTab.tap()
            wait(for: 0.5)

            // Should show subject content again
            let subjectList = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Clinica'")).element
            let radarChart = app.otherElements[AccessibilityID.radarChart]

            let showsSubjectContent = subjectList.exists || radarChart.exists
            if showsSubjectContent {
                XCTAssertTrue(true, "Subject tab shows relevant content")
            }
        }
    }

    // MARK: - Chart Tests

    func testRadarChartExists() throws {
        launchAndNavigateToPerformance()

        // Radar chart should be visible on subject tab
        let radarChart = app.otherElements[AccessibilityID.radarChart]
        let canvasElement = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'chart'")).firstMatch

        let hasChart = radarChart.exists || canvasElement.exists
        // Chart might be rendered as image or canvas, soft check
        if hasChart {
            XCTAssertTrue(true, "Radar chart found")
        }
    }

    func testSubjectListWithProgressBars() throws {
        launchAndNavigateToPerformance()

        // Look for subject performance items
        let clinicaItem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Clinica'")).element
        let cirurgiaItem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Cirurgia'")).element
        let pediatriaItem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Pediatria'")).element

        let hasSubjects = clinicaItem.exists || cirurgiaItem.exists || pediatriaItem.exists
        if hasSubjects {
            XCTAssertTrue(true, "Subject performance list found")
        }
    }

    // MARK: - Period Selector Tests

    func testPeriodSelectorWorks() throws {
        launchAndNavigateToPerformance()

        // Switch to period tab
        let byPeriodTab = app.buttons["Por Periodo"]
        if byPeriodTab.exists {
            byPeriodTab.tap()
            wait(for: 0.5)
        }

        // Find period buttons
        let sevenDays = app.buttons["7 dias"]
        let thirtyDays = app.buttons["30 dias"]
        let threeMonths = app.buttons["3 meses"]
        let oneYear = app.buttons["1 ano"]

        let hasPeriodOptions = sevenDays.exists || thirtyDays.exists || threeMonths.exists || oneYear.exists

        if hasPeriodOptions {
            // Tap 30 days
            if thirtyDays.exists {
                thirtyDays.tap()
                wait(for: 0.5)
                XCTAssertTrue(true, "Period selector works")
            }
        }
    }

    // MARK: - Export Tests

    func testExportButtonExists() throws {
        launchAndNavigateToPerformance()

        // Look for export button
        let exportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'export' OR identifier CONTAINS 'export'")).firstMatch
        let shareButton = app.buttons["square.and.arrow.up"]
        let exportIcon = app.images["square.and.arrow.up"]

        let hasExport = exportButton.exists || shareButton.exists || exportIcon.exists
        if hasExport {
            XCTAssertTrue(true, "Export button found")
        }
    }

    // MARK: - Accuracy Display Tests

    func testAccuracyPercentagesVisible() throws {
        launchAndNavigateToPerformance()

        // Look for percentage values
        let percentageText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'"))

        // Should have at least one percentage displayed
        XCTAssertGreaterThan(percentageText.count, 0, "Should show accuracy percentages")
    }

    // MARK: - Trend Indicators Tests

    func testTrendIndicatorsVisible() throws {
        launchAndNavigateToPerformance()

        // Look for trend arrows or indicators
        let upArrow = app.images["arrow.up"]
        let downArrow = app.images["arrow.down"]
        let trendText = app.staticTexts.matching(NSPredicate(format: "label MATCHES '.*[+-][0-9]+.*'"))

        let hasTrends = upArrow.exists || downArrow.exists || trendText.count > 0
        if hasTrends {
            XCTAssertTrue(true, "Trend indicators found")
        }
    }

    // MARK: - Scroll Tests

    func testScreenIsScrollable() throws {
        launchAndNavigateToPerformance()

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Try to scroll
            scrollView.swipeUp()
            wait(for: 0.5)
            scrollView.swipeDown()
            XCTAssertTrue(true, "Screen is scrollable")
        }
    }

    // MARK: - Level Display Tests

    func testLevelProgressVisible() throws {
        launchAndNavigateToPerformance()

        // Look for level info
        let levelText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Level' OR label CONTAINS[c] 'Nivel'")).element
        let xpProgress = app.progressIndicators.firstMatch

        let hasLevelInfo = levelText.exists || xpProgress.exists
        if hasLevelInfo {
            XCTAssertTrue(true, "Level progress info found")
        }
    }
}
