# 05. Data Flow & State Management - RESUMED iOS

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                        Views                             │
│  (SwiftUI - Declarative UI, @Published bindings)        │
└───────────────────┬─────────────────────────────────────┘
                    │
                    │ User Actions
                    ▼
┌─────────────────────────────────────────────────────────┐
│                     ViewModels                           │
│  (@MainActor - UI updates, business logic)              │
└───────────────────┬─────────────────────────────────────┘
                    │
                    │ API Calls / Data Requests
                    ▼
┌─────────────────────────────────────────────────────────┐
│                   Data Layer                             │
│  ├─ APIClient (Network requests)                        │
│  ├─ CoreDataManager (Local persistence)                 │
│  └─ CacheManager (Temporary caching)                    │
└─────────────────────────────────────────────────────────┘
```

## State Management Strategy

### 1. Local State (@State)

Para UI simples e temporária:

```swift
struct QuestionView: View {
    @State private var selectedOption: Int? = nil
    @State private var isAnswerRevealed = false
    @State private var showExplanation = false

    var body: some View {
        VStack {
            // UI que depende desses estados
        }
    }
}
```

**Quando usar:**
- Estados de UI temporários (expandido/colapsado, selecionado, etc)
- Animações e transições
- Formulários simples
- Estados que não precisam persistir

### 2. Shared State (@StateObject / @ObservedObject)

Para dados compartilhados entre views:

```swift
@MainActor
class StudySessionViewModel: ObservableObject {
    @Published var currentQuestion: Question?
    @Published var questionsAnswered: Int = 0
    @Published var correctAnswers: Int = 0
    @Published var isLoading = false
    @Published var error: Error?

    private let apiClient = APIClient.shared
    private let coreDataManager = CoreDataManager.shared

    func loadNextQuestion() async {
        isLoading = true
        defer { isLoading = false }

        do {
            currentQuestion = try await apiClient.request(
                endpoint: "/study/next-question",
                method: .get
            )
        } catch {
            self.error = error
        }
    }

    func submitAnswer(_ optionId: Int) async {
        guard let question = currentQuestion else { return }

        do {
            let result: AnswerResult = try await apiClient.request(
                endpoint: "/study/answer",
                method: .post,
                body: AnswerRequest(questionId: question.id, optionId: optionId)
            )

            if result.isCorrect {
                correctAnswers += 1
            }
            questionsAnswered += 1

            // Save to Core Data
            await coreDataManager.saveAnswer(
                questionId: question.id,
                isCorrect: result.isCorrect
            )

        } catch {
            self.error = error
        }
    }
}

// Usage
struct StudyView: View {
    @StateObject private var viewModel = StudySessionViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                LoadingView()
            } else if let question = viewModel.currentQuestion {
                QuestionCard(question: question) { optionId in
                    Task {
                        await viewModel.submitAnswer(optionId)
                    }
                }
            }
        }
        .task {
            await viewModel.loadNextQuestion()
        }
    }
}
```

**Quando usar:**
- ViewModels que gerenciam lógica de negócio
- Estados compartilhados entre múltiplas views
- Dados que requerem sincronização com API
- Fluxos com múltiplas etapas

### 3. Environment Objects (@EnvironmentObject)

Para estados globais acessíveis em toda a hierarquia:

```swift
@MainActor
class AppState: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var userStats: UserStats?
    @Published var studyPlan: StudyPlan?

    func signIn(with credential: AuthCredential) async throws {
        // Auth logic
        self.user = try await AuthManager.shared.signIn(credential)
        self.isAuthenticated = true
        await loadUserData()
    }

    func signOut() async {
        await AuthManager.shared.signOut()
        self.user = nil
        self.isAuthenticated = false
        self.userStats = nil
        self.studyPlan = nil
    }

    private func loadUserData() async {
        async let stats = APIClient.shared.request(
            endpoint: "/user/stats",
            method: .get
        ) as UserStats

        async let plan = APIClient.shared.request(
            endpoint: "/study-plan",
            method: .get
        ) as StudyPlan

        do {
            (self.userStats, self.studyPlan) = try await (stats, plan)
        } catch {
            print("Error loading user data: \(error)")
        }
    }
}

// Injection no root
@main
struct ResumedApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

// Usage em qualquer view
struct HomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            if let user = appState.user {
                Text("Olá, \(user.name)")
            }
        }
    }
}
```

**Quando usar:**
- User session (autenticação, perfil)
- Configurações globais (tema, idioma)
- Estados que precisam ser acessados em muitas views
- Dependency injection

## Core Data Integration

### Entity Definitions

```swift
// Question+CoreDataClass.swift
@objc(Question)
public class Question: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var text: String
    @NSManaged public var subject: String
    @NSManaged public var options: Data  // JSON encoded
    @NSManaged public var correctOption: Int
    @NSManaged public var explanation: String?
    @NSManaged public var difficulty: String
    @NSManaged public var lastReviewed: Date?
    @NSManaged public var nextReview: Date?
    @NSManaged public var reviewCount: Int
    @NSManaged public var correctCount: Int
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

// FlashCard+CoreDataClass.swift
@objc(FlashCard)
public class FlashCard: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var front: String
    @NSManaged public var back: String
    @NSManaged public var subject: String
    @NSManaged public var tags: Data  // [String] encoded
    @NSManaged public var lastReviewed: Date?
    @NSManaged public var nextReview: Date
    @NSManaged public var easinessFactor: Double
    @NSManaged public var interval: Int  // days
    @NSManaged public var repetitions: Int
    @NSManaged public var createdAt: Date
}

// StudySession+CoreDataClass.swift
@objc(StudySession)
public class StudySession: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date?
    @NSManaged public var questionsAnswered: Int
    @NSManaged public var correctAnswers: Int
    @NSManaged public var xpEarned: Int
    @NSManaged public var subject: String?
}
```

### Core Data Manager

```swift
@MainActor
class CoreDataManager {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Resumed")

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - CRUD Operations

    func saveContext() {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    // MARK: - Questions

    func saveQuestion(_ questionDTO: QuestionDTO) async throws {
        let question = Question(context: context)
        question.id = questionDTO.id
        question.text = questionDTO.text
        question.subject = questionDTO.subject
        question.options = try JSONEncoder().encode(questionDTO.options)
        question.correctOption = questionDTO.correctOption
        question.explanation = questionDTO.explanation
        question.difficulty = questionDTO.difficulty
        question.createdAt = Date()
        question.updatedAt = Date()

        saveContext()
    }

    func fetchQuestionsDueForReview() async throws -> [Question] {
        let request = Question.fetchRequest()
        request.predicate = NSPredicate(
            format: "nextReview <= %@",
            Date() as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "nextReview", ascending: true)
        ]

        return try context.fetch(request)
    }

    func updateQuestionReview(
        questionId: String,
        isCorrect: Bool
    ) async throws {
        let request = Question.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", questionId)

        guard let question = try context.fetch(request).first else {
            throw CoreDataError.questionNotFound
        }

        question.lastReviewed = Date()
        question.reviewCount += 1

        if isCorrect {
            question.correctCount += 1
        }

        // Spaced Repetition Algorithm
        let newInterval = calculateNextInterval(
            currentInterval: question.interval,
            isCorrect: isCorrect
        )

        question.nextReview = Calendar.current.date(
            byAdding: .day,
            value: newInterval,
            to: Date()
        )

        saveContext()
    }

    private func calculateNextInterval(currentInterval: Int, isCorrect: Bool) -> Int {
        if isCorrect {
            return max(1, currentInterval * 2)
        } else {
            return 1  // Reset to 1 day if wrong
        }
    }

    // MARK: - FlashCards

    func saveFlashCard(_ cardDTO: FlashCardDTO) async throws {
        let card = FlashCard(context: context)
        card.id = cardDTO.id
        card.front = cardDTO.front
        card.back = cardDTO.back
        card.subject = cardDTO.subject
        card.tags = try JSONEncoder().encode(cardDTO.tags)
        card.nextReview = Date()
        card.easinessFactor = 2.5
        card.interval = 1
        card.repetitions = 0
        card.createdAt = Date()

        saveContext()
    }

    func fetchFlashCardsDueForReview() async throws -> [FlashCard] {
        let request = FlashCard.fetchRequest()
        request.predicate = NSPredicate(
            format: "nextReview <= %@",
            Date() as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "nextReview", ascending: true)
        ]

        return try context.fetch(request)
    }

    func updateFlashCardReview(
        cardId: String,
        quality: Int  // 0-3 (Errei, Difícil, Bom, Fácil)
    ) async throws {
        let request = FlashCard.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", cardId)

        guard let card = try context.fetch(request).first else {
            throw CoreDataError.flashCardNotFound
        }

        card.lastReviewed = Date()

        // SM-2 Algorithm
        let (newEF, newInterval, newReps) = calculateSM2(
            quality: quality,
            easinessFactor: card.easinessFactor,
            interval: card.interval,
            repetitions: card.repetitions
        )

        card.easinessFactor = newEF
        card.interval = newInterval
        card.repetitions = newReps
        card.nextReview = Calendar.current.date(
            byAdding: .day,
            value: newInterval,
            to: Date()
        )!

        saveContext()
    }

    // SM-2 Spaced Repetition Algorithm
    private func calculateSM2(
        quality: Int,
        easinessFactor: Double,
        interval: Int,
        repetitions: Int
    ) -> (Double, Int, Int) {
        var newEF = easinessFactor
        var newInterval = interval
        var newReps = repetitions

        // Update easiness factor
        newEF = max(1.3, newEF + (0.1 - (3 - Double(quality)) * (0.08 + (3 - Double(quality)) * 0.02)))

        if quality < 2 {  // Errei or Difícil
            newReps = 0
            newInterval = 1
        } else {
            newReps += 1

            if newReps == 1 {
                newInterval = 1
            } else if newReps == 2 {
                newInterval = 3
            } else {
                newInterval = Int(Double(interval) * newEF)
            }
        }

        return (newEF, newInterval, newReps)
    }

    // MARK: - Study Sessions

    func createStudySession(subject: String?) async throws -> StudySession {
        let session = StudySession(context: context)
        session.id = UUID().uuidString
        session.startTime = Date()
        session.subject = subject
        session.questionsAnswered = 0
        session.correctAnswers = 0
        session.xpEarned = 0

        saveContext()
        return session
    }

    func updateStudySession(
        sessionId: String,
        questionsAnswered: Int,
        correctAnswers: Int,
        xpEarned: Int
    ) async throws {
        let request = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionId)

        guard let session = try context.fetch(request).first else {
            throw CoreDataError.sessionNotFound
        }

        session.questionsAnswered = questionsAnswered
        session.correctAnswers = correctAnswers
        session.xpEarned = xpEarned

        saveContext()
    }

    func endStudySession(sessionId: String) async throws {
        let request = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionId)

        guard let session = try context.fetch(request).first else {
            throw CoreDataError.sessionNotFound
        }

        session.endTime = Date()
        saveContext()
    }

    func fetchRecentSessions(limit: Int = 10) async throws -> [StudySession] {
        let request = StudySession.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "startTime", ascending: false)
        ]
        request.fetchLimit = limit

        return try context.fetch(request)
    }

    // MARK: - Cleanup

    func deleteOldSessions(olderThan days: Int) async throws {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        )!

        let request = StudySession.fetchRequest()
        request.predicate = NSPredicate(
            format: "startTime < %@",
            cutoffDate as NSDate
        )

        let oldSessions = try context.fetch(request)

        for session in oldSessions {
            context.delete(session)
        }

        saveContext()
    }
}

enum CoreDataError: Error {
    case questionNotFound
    case flashCardNotFound
    case sessionNotFound
}
```

## Network Synchronization

### Sync Manager

```swift
@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private let apiClient = APIClient.shared
    private let coreDataManager = CoreDataManager.shared

    func syncAll() async {
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            // Upload pending data
            try await uploadPendingData()

            // Download new data
            try await downloadNewData()

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")

        } catch {
            print("Sync error: \(error)")
        }
    }

    private func uploadPendingData() async throws {
        // Upload study sessions
        let sessions = try await coreDataManager.fetchRecentSessions()

        for session in sessions where session.endTime != nil {
            let dto = StudySessionDTO(from: session)

            try await apiClient.request(
                endpoint: "/study/sessions",
                method: .post,
                body: dto
            )
        }

        // Upload flashcard reviews
        // Upload question answers
        // etc...
    }

    private func downloadNewData() async throws {
        // Download new questions
        let questions: [QuestionDTO] = try await apiClient.request(
            endpoint: "/questions/new",
            method: .get
        )

        for questionDTO in questions {
            try await coreDataManager.saveQuestion(questionDTO)
        }

        // Download user stats
        let stats: UserStats = try await apiClient.request(
            endpoint: "/user/stats",
            method: .get
        )

        // Update AppState
        // etc...
    }
}
```

### Offline Mode

```swift
extension APIClient {
    func requestWithOfflineSupport<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws -> T {
        // Check network availability
        guard NetworkMonitor.shared.isConnected else {
            // Try to load from cache
            if let cached: T = CacheManager.shared.load(key: endpoint) {
                return cached
            }

            throw APIError.offline
        }

        do {
            let result: T = try await request(
                endpoint: endpoint,
                method: method,
                body: body
            )

            // Cache successful response
            CacheManager.shared.save(result, key: endpoint)

            return result

        } catch {
            // On network error, fallback to cache
            if let cached: T = CacheManager.shared.load(key: endpoint) {
                return cached
            }

            throw error
        }
    }
}
```

## Cache Management

```swift
class CacheManager {
    static let shared = CacheManager()

    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    func save<T: Codable>(_ object: T, key: String, expiration: TimeInterval = 3600) {
        let cacheItem = CacheItem(data: object, expiresAt: Date().addingTimeInterval(expiration))

        guard let encoded = try? JSONEncoder().encode(cacheItem) else { return }

        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)

        try? encoded.write(to: fileURL)
    }

    func load<T: Codable>(key: String) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)

        guard let data = try? Data(contentsOf: fileURL),
              let cacheItem = try? JSONDecoder().decode(CacheItem<T>.self, from: data)
        else { return nil }

        // Check expiration
        guard cacheItem.expiresAt > Date() else {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        return cacheItem.data
    }

    func clear() {
        let cacheFiles = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )

        cacheFiles?.forEach { url in
            try? fileManager.removeItem(at: url)
        }
    }
}

struct CacheItem<T: Codable>: Codable {
    let data: T
    let expiresAt: Date
}

extension String {
    var md5Hash: String {
        // MD5 implementation for cache key hashing
        // Use CryptoKit in production
        return self.data(using: .utf8)?.base64EncodedString() ?? self
    }
}
```

## Network Monitor

```swift
import Network

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
```

## Data Models

### DTOs (Data Transfer Objects)

```swift
// From API
struct QuestionDTO: Codable {
    let id: String
    let text: String
    let subject: String
    let options: [QuestionOption]
    let correctOption: Int
    let explanation: String?
    let difficulty: String
    let tags: [String]
    let year: Int?
    let institution: String?
}

struct QuestionOption: Codable {
    let id: Int
    let text: String
}

// To API
struct AnswerRequest: Codable {
    let questionId: String
    let optionId: Int
    let timeSpent: Int  // seconds
}

struct AnswerResult: Codable {
    let isCorrect: Bool
    let correctOption: Int
    let explanation: String?
    let xpEarned: Int
}

// FlashCard
struct FlashCardDTO: Codable {
    let id: String
    let front: String
    let back: String
    let subject: String
    let tags: [String]
    let createdAt: Date
}

// Study Plan
struct StudyPlanDTO: Codable {
    let id: String
    let startDate: Date
    let endDate: Date
    let examDate: Date?
    let dailyGoalMinutes: Int
    let subjects: [SubjectPlan]
}

struct SubjectPlan: Codable {
    let subject: String
    let priority: Int  // 1-5
    let weeklyHours: Int
    let completed: Bool
}

// User Stats
struct UserStatsDTO: Codable {
    let level: Int
    let xp: Int
    let streak: Int
    let totalQuestionsAnswered: Int
    let totalCorrectAnswers: Int
    let studyTimeMinutes: Int
    let badges: [String]
    let subjectStats: [SubjectStats]
}

struct SubjectStats: Codable {
    let subject: String
    let questionsAnswered: Int
    let accuracy: Double
    let timeSpentMinutes: Int
}
```

## Error Handling

```swift
enum AppError: LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case unauthorized
    case serverError(statusCode: Int)
    case offline
    case coreDataError(Error)

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Erro de rede: \(error.localizedDescription)"
        case .decodingError:
            return "Erro ao processar dados"
        case .unauthorized:
            return "Sessão expirada. Faça login novamente"
        case .serverError(let code):
            return "Erro no servidor (código \(code))"
        case .offline:
            return "Sem conexão com a internet"
        case .coreDataError(let error):
            return "Erro ao salvar dados: \(error.localizedDescription)"
        }
    }
}

// Usage in ViewModels
@MainActor
class HomeViewModel: ObservableObject {
    @Published var error: AppError?

    func loadData() async {
        do {
            let stats: UserStatsDTO = try await APIClient.shared.request(
                endpoint: "/user/stats",
                method: .get
            )

            // Process stats...

        } catch let error as APIError {
            self.error = .networkError(error)
        } catch {
            self.error = .networkError(error)
        }
    }
}
```
