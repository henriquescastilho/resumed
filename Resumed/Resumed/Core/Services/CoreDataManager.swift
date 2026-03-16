//
//  CoreDataManager.swift
//  Resumed
//
//  Core Service - Core Data Persistence Manager
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        CoreDataStack.shared.persistentContainer
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private init() {}

    // MARK: - Save Context

    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("CoreData Save Error: \(error)")
            }
        }
    }

    @MainActor
    func saveAsync() async {
        save()
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

    // MARK: - FlashCard Operations

    func saveFlashCard(_ card: FlashCard) {
        let entity = CDFlashCard(context: viewContext)
        entity.id = card.id
        entity.front = card.front
        entity.back = card.back
        entity.subject = card.subject
        entity.tags = card.tags as NSArray
        entity.easeFactor = card.easinessFactor
        entity.interval = Int32(card.interval)
        entity.repetitions = Int32(card.repetitions)
        entity.nextReviewDate = card.nextReviewDate
        entity.createdAt = Date()
        entity.lastReviewedAt = card.lastReviewDate
        entity.isSynced = false
        save()
    }

    func fetchFlashCards(subject: String? = nil) -> [FlashCard] {
        let request = NSFetchRequest<CDFlashCard>(entityName: "CDFlashCard")

        if let subject = subject {
            request.predicate = NSPredicate(format: "subject == %@", subject)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDFlashCard.nextReviewDate, ascending: true)]

        do {
            let entities = try viewContext.fetch(request)
            return entities.map { $0.toFlashCard() }
        } catch {
            print("Fetch FlashCards Error: \(error)")
            return []
        }
    }

    func fetchFlashCard(id: String) -> FlashCard? {
        let request = NSFetchRequest<CDFlashCard>(entityName: "CDFlashCard")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first?.toFlashCard()
        } catch {
            print("Fetch FlashCard by id Error: \(error)")
            return nil
        }
    }

    func saveOrUpdateFlashCard(_ card: FlashCard) {
        let request = NSFetchRequest<CDFlashCard>(entityName: "CDFlashCard")
        request.predicate = NSPredicate(format: "id == %@", card.id)
        request.fetchLimit = 1

        do {
            if let entity = try viewContext.fetch(request).first {
                entity.update(from: card)
                save()
            } else {
                saveFlashCard(card)
            }
        } catch {
            print("SaveOrUpdate FlashCard Error: \(error)")
        }
    }

    func fetchDueFlashCards() -> [FlashCard] {
        let request = NSFetchRequest<CDFlashCard>(entityName: "CDFlashCard")
        request.predicate = NSPredicate(format: "nextReviewDate <= %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDFlashCard.nextReviewDate, ascending: true)]

        do {
            let entities = try viewContext.fetch(request)
            return entities.map { $0.toFlashCard() }
        } catch {
            print("Fetch Due FlashCards Error: \(error)")
            return []
        }
    }

    func updateFlashCard(_ card: FlashCard) {
        let request = NSFetchRequest<CDFlashCard>(entityName: "CDFlashCard")
        request.predicate = NSPredicate(format: "id == %@", card.id)

        do {
            if let entity = try viewContext.fetch(request).first {
                entity.easeFactor = card.easinessFactor
                entity.interval = Int32(card.interval)
                entity.repetitions = Int32(card.repetitions)
                entity.nextReviewDate = card.nextReviewDate
                entity.lastReviewedAt = card.lastReviewDate
                entity.isSynced = false
                save()
            }
        } catch {
            print("Update FlashCard Error: \(error)")
        }
    }

    func deleteFlashCard(_ card: FlashCard) {
        let request = NSFetchRequest<CDFlashCard>(entityName: "CDFlashCard")
        request.predicate = NSPredicate(format: "id == %@", card.id)

        do {
            if let entity = try viewContext.fetch(request).first {
                viewContext.delete(entity)
                save()
            }
        } catch {
            print("Delete FlashCard Error: \(error)")
        }
    }

    // MARK: - Question History Operations

    func saveQuestionAnswer(questionId: String, selectedAnswer: String, isCorrect: Bool, subject: String, timeSpentSeconds: Int = 0) {
        let entity = CDQuestionHistory(context: viewContext)
        entity.id = UUID().uuidString
        entity.questionId = questionId
        entity.selectedAnswer = selectedAnswer
        entity.isCorrect = isCorrect
        entity.subject = subject
        entity.answeredAt = Date()
        entity.timeSpentSeconds = Int32(timeSpentSeconds)
        entity.isSynced = false
        save()
    }

    func fetchQuestionHistory(subject: String? = nil, limit: Int = 100) -> [CDQuestionHistory] {
        let request = NSFetchRequest<CDQuestionHistory>(entityName: "CDQuestionHistory")

        if let subject = subject {
            request.predicate = NSPredicate(format: "subject == %@", subject)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDQuestionHistory.answeredAt, ascending: false)]
        request.fetchLimit = limit

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch Question History Error: \(error)")
            return []
        }
    }

    func fetchSubjectsWithHistory() -> [String] {
        let request = NSFetchRequest<NSDictionary>(entityName: "CDQuestionHistory")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["subject"]
        request.returnsDistinctResults = true

        do {
            let results = try viewContext.fetch(request)
            let subjects = results.compactMap { $0["subject"] as? String }
            return Array(Set(subjects)).sorted()
        } catch {
            print("Fetch Subjects Error: \(error)")
            return []
        }
    }

    func getAccuracy(subject: String? = nil) -> Double {
        let history = fetchQuestionHistory(subject: subject, limit: 1000)
        guard !history.isEmpty else { return 0 }

        let correct = history.filter { $0.isCorrect }.count
        return Double(correct) / Double(history.count) * 100
    }

    // MARK: - Offline Queue Operations

    func queueOfflineAction(_ action: OfflineAction) {
        let entity = CDOfflineQueue(context: viewContext)
        entity.id = UUID().uuidString
        entity.actionType = action.type.rawValue
        entity.endpoint = ""
        entity.method = "POST"
        entity.payload = try? JSONEncoder().encode(action.payload)
        entity.createdAt = Date()
        entity.retryCount = 0
        save()
    }

    func fetchPendingOfflineActions() -> [CDOfflineQueue] {
        let request = NSFetchRequest<CDOfflineQueue>(entityName: "CDOfflineQueue")
        request.predicate = NSPredicate(format: "retryCount < 3")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDOfflineQueue.createdAt, ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch Offline Queue Error: \(error)")
            return []
        }
    }

    func removeOfflineAction(_ entity: CDOfflineQueue) {
        viewContext.delete(entity)
        save()
    }

    // MARK: - Clear All Data

    func clearAllData() {
        let entities = ["CDFlashCard", "CDQuestionHistory", "CDOfflineQueue", "CDUserStats", "CDStudySession", "CDCachedExam"]

        for entityName in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try viewContext.execute(deleteRequest) as? NSBatchDeleteResult
                let objectIDs = result?.result as? [NSManagedObjectID] ?? []
                // Merge batch delete into in-memory context so objects don't linger
                if !objectIDs.isEmpty {
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                        into: [viewContext]
                    )
                }
            } catch {
                print("Clear \(entityName) Error: \(error)")
            }
        }
    }
}

// MARK: - Offline Action Model

struct OfflineAction: Codable {
    enum ActionType: String, Codable {
        case syncFlashCard
        case syncQuestionAnswer
        case syncProgress
    }

    let type: ActionType
    let payload: [String: String]
}

// Note: Core Data entities are defined programmatically in CoreDataStack.swift
