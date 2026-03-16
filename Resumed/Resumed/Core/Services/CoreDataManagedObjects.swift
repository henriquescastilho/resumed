//
//  CoreDataManagedObjects.swift
//  Resumed
//
//  NSManagedObject subclasses for programmatic Core Data entities.
//  Required because CoreDataStack defines entities programmatically
//  and sets managedObjectClassName to these class names.
//

import Foundation
import CoreData

// MARK: - CDFlashCard

@objc(CDFlashCard)
public class CDFlashCard: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var front: String?
    @NSManaged public var back: String?
    @NSManaged public var subject: String?
    @NSManaged public var tags: NSObject?
    @NSManaged public var easeFactor: Double
    @NSManaged public var interval: Int32
    @NSManaged public var repetitions: Int32
    @NSManaged public var nextReviewDate: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastReviewedAt: Date?
    @NSManaged public var isSynced: Bool
}

// MARK: - CDQuestion

@objc(CDQuestion)
public class CDQuestion: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var statement: String?
    @NSManaged public var optionsData: Data?
    @NSManaged public var correctOptionId: String?
    @NSManaged public var explanation: String?
    @NSManaged public var subject: String?
    @NSManaged public var source: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var cachedAt: Date?
}

// MARK: - CDQuestionHistory

@objc(CDQuestionHistory)
public class CDQuestionHistory: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var questionId: String?
    @NSManaged public var selectedAnswer: String?
    @NSManaged public var isCorrect: Bool
    @NSManaged public var subject: String?
    @NSManaged public var timeSpentSeconds: Int32
    @NSManaged public var answeredAt: Date?
    @NSManaged public var isSynced: Bool
}

// MARK: - CDStudySession

@objc(CDStudySession)
public class CDStudySession: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var type: String?
    @NSManaged public var subject: String?
    @NSManaged public var startedAt: Date?
    @NSManaged public var endedAt: Date?
    @NSManaged public var durationMinutes: Int32
    @NSManaged public var questionsAnswered: Int32
    @NSManaged public var correctAnswers: Int32
    @NSManaged public var flashcardsReviewed: Int32
    @NSManaged public var xpEarned: Int32
    @NSManaged public var isSynced: Bool
}

// MARK: - CDUserStats

@objc(CDUserStats)
public class CDUserStats: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var level: Int32
    @NSManaged public var totalXP: Int32
    @NSManaged public var streak: Int32
    @NSManaged public var longestStreak: Int32
    @NSManaged public var totalQuestionsAnswered: Int32
    @NSManaged public var totalCorrectAnswers: Int32
    @NSManaged public var totalStudyTimeMinutes: Int32
    @NSManaged public var totalFlashcardsReviewed: Int32
    @NSManaged public var totalExamsCompleted: Int32
    @NSManaged public var unlockedBadgesData: Data?
    @NSManaged public var subjectStatsData: Data?
    @NSManaged public var lastStudyDate: Date?
    @NSManaged public var updatedAt: Date?
}

// MARK: - CDOfflineQueue

@objc(CDOfflineQueue)
public class CDOfflineQueue: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var actionType: String?
    @NSManaged public var endpoint: String?
    @NSManaged public var method: String?
    @NSManaged public var payload: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var retryCount: Int16
    @NSManaged public var lastAttemptAt: Date?
}

// MARK: - CDCachedExam

@objc(CDCachedExam)
public class CDCachedExam: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var institution: String?
    @NSManaged public var name: String?
    @NSManaged public var year: Int32
    @NSManaged public var subjects: NSObject?
    @NSManaged public var questionCount: Int32
    @NSManaged public var durationMinutes: Int32
    @NSManaged public var difficulty: String?
    @NSManaged public var questionsData: Data?
    @NSManaged public var cachedAt: Date?
}
