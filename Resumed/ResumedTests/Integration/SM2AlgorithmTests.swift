//
//  SM2AlgorithmTests.swift
//  ResumedTests
//
//  Integration Tests for SM-2 Spaced Repetition Algorithm
//

import XCTest
@testable import Resumed

final class SM2AlgorithmTests: XCTestCase {

    // MARK: - Initial State Tests

    func testNewCardHasDefaultValues() throws {
        let card = FlashCard(
            front: "Test Question",
            back: "Test Answer",
            subject: "Test"
        )

        XCTAssertEqual(card.easinessFactor, 2.5, "Default easiness factor should be 2.5")
        XCTAssertEqual(card.interval, 0, "Default interval should be 0")
        XCTAssertEqual(card.repetitions, 0, "Default repetitions should be 0")
    }

    // MARK: - Easiness Factor Tests

    func testEasinessFactorIncreasesWithFacil() throws {
        var card = FlashCard(
            front: "Test",
            back: "Answer",
            subject: "Test"
        )
        let initialEF = card.easinessFactor

        SM2Algorithm.applyReview(to: &card, quality: .facil)

        XCTAssertGreaterThan(card.easinessFactor, initialEF, "EF should increase for 'Facil' rating")
    }

    func testEasinessFactorDecreasesWithErrei() throws {
        var card = FlashCard(
            front: "Test",
            back: "Answer",
            subject: "Test"
        )
        let initialEF = card.easinessFactor

        SM2Algorithm.applyReview(to: &card, quality: .errei)

        XCTAssertLessThanOrEqual(card.easinessFactor, initialEF, "EF should decrease or stay same for 'Errei' rating")
    }

    func testEasinessFactorNeverBelowMinimum() throws {
        var card = FlashCard(
            id: "test",
            front: "Test",
            back: "Answer",
            subject: "Test",
            easinessFactor: 1.5 // Start with low EF
        )

        // Apply multiple "Errei" ratings
        for _ in 0..<10 {
            SM2Algorithm.applyReview(to: &card, quality: .errei)
        }

        XCTAssertGreaterThanOrEqual(card.easinessFactor, 1.3, "EF should never go below 1.3")
    }

    // MARK: - Interval Progression Tests

    func testFirstReviewSetsIntervalToOne() throws {
        var card = FlashCard(
            front: "Test",
            back: "Answer",
            subject: "Test"
        )

        SM2Algorithm.applyReview(to: &card, quality: .bom)

        XCTAssertEqual(card.interval, 1, "First review should set interval to 1 day")
        XCTAssertEqual(card.repetitions, 1, "Repetitions should increment to 1")
    }

    func testSecondReviewSetsIntervalToSix() throws {
        var card = FlashCard(
            id: "test",
            front: "Test",
            back: "Answer",
            subject: "Test",
            easinessFactor: 2.5,
            interval: 1,
            repetitions: 1
        )

        SM2Algorithm.applyReview(to: &card, quality: .bom)

        XCTAssertEqual(card.interval, 6, "Second review should set interval to 6 days")
        XCTAssertEqual(card.repetitions, 2, "Repetitions should increment to 2")
    }

    func testSubsequentReviewsUseEasinessMultiplier() throws {
        var card = FlashCard(
            id: "test",
            front: "Test",
            back: "Answer",
            subject: "Test",
            easinessFactor: 2.5,
            interval: 6,
            repetitions: 2
        )

        SM2Algorithm.applyReview(to: &card, quality: .bom)

        // Interval should be approximately 6 * 2.5 = 15
        XCTAssertGreaterThan(card.interval, 6, "Interval should increase based on EF")
        XCTAssertEqual(card.repetitions, 3, "Repetitions should increment")
    }

    // MARK: - Reset on Error Tests

    func testErreiResetsRepetitions() throws {
        var card = FlashCard(
            id: "test",
            front: "Test",
            back: "Answer",
            subject: "Test",
            easinessFactor: 2.5,
            interval: 30,
            repetitions: 5
        )

        SM2Algorithm.applyReview(to: &card, quality: .errei)

        XCTAssertEqual(card.repetitions, 0, "'Errei' should reset repetitions to 0")
        XCTAssertEqual(card.interval, 1, "'Errei' should reset interval to 1")
    }

    // MARK: - Next Review Date Tests

    func testNextReviewDateIsSet() throws {
        var card = FlashCard(
            front: "Test",
            back: "Answer",
            subject: "Test"
        )
        let beforeReview = Date()

        SM2Algorithm.applyReview(to: &card, quality: .bom)

        XCTAssertGreaterThan(card.nextReviewDate, beforeReview, "Next review date should be in the future")
    }

    func testNextReviewDateMatchesInterval() throws {
        var card = FlashCard(
            front: "Test",
            back: "Answer",
            subject: "Test"
        )

        SM2Algorithm.applyReview(to: &card, quality: .bom)

        // Next review should be approximately 1 day from now
        let expectedDate = Calendar.current.date(byAdding: .day, value: card.interval, to: Date())!
        let tolerance: TimeInterval = 60 // 1 minute tolerance

        XCTAssertEqual(
            card.nextReviewDate.timeIntervalSince1970,
            expectedDate.timeIntervalSince1970,
            accuracy: tolerance,
            "Next review date should match interval"
        )
    }

    // MARK: - Quality Mapping Tests

    func testQualityEnumValues() throws {
        XCTAssertEqual(SM2Algorithm.Quality.errei.rawValue, 0)
        XCTAssertEqual(SM2Algorithm.Quality.dificil.rawValue, 1)
        XCTAssertEqual(SM2Algorithm.Quality.bom.rawValue, 2)
        XCTAssertEqual(SM2Algorithm.Quality.facil.rawValue, 3)
    }

    func testQualityDisplayNames() throws {
        XCTAssertEqual(SM2Algorithm.Quality.errei.displayName, "Errei")
        XCTAssertEqual(SM2Algorithm.Quality.dificil.displayName, "Difícil")
        XCTAssertEqual(SM2Algorithm.Quality.bom.displayName, "Bom")
        XCTAssertEqual(SM2Algorithm.Quality.facil.displayName, "Fácil")
    }

    // MARK: - XP Reward Tests

    func testXPRewardsForQualities() throws {
        // These values depend on implementation
        let erreiXP = SM2Algorithm.Quality.errei.xpReward
        let dificilXP = SM2Algorithm.Quality.dificil.xpReward
        let bomXP = SM2Algorithm.Quality.bom.xpReward
        let facilXP = SM2Algorithm.Quality.facil.xpReward

        // XP should increase with better ratings
        XCTAssertLessThanOrEqual(erreiXP, dificilXP, "Errei XP <= Dificil XP")
        XCTAssertLessThanOrEqual(dificilXP, bomXP, "Dificil XP <= Bom XP")
        XCTAssertLessThanOrEqual(bomXP, facilXP, "Bom XP <= Facil XP")
    }

    // MARK: - Long Term Progression Tests

    func testLongTermIntervalProgression() throws {
        var card = FlashCard(
            front: "Test",
            back: "Answer",
            subject: "Test"
        )

        var intervals: [Int] = []

        // Simulate 10 successful reviews
        for _ in 0..<10 {
            SM2Algorithm.applyReview(to: &card, quality: .bom)
            intervals.append(card.interval)
        }

        // Intervals should generally increase
        for i in 1..<intervals.count {
            XCTAssertGreaterThanOrEqual(
                intervals[i],
                intervals[i-1],
                "Intervals should increase over time with consistent good reviews"
            )
        }
    }

    func testMixedQualityProgression() throws {
        var card = FlashCard(
            front: "Test",
            back: "Answer",
            subject: "Test"
        )

        // Good review
        SM2Algorithm.applyReview(to: &card, quality: .bom)
        let afterGood = card.interval

        // Difficult review
        SM2Algorithm.applyReview(to: &card, quality: .dificil)
        let afterDifficult = card.interval

        // After difficult, interval might be shorter due to lower EF
        XCTAssertGreaterThanOrEqual(afterDifficult, afterGood, "Should still progress after difficult")

        // Error should reset
        SM2Algorithm.applyReview(to: &card, quality: .errei)
        XCTAssertEqual(card.interval, 1, "Errei should reset interval")
    }

    // MARK: - Edge Cases

    func testEmptyCardContent() throws {
        var card = FlashCard(
            front: "",
            back: "",
            subject: ""
        )

        // Should still work with empty content
        SM2Algorithm.applyReview(to: &card, quality: .bom)

        XCTAssertEqual(card.repetitions, 1, "Algorithm should work with empty content")
    }

    func testUnicodeContent() throws {
        var card = FlashCard(
            front: "O que sao os criterios de Hipertensao Arterial?",
            back: "PA >= 140/90 mmHg em medicoes repetidas",
            subject: "Cardiologia"
        )

        SM2Algorithm.applyReview(to: &card, quality: .facil)

        XCTAssertEqual(card.repetitions, 1, "Algorithm should handle Portuguese content")
    }
}
