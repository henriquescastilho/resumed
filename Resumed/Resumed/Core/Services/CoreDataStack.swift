//
//  CoreDataStack.swift
//  Resumed
//
//  Programmatic Core Data Model - No .xcdatamodeld required
//

import Foundation
import CoreData

// MARK: - Core Data Stack with Programmatic Model

class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        // Prefer bundled model when available, fallback to programmatic model.
        let model = NSManagedObjectModel.mergedModel(from: [Bundle.main]) ?? createManagedObjectModel()
        let container = NSPersistentContainer(name: "Resumed", managedObjectModel: model)

        // Configure for lightweight migration
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ Core Data Error: \(error), \(error.userInfo)")
                #if DEBUG
                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
                #else
                // In production, post notification so the app can show an alert
                NotificationCenter.default.post(
                    name: NSNotification.Name("CoreDataLoadFailed"),
                    object: error
                )
                #endif
            } else {
                print("✅ Core Data loaded successfully")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private init() {}

    // MARK: - Programmatic Model Creation

    private func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Create all entities
        let flashCardEntity = createFlashCardEntity()
        let questionEntity = createQuestionEntity()
        let questionHistoryEntity = createQuestionHistoryEntity()
        let studySessionEntity = createStudySessionEntity()
        let userStatsEntity = createUserStatsEntity()
        let offlineQueueEntity = createOfflineQueueEntity()
        let cachedExamEntity = createCachedExamEntity()

        model.entities = [
            flashCardEntity,
            questionEntity,
            questionHistoryEntity,
            studySessionEntity,
            userStatsEntity,
            offlineQueueEntity,
            cachedExamEntity
        ]

        return model
    }

    // MARK: - Entity Definitions

    private func createFlashCardEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDFlashCard"
        entity.managedObjectClassName = NSStringFromClass(CDFlashCard.self)

        var properties: [NSAttributeDescription] = []

        properties.append(createAttribute(name: "id", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "front", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "back", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "subject", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "tags", type: .transformableAttributeType, optional: true, transformerName: NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue))
        properties.append(createAttribute(name: "easeFactor", type: .doubleAttributeType, optional: false, defaultValue: 2.5))
        properties.append(createAttribute(name: "interval", type: .integer32AttributeType, optional: false, defaultValue: 1))
        properties.append(createAttribute(name: "repetitions", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "nextReviewDate", type: .dateAttributeType, optional: false))
        properties.append(createAttribute(name: "createdAt", type: .dateAttributeType, optional: false))
        properties.append(createAttribute(name: "lastReviewedAt", type: .dateAttributeType, optional: true))
        properties.append(createAttribute(name: "isSynced", type: .booleanAttributeType, optional: false, defaultValue: false))

        entity.properties = properties
        return entity
    }

    private func createQuestionEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDQuestion"
        entity.managedObjectClassName = NSStringFromClass(CDQuestion.self)

        var properties: [NSAttributeDescription] = []

        properties.append(createAttribute(name: "id", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "statement", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "optionsData", type: .binaryDataAttributeType, optional: false)) // JSON encoded
        properties.append(createAttribute(name: "correctOptionId", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "explanation", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "subject", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "source", type: .stringAttributeType, optional: true))
        properties.append(createAttribute(name: "difficulty", type: .stringAttributeType, optional: true))
        properties.append(createAttribute(name: "imageURL", type: .stringAttributeType, optional: true))
        properties.append(createAttribute(name: "cachedAt", type: .dateAttributeType, optional: false))

        entity.properties = properties
        return entity
    }

    private func createQuestionHistoryEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDQuestionHistory"
        entity.managedObjectClassName = NSStringFromClass(CDQuestionHistory.self)

        var properties: [NSAttributeDescription] = []

        properties.append(createAttribute(name: "id", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "questionId", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "selectedAnswer", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "isCorrect", type: .booleanAttributeType, optional: false))
        properties.append(createAttribute(name: "subject", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "timeSpentSeconds", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "answeredAt", type: .dateAttributeType, optional: false))
        properties.append(createAttribute(name: "isSynced", type: .booleanAttributeType, optional: false, defaultValue: false))

        entity.properties = properties
        return entity
    }

    private func createStudySessionEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDStudySession"
        entity.managedObjectClassName = NSStringFromClass(CDStudySession.self)

        var properties: [NSAttributeDescription] = []

        properties.append(createAttribute(name: "id", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "type", type: .stringAttributeType, optional: false)) // "questions", "flashcards", "exam"
        properties.append(createAttribute(name: "subject", type: .stringAttributeType, optional: true))
        properties.append(createAttribute(name: "startedAt", type: .dateAttributeType, optional: false))
        properties.append(createAttribute(name: "endedAt", type: .dateAttributeType, optional: true))
        properties.append(createAttribute(name: "durationMinutes", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "questionsAnswered", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "correctAnswers", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "flashcardsReviewed", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "xpEarned", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "isSynced", type: .booleanAttributeType, optional: false, defaultValue: false))

        entity.properties = properties
        return entity
    }

    private func createUserStatsEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDUserStats"
        entity.managedObjectClassName = NSStringFromClass(CDUserStats.self)

        var properties: [NSAttributeDescription] = []

        properties.append(createAttribute(name: "id", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "level", type: .integer32AttributeType, optional: false, defaultValue: 1))
        properties.append(createAttribute(name: "totalXP", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "streak", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "longestStreak", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "totalQuestionsAnswered", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "totalCorrectAnswers", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "totalStudyTimeMinutes", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "totalFlashcardsReviewed", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "totalExamsCompleted", type: .integer32AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "unlockedBadgesData", type: .binaryDataAttributeType, optional: true)) // JSON array
        properties.append(createAttribute(name: "subjectStatsData", type: .binaryDataAttributeType, optional: true)) // JSON dictionary
        properties.append(createAttribute(name: "lastStudyDate", type: .dateAttributeType, optional: true))
        properties.append(createAttribute(name: "updatedAt", type: .dateAttributeType, optional: false))

        entity.properties = properties
        return entity
    }

    private func createOfflineQueueEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDOfflineQueue"
        entity.managedObjectClassName = NSStringFromClass(CDOfflineQueue.self)

        var properties: [NSAttributeDescription] = []

        properties.append(createAttribute(name: "id", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "actionType", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "endpoint", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "method", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "payload", type: .binaryDataAttributeType, optional: true))
        properties.append(createAttribute(name: "createdAt", type: .dateAttributeType, optional: false))
        properties.append(createAttribute(name: "retryCount", type: .integer16AttributeType, optional: false, defaultValue: 0))
        properties.append(createAttribute(name: "lastAttemptAt", type: .dateAttributeType, optional: true))

        entity.properties = properties
        return entity
    }

    private func createCachedExamEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDCachedExam"
        entity.managedObjectClassName = NSStringFromClass(CDCachedExam.self)

        var properties: [NSAttributeDescription] = []

        properties.append(createAttribute(name: "id", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "institution", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "name", type: .stringAttributeType, optional: false))
        properties.append(createAttribute(name: "year", type: .integer32AttributeType, optional: false))
        properties.append(createAttribute(name: "subjects", type: .transformableAttributeType, optional: true, transformerName: NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue))
        properties.append(createAttribute(name: "questionCount", type: .integer32AttributeType, optional: false))
        properties.append(createAttribute(name: "durationMinutes", type: .integer32AttributeType, optional: false))
        properties.append(createAttribute(name: "difficulty", type: .stringAttributeType, optional: true))
        properties.append(createAttribute(name: "questionsData", type: .binaryDataAttributeType, optional: true)) // Cached questions JSON
        properties.append(createAttribute(name: "cachedAt", type: .dateAttributeType, optional: false))

        entity.properties = properties
        return entity
    }

    // MARK: - Helper Methods

    private func createAttribute(
        name: String,
        type: NSAttributeType,
        optional: Bool,
        defaultValue: Any? = nil,
        transformerName: String? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        if let defaultValue = defaultValue {
            attribute.defaultValue = defaultValue
        }
        if let transformerName = transformerName {
            attribute.valueTransformerName = transformerName
        }
        return attribute
    }

    // MARK: - Save Context

    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Core Data Save Error: \(error)")
            }
        }
    }

    func saveAsync() async {
        await viewContext.perform {
            self.save()
        }
    }

    // MARK: - Background Context

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
}
