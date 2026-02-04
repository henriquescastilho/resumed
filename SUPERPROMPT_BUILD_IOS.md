# 🚀 SUPERPROMPT: Construir RESUMED iOS App

**OBJETIVO:** Construir um aplicativo nativo iOS revolucionário para preparação de residência médica, inspirado no Akira ENEM mas elevado a outro nível com IA, personalização avançada e gamificação científica.

---

## 📋 CONTEXTO DO PROJETO

**RESUMED** é uma plataforma de estudos para residência médica que revoluciona o autoaprendizado através de:
- **Personalização por IA** (Grey AI - assistente médico inteligente)
- **Spaced Repetition científico** (algoritmo SM-2 para retenção de longo prazo)
- **Gamificação saudável** (XP, levels, streaks, badges - sem vícios)
- **Plano de estudos adaptativo** (ajusta-se ao progresso real do estudante)
- **6 módulos integrados** (Home, Meu Plano, Grey, ResuCards, Desempenho, Provas Anteriores)

**Inspiração:** Akira ENEM (interface, gamificação, UX smooth)
**Inovação:** Vamos além com IA generativa, personalização extrema, spaced repetition científico e análise preditiva de performance

---

## 🎯 MISSÃO PRINCIPAL

Você deve construir um **aplicativo iOS nativo completo** pronto para submissão à Apple Store que:

1. ✅ Implemente TODAS as 6 telas principais com funcionalidade completa
2. ✅ Use Swift 5.9+ e SwiftUI 4 (100% nativo, zero UIKit legacy)
3. ✅ Siga arquitetura MVVM rigorosa (Views → ViewModels → Models/Services)
4. ✅ Integre com backend via API REST (endpoints documentados)
5. ✅ Implemente persistência local com Core Data (offline-first)
6. ✅ Aplique design system Gold (#D4A54A) + Black (#000000) consistentemente
7. ✅ Funcione perfeitamente em iPhone (iOS 16+) e iPad (landscape/portrait)
8. ✅ Passe em todos os requisitos da App Store (privacidade, acessibilidade, performance)

---

## 📚 DOCUMENTAÇÃO DE REFERÊNCIA (LEIA TUDO ANTES DE COMEÇAR)

Você DEVE ler e seguir rigorosamente os seguintes documentos:

### Documentação iOS (OBRIGATÓRIA)
1. **`docs/ios/01_Overview.md`** - Arquitetura geral, folder structure, design system
2. **`docs/ios/02_Tech_Stack.md`** - Tecnologias, dependências, APIClient, auth
3. **`docs/ios/03_Features_Spec.md`** - Especificação DETALHADA das 6 telas (28KB)
4. **`docs/ios/04_UI_UX_Guidelines.md`** - Design system, componentes reutilizáveis, responsive
5. **`docs/ios/05_Data_Flow.md`** - State management, Core Data, sync, offline
6. **`docs/ios/06_API_Integration.md`** - Todos os endpoints, request/response examples

### Documentação de Produto
7. **`docs/product/Brand_Guidelines.md`** - Cores, tipografia, logo, tom de voz
8. **`docs/product/MASTER_PLAN_RESUMED.md`** - Visão estratégica, personas, roadmap
9. **`docs/product/PRD_RESUMED_v1.0.docx`** - Product Requirements completo

---

## 🏗️ ESTRUTURA DO PROJETO

Crie o projeto Xcode com esta estrutura EXATA:

```
Resumed/
├── ResumedApp.swift                 # Entry point (@main)
├── Info.plist
│
├── Core/
│   ├── Models/                      # Data models
│   │   ├── User.swift
│   │   ├── Question.swift
│   │   ├── FlashCard.swift
│   │   ├── StudyPlan.swift
│   │   └── UserStats.swift
│   │
│   ├── Services/                    # Business logic
│   │   ├── APIClient.swift
│   │   ├── AuthManager.swift
│   │   ├── CoreDataManager.swift
│   │   ├── SyncManager.swift
│   │   ├── CacheManager.swift
│   │   └── NetworkMonitor.swift
│   │
│   └── Utilities/
│       ├── Constants.swift
│       ├── Extensions/
│       │   ├── Color+Resumed.swift
│       │   ├── Font+Resumed.swift
│       │   └── View+Extensions.swift
│       └── Helpers/
│           ├── HapticManager.swift
│           └── DateFormatter+Resumed.swift
│
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   ├── OnboardingView.swift
│   │   │   └── OnboardingStepView.swift
│   │   └── ViewModels/
│   │       └── AuthViewModel.swift
│   │
│   ├── Home/
│   │   ├── Views/
│   │   │   ├── HomeView.swift
│   │   │   ├── StatCard.swift
│   │   │   └── QuickActionButton.swift
│   │   └── ViewModels/
│   │       └── HomeViewModel.swift
│   │
│   ├── StudyPlan/
│   │   ├── Views/
│   │   │   ├── StudyPlanView.swift
│   │   │   ├── CalendarView.swift
│   │   │   ├── TaskRow.swift
│   │   │   └── CreatePlanSheet.swift
│   │   └── ViewModels/
│   │       └── StudyPlanViewModel.swift
│   │
│   ├── Grey/                        # AI Chat
│   │   ├── Views/
│   │   │   ├── GreyView.swift
│   │   │   ├── MessageBubble.swift
│   │   │   ├── ChatInputBar.swift
│   │   │   └── ConversationRow.swift
│   │   └── ViewModels/
│   │       └── GreyViewModel.swift
│   │
│   ├── ResuCards/                   # Flashcards
│   │   ├── Views/
│   │   │   ├── ResuCardsView.swift
│   │   │   ├── FlashCardView.swift
│   │   │   ├── CardFrontView.swift
│   │   │   ├── CardBackView.swift
│   │   │   └── CreateCardSheet.swift
│   │   └── ViewModels/
│   │       └── ResuCardsViewModel.swift
│   │
│   ├── Performance/
│   │   ├── Views/
│   │   │   ├── PerformanceView.swift
│   │   │   ├── RadarChart.swift
│   │   │   ├── ProgressChart.swift
│   │   │   └── SubjectBreakdown.swift
│   │   └── ViewModels/
│   │       └── PerformanceViewModel.swift
│   │
│   ├── PastExams/
│   │   ├── Views/
│   │   │   ├── PastExamsView.swift
│   │   │   ├── ExamCard.swift
│   │   │   ├── ExamDetailView.swift
│   │   │   ├── QuestionView.swift
│   │   │   └── ResultsView.swift
│   │   └── ViewModels/
│   │       ├── PastExamsViewModel.swift
│   │       └── ExamSessionViewModel.swift
│   │
│   └── Study/                       # Sessões de estudo
│       ├── Views/
│       │   ├── StudySessionView.swift
│       │   ├── QuestionCard.swift
│       │   ├── ExplanationView.swift
│       │   └── SessionSummaryView.swift
│       └── ViewModels/
│           └── StudySessionViewModel.swift
│
├── DesignSystem/
│   ├── Components/
│   │   ├── ResumedCard.swift
│   │   ├── ResumedButton.swift
│   │   ├── ResumedTextField.swift
│   │   ├── ProgressBar.swift
│   │   ├── XPBadge.swift
│   │   ├── EmptyState.swift
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   └── ShimmerEffect.swift
│   │
│   ├── Theme/
│   │   ├── ResumedColors.swift
│   │   ├── ResumedTypography.swift
│   │   ├── Spacing.swift
│   │   └── CornerRadius.swift
│   │
│   └── Icons/
│       └── ResumedIcons.swift
│
├── Navigation/
│   ├── RootView.swift               # Root coordinator
│   ├── TabBarView.swift             # Custom tab bar
│   └── NavigationState.swift
│
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   ├── Colors/
│   │   └── Icons/
│   │
│   └── Localizable.strings
│
└── Persistence/
    ├── Resumed.xcdatamodeld/        # Core Data model
    └── PersistenceController.swift
```

---

## 🎨 DESIGN SYSTEM (OBRIGATÓRIO)

### Paleta de Cores (Gold + Black)

```swift
// COPIE EXATAMENTE ESTE CÓDIGO
extension Color {
    static let resumed = ResumedColors()
}

struct ResumedColors {
    // Primary
    let gold = Color(hex: "D4A54A")           // CTA, highlights, XP
    let goldLight = Color(hex: "E5C572")      // Hover states
    let goldDark = Color(hex: "8C6A28")       // Active states

    // Background
    let black = Color(hex: "000000")          // Main background
    let blackSecondary = Color(hex: "050505") // Cards
    let blackTertiary = Color(hex: "0A0A0A")  // Elevated cards

    // Border & Dividers
    let border = Color(hex: "1F1F1F")
    let borderLight = Color(hex: "333333")

    // Text
    let white = Color(hex: "FFFFFF")          // Primary text
    let gray = Color(hex: "777777")           // Secondary text
    let grayLight = Color(hex: "A3A3A3")      // Tertiary text

    // Semantic
    let success = Color(hex: "10B981")        // Correct answers
    let error = Color(hex: "EF4444")          // Wrong answers
    let warning = Color(hex: "F59E0B")
    let info = Color(hex: "3B82F6")
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double((rgbValue & 0x0000FF)) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

### Tipografia

```swift
extension Font {
    static let resumed = ResumedTypography()
}

struct ResumedTypography {
    let h1 = Font.system(size: 32, weight: .black, design: .default)
    let h2 = Font.system(size: 24, weight: .bold, design: .default)
    let h3 = Font.system(size: 20, weight: .bold, design: .default)
    let h4 = Font.system(size: 18, weight: .semibold, design: .default)
    let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    let body = Font.system(size: 14, weight: .regular, design: .default)
    let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    let caption = Font.system(size: 10, weight: .regular, design: .default)
    let button = Font.system(size: 14, weight: .bold, design: .default)
}
```

---

## 🚀 FEATURES OBRIGATÓRIAS (MVP)

### 1. 🏠 HOME VIEW
**Layout:**
- Header: Avatar, nome, level, XP bar, streak 🔥
- Stats cards: Questões respondidas, Acurácia, Tempo de estudo
- Quick actions: "Começar estudo", "Ver plano", "Revisar cards"
- Motivational quote/tip do dia

**Estado:**
```swift
@Published var user: User?
@Published var stats: UserStats?
@Published var streak: Int = 0
@Published var dailyProgress: Double = 0.0  // 0.0 to 1.0
```

### 2. 📅 MEU PLANO (CORE FEATURE)
**Layout:**
- Calendário semanal com dias coloridos (completo/parcial/vazio)
- Lista de tarefas do dia (checkbox, título, estimativa, subject)
- Progresso semanal (barra)
- Botão: "Ajustar meu plano"

**Funcionalidades:**
- ✅ Marcar tarefa como concluída (+XP)
- ✅ Criar nova tarefa manualmente
- ✅ Ver tarefas futuras
- ✅ Visualizar progresso por matéria

**Estado:**
```swift
@Published var studyPlan: StudyPlan?
@Published var todayTasks: [Task] = []
@Published var weekProgress: [DayProgress] = []
```

### 3. 🤖 GREY (AI CHAT)
**Layout:**
- Chat interface (messages scrollable)
- Input bar com TextField + Send button
- Typing indicator quando IA está respondendo
- Sidebar (iPad): Histórico de conversas

**Funcionalidades:**
- ✅ Enviar pergunta médica
- ✅ Receber resposta com sources
- ✅ Ver perguntas sugeridas
- ✅ Histórico de conversas
- ✅ Criar novo chat

**Estado:**
```swift
@Published var messages: [ChatMessage] = []
@Published var isTyping: Bool = false
@Published var suggestedQuestions: [String] = []
@Published var conversations: [Conversation] = []
```

**API Integration:**
```swift
// POST /chat/message
let response: ChatResponse = try await apiClient.request(
    endpoint: "/chat/message",
    method: .post,
    body: ChatRequest(message: userMessage, conversationId: currentConversationId)
)
```

### 4. 🗂️ RESUCARDS (FLASHCARDS + SPACED REPETITION)
**Layout:**
- Card 3D flip animation
- Front: Pergunta
- Back: Resposta + botões de avaliação
- Contador: "5/20 cards hoje"
- Progress bar

**Funcionalidades:**
- ✅ Flip card (tap ou swipe)
- ✅ Avaliar dificuldade (Errei, Difícil, Bom, Fácil)
- ✅ Algoritmo SM-2 (calcular próxima revisão)
- ✅ XP por revisão (+5/+10/+15/+20 XP)
- ✅ Criar novo card
- ✅ Editar/deletar card

**Estado:**
```swift
@Published var currentCard: FlashCard?
@Published var cardsReviewed: Int = 0
@Published var cardsDueToday: Int = 0
@Published var isFlipped: Bool = false
```

**SM-2 Algorithm (IMPLEMENTAR):**
```swift
func calculateNextReview(quality: Int, card: FlashCard) -> (Date, Double, Int) {
    var newEF = card.easinessFactor
    var newInterval = card.interval
    var newReps = card.repetitions

    // EF' = EF + (0.1 - (3 - q) * (0.08 + (3 - q) * 0.02))
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
            newInterval = Int(Double(newInterval) * newEF)
        }
    }

    let nextReview = Calendar.current.date(byAdding: .day, value: newInterval, to: Date())!
    return (nextReview, newEF, newReps)
}
```

### 5. 📊 DESEMPENHO (ANALYTICS)
**Layout:**
- Level + XP progress (circular ou linear)
- Radar chart (6 matérias: Clínica, Cirurgia, Pediatria, GO, Preventiva, Outras)
- Line chart: Progresso últimos 30 dias (acurácia)
- Bar chart: Questões por matéria
- Lista: Tópicos mais fracos (sugestão de revisão)

**Funcionalidades:**
- ✅ Visualizar progresso temporal
- ✅ Comparar matérias (radar chart)
- ✅ Identificar pontos fracos
- ✅ Ver badges conquistados
- ✅ Filtrar por período (7d, 30d, 90d, all time)

**Estado:**
```swift
@Published var userStats: UserStats?
@Published var subjectStats: [SubjectStat] = []
@Published var progressData: [ProgressDataPoint] = []
@Published var badges: [Badge] = []
@Published var selectedPeriod: TimePeriod = .thirtyDays
```

**Charts (usar Swift Charts):**
```swift
import Charts

Chart {
    ForEach(progressData) { point in
        LineMark(
            x: .value("Data", point.date),
            y: .value("Acurácia", point.accuracy)
        )
        .foregroundStyle(Color.resumed.gold)
    }
}
.chartXAxis {
    AxisMarks(values: .stride(by: .day, count: 7))
}
```

### 6. 📝 PROVAS ANTERIORES (SIMULADOS)
**Layout:**
- Grid/List de exames (USP 2023, UNICAMP 2022, etc)
- Cada card: Logo instituição, nome, ano, nº questões, duração
- Filtros: Instituição, Ano, Matéria
- Detalhes: Ver progresso (45/100 questões, 71% acurácia)

**Funcionalidades:**
- ✅ Listar provas disponíveis
- ✅ Iniciar simulado (cronômetro)
- ✅ Responder questões sequencialmente
- ✅ Pausar/retomar
- ✅ Submeter respostas
- ✅ Ver resultado detalhado
- ✅ Comparar com ranking

**Estado:**
```swift
@Published var exams: [Exam] = []
@Published var currentSession: ExamSession?
@Published var timeRemaining: Int = 0  // seconds
@Published var currentQuestionIndex: Int = 0
@Published var answers: [String: Int] = [:]  // questionId: optionId
```

---

## 🔐 AUTENTICAÇÃO (FIREBASE)

### Onboarding Flow

1. **Splash Screen** (1s)
2. **Onboarding Screens** (3 screens com swipe)
   - Screen 1: "Seu plano personalizado de estudos"
   - Screen 2: "Grey AI, seu tutor médico 24/7"
   - Screen 3: "Gamificação científica que funciona"
3. **Login Screen**
   - Botão: "Continuar com Google" (Firebase Auth)
   - Logo RESUMED (Gold)
   - Fundo: Black com gradient sutil

### AuthManager Implementation

```swift
import Firebase
import FirebaseAuth

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false

    var accessToken: String? {
        // Get from Keychain
        KeychainHelper.shared.read(key: "accessToken")
    }

    init() {
        checkAuthStatus()
    }

    func checkAuthStatus() {
        if let firebaseUser = Auth.auth().currentUser {
            // User is signed in
            Task {
                await fetchUserProfile()
            }
        }
    }

    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }

        // 1. Get Google ID token from Firebase
        guard let idToken = try await getGoogleIDToken() else {
            throw AuthError.failedToGetToken
        }

        // 2. Send to backend
        let response: AuthResponse = try await APIClient.shared.request(
            endpoint: "/auth/google",
            method: .post,
            body: GoogleAuthRequest(
                idToken: idToken,
                deviceId: UIDevice.current.identifierForVendor?.uuidString ?? ""
            ),
            requiresAuth: false
        )

        // 3. Save tokens
        KeychainHelper.shared.save(response.accessToken, key: "accessToken")
        KeychainHelper.shared.save(response.refreshToken, key: "refreshToken")

        // 4. Update state
        self.user = response.user
        self.isAuthenticated = true
    }

    func signOut() async {
        try? Auth.auth().signOut()
        KeychainHelper.shared.delete(key: "accessToken")
        KeychainHelper.shared.delete(key: "refreshToken")

        self.user = nil
        self.isAuthenticated = false
    }

    func refreshToken() async throws {
        guard let refreshToken = KeychainHelper.shared.read(key: "refreshToken") else {
            throw AuthError.noRefreshToken
        }

        let response: RefreshResponse = try await APIClient.shared.request(
            endpoint: "/auth/refresh",
            method: .post,
            body: RefreshRequest(refreshToken: refreshToken),
            requiresAuth: false
        )

        KeychainHelper.shared.save(response.accessToken, key: "accessToken")
    }
}

enum AuthError: Error {
    case failedToGetToken
    case noRefreshToken
}
```

---

## 💾 CORE DATA (OFFLINE-FIRST)

### Entities (Core Data Model)

**Question**
```
id: String (UUID)
text: String
subject: String
options: Data (JSON)
correctOption: Int16
explanation: String?
difficulty: String
lastReviewed: Date?
nextReview: Date?
reviewCount: Int16
correctCount: Int16
createdAt: Date
updatedAt: Date
```

**FlashCard**
```
id: String (UUID)
front: String
back: String
subject: String
tags: Data (JSON [String])
lastReviewed: Date?
nextReview: Date
easinessFactor: Double (default 2.5)
interval: Int16 (days)
repetitions: Int16
createdAt: Date
```

**StudySession**
```
id: String (UUID)
startTime: Date
endTime: Date?
questionsAnswered: Int16
correctAnswers: Int16
xpEarned: Int16
subject: String?
```

### CoreDataManager (IMPLEMENTAR COMPLETO)

```swift
@MainActor
class CoreDataManager {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Resumed")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    // CRUD methods for each entity
    func fetchFlashCardsDueToday() async throws -> [FlashCard] {
        let request = FlashCard.fetchRequest()
        request.predicate = NSPredicate(format: "nextReview <= %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "nextReview", ascending: true)]
        return try context.fetch(request)
    }

    // ... (implementar todos os métodos conforme docs/ios/05_Data_Flow.md)
}
```

---

## 🌐 API CLIENT (NETWORKING)

### Base APIClient

```swift
@MainActor
class APIClient {
    static let shared = APIClient()

    private let baseURL = "https://api.resumed.app/v1"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Auth token
        if requiresAuth {
            guard let token = AuthManager.shared.accessToken else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Body
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            try await AuthManager.shared.refreshToken()
            return try await self.request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(statusCode: Int)
}
```

---

## 🎮 GAMIFICAÇÃO (XP, LEVELS, STREAKS, BADGES)

### Sistema de XP

**Ganho de XP:**
- Questão correta: +15 XP
- Questão errada: +5 XP (tentou!)
- FlashCard "Errei": +5 XP
- FlashCard "Difícil": +10 XP
- FlashCard "Bom": +15 XP
- FlashCard "Fácil": +20 XP
- Completar tarefa do plano: +50 XP
- Meta diária completa: +100 XP
- Simulado completo: +500 XP

**Tabela de Levels:**
```swift
struct LevelSystem {
    static func xpForLevel(_ level: Int) -> Int {
        // Fórmula: XP = 1000 * level^1.5
        return Int(1000.0 * pow(Double(level), 1.5))
    }

    static func levelForXP(_ xp: Int) -> Int {
        var level = 1
        var totalXP = 0

        while totalXP + xpForLevel(level) <= xp {
            totalXP += xpForLevel(level)
            level += 1
        }

        return level
    }

    static func xpProgressInCurrentLevel(totalXP: Int) -> (current: Int, needed: Int) {
        let level = levelForXP(totalXP)
        let xpNeeded = xpForLevel(level)

        // Calculate XP already spent on previous levels
        var previousLevelsXP = 0
        for l in 1..<level {
            previousLevelsXP += xpForLevel(l)
        }

        let currentLevelXP = totalXP - previousLevelsXP

        return (currentLevelXP, xpNeeded)
    }
}

// Level 1: 0-1000 XP
// Level 2: 1000-2414 XP (1414 XP needed)
// Level 3: 2414-4656 XP (2242 XP needed)
// Level 4: 4656-7656 XP (3000 XP needed)
// ...
```

### Streak System

```swift
struct StreakManager {
    static func updateStreak(lastStudyDate: Date?) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastDate = lastStudyDate else {
            return 1  // First day
        }

        let lastStudy = calendar.startOfDay(for: lastDate)
        let daysDiff = calendar.dateComponents([.day], from: lastStudy, to: today).day ?? 0

        if daysDiff == 0 {
            // Same day, maintain streak
            return currentStreak
        } else if daysDiff == 1 {
            // Consecutive day, increment
            return currentStreak + 1
        } else {
            // Streak broken, reset
            return 1
        }
    }
}
```

### Badges System

```swift
enum Badge: String, CaseIterable {
    case firstQuestion = "first-question"
    case weekStreak = "week-streak"
    case monthStreak = "month-streak"
    case hundredQuestions = "hundred-questions"
    case level10 = "level-10"
    case perfectDay = "perfect-day"
    case subjectMasterClinica = "subject-master-clinica"
    case examCompleted = "exam-completed"

    var title: String {
        switch self {
        case .firstQuestion: return "Primeira Questão"
        case .weekStreak: return "Semana Completa"
        case .monthStreak: return "Mês de Dedicação"
        case .hundredQuestions: return "Centurião"
        case .level10: return "Level 10"
        case .perfectDay: return "Dia Perfeito"
        case .subjectMasterClinica: return "Mestre em Clínica"
        case .examCompleted: return "Simulado Completo"
        }
    }

    var description: String {
        switch self {
        case .firstQuestion: return "Respondeu sua primeira questão"
        case .weekStreak: return "7 dias consecutivos de estudo"
        case .monthStreak: return "30 dias consecutivos de estudo"
        case .hundredQuestions: return "100 questões respondidas"
        case .level10: return "Alcançou o level 10"
        case .perfectDay: return "100% de acurácia em um dia"
        case .subjectMasterClinica: return "80%+ de acurácia em Clínica Médica"
        case .examCompleted: return "Completou um simulado inteiro"
        }
    }

    var icon: String {
        switch self {
        case .firstQuestion: return "checkmark.circle.fill"
        case .weekStreak: return "flame.fill"
        case .monthStreak: return "star.fill"
        case .hundredQuestions: return "100.circle.fill"
        case .level10: return "crown.fill"
        case .perfectDay: return "sparkles"
        case .subjectMasterClinica: return "cross.case.fill"
        case .examCompleted: return "doc.text.fill"
        }
    }
}
```

---

## 📱 NAVIGATION & TAB BAR

### Custom Tab Bar (Bottom Navigation)

```swift
struct TabBarView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack {
            // Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .plan:
                    StudyPlanView()
                case .grey:
                    GreyView()
                case .cards:
                    ResuCardsView()
                case .performance:
                    PerformanceView()
                }
            }

            // Custom Tab Bar
            VStack {
                Spacer()

                HStack(spacing: 0) {
                    TabBarItem(tab: .home, selectedTab: $selectedTab, icon: "house.fill", label: "Home")
                    TabBarItem(tab: .plan, selectedTab: $selectedTab, icon: "calendar", label: "Meu Plano")
                    TabBarItem(tab: .grey, selectedTab: $selectedTab, icon: "brain.head.profile", label: "Grey")
                    TabBarItem(tab: .cards, selectedTab: $selectedTab, icon: "rectangle.stack.fill", label: "ResuCards")
                    TabBarItem(tab: .performance, selectedTab: $selectedTab, icon: "chart.bar.fill", label: "Desempenho")
                }
                .frame(height: 60)
                .background(Color.resumed.blackSecondary)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.resumed.border),
                    alignment: .top
                )
                .padding(.bottom)
            }
        }
        .background(Color.resumed.black)
        .preferredColorScheme(.dark)  // Force dark mode
    }
}

struct TabBarItem: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    let icon: String
    let label: String

    var isSelected: Bool {
        selectedTab == tab
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
                HapticManager.shared.selection()
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))

                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? Color.resumed.gold : Color.resumed.gray)
            .frame(maxWidth: .infinity)
        }
    }
}

enum Tab {
    case home
    case plan
    case grey
    case cards
    case performance
}
```

---

## 🎬 ANIMAÇÕES OBRIGATÓRIAS

### Card Flip (ResuCards)
```swift
@State private var isFlipped = false
@State private var rotation: Double = 0

var body: some View {
    ZStack {
        if !isFlipped {
            CardFrontView(text: card.front)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        } else {
            CardBackView(text: card.back)
                .rotation3DEffect(.degrees(rotation + 180), axis: (x: 0, y: 1, z: 0))
        }
    }
    .onTapGesture {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            rotation += 180
            isFlipped.toggle()
        }
        HapticManager.shared.impact(.medium)
    }
}
```

### XP Gain Animation
```swift
@State private var showXP = false
@State private var xpOffset: CGFloat = 0

if showXP {
    Text("+15 XP")
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(.resumed.gold)
        .offset(y: xpOffset)
        .opacity(xpOffset < -50 ? 0 : 1)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                xpOffset = -80
            }
        }
}
```

### Level Up Animation
```swift
.overlay {
    if showLevelUp {
        LevelUpOverlay(level: newLevel)
            .transition(.scale.combined(with: .opacity))
    }
}
```

---

## ✅ CHECKLIST PRÉ-SUBMISSÃO APPLE STORE

### Funcionalidade
- [ ] App abre sem crashes
- [ ] Todas as 6 telas funcionam
- [ ] Login com Google funciona
- [ ] Dados persistem (Core Data)
- [ ] Offline mode funciona (cache)
- [ ] Sincronização com API funciona
- [ ] Push notifications funcionam
- [ ] Deep links funcionam

### Design
- [ ] Dark mode forçado (sem light mode)
- [ ] Cores consistentes (Gold + Black)
- [ ] Tipografia SF Pro correta
- [ ] iPad responsivo (landscape/portrait)
- [ ] Animações smooth (60fps)
- [ ] Loading states em todos os requests
- [ ] Error states com retry
- [ ] Empty states com ilustrações

### Acessibilidade
- [ ] VoiceOver labels corretos
- [ ] Dynamic Type suportado
- [ ] Contraste WCAG AA (mínimo)
- [ ] Hit targets mínimos (44x44pt)
- [ ] Haptic feedback apropriado

### Privacidade
- [ ] Info.plist com descrições (Camera, Notifications, etc)
- [ ] Privacy Manifest (PrivacyInfo.xcprivacy)
- [ ] Terms of Service link
- [ ] Privacy Policy link
- [ ] Não coleta dados sem consentimento

### Performance
- [ ] App size < 200MB (idealmente)
- [ ] Launch time < 2s
- [ ] Scroll 60fps
- [ ] Sem memory leaks
- [ ] Battery efficient

### App Store Assets
- [ ] App Icon 1024x1024px (sem alpha)
- [ ] Screenshots iPhone (6.5", 5.5")
- [ ] Screenshots iPad (12.9", 11")
- [ ] App Preview videos (opcional)
- [ ] Description PT-BR
- [ ] Keywords otimizados
- [ ] Category: Education / Medical

---

## 🚨 IMPORTANTE: DIFERENÇAS DO AKIRA ENEM

**RESUMED NÃO É UMA CÓPIA. É UMA REVOLUÇÃO.**

### O que NÃO fazer (evitar cópia do Akira):
- ❌ NÃO copiar layouts exatos
- ❌ NÃO copiar frases/textos
- ❌ NÃO copiar ícones customizados
- ❌ NÃO copiar animações específicas

### Nossas inovações EXCLUSIVAS:
- ✅ **Grey AI**: Tutor médico inteligente (Akira não tem)
- ✅ **Spaced Repetition científico**: SM-2 algorithm (Akira não implementa)
- ✅ **Plano adaptativo**: Ajusta automaticamente ao progresso (Akira é estático)
- ✅ **Análise preditiva**: Machine learning para prever performance (Akira não tem)
- ✅ **ResuCards**: Flashcards inteligentes com SRS (Akira não tem flashcards)
- ✅ **Radar chart de matérias**: Visualização única (Akira usa barras simples)
- ✅ **Gold + Black theme**: Identidade visual única (Akira usa azul/roxo)
- ✅ **iPad first-class**: Split view, multi-window (Akira é iPhone-only)

**Inspiração sim, cópia não. Somos melhores.**

---

## 📦 DEPENDENCIES (Package.swift)

```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.20.0"),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
    .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.3.0")
]
```

**Opcional (se necessário):**
- SDWebImageSwiftUI (para cache de imagens)
- Lottie (para animações complexas)

**NÃO usar:**
- Alamofire (use URLSession nativo)
- Realm (use Core Data)
- RxSwift (use Combine nativo)

---

## 🎯 ORDEM DE IMPLEMENTAÇÃO SUGERIDA

### Fase 1: Foundation (Dia 1-2)
1. Setup projeto Xcode
2. Design System completo (Colors, Typography, Components)
3. Navigation (TabBar, RootView)
4. Core Data model
5. APIClient base
6. AuthManager + Firebase

### Fase 2: Core Features (Dia 3-5)
7. HomeView + ViewModel (básico)
8. Meu Plano View + ViewModel
9. StudySessionView (questões)
10. ResuCardsView + SM-2 algorithm

### Fase 3: Advanced Features (Dia 6-7)
11. GreyView (AI Chat)
12. PerformanceView (Charts)
13. PastExamsView (Simulados)
14. Gamificação (XP, Levels, Badges)

### Fase 4: Polish (Dia 8-9)
15. Animações
16. Empty states
17. Error handling
18. Offline mode
19. iPad layouts

### Fase 5: Release (Dia 10)
20. App Store assets
21. TestFlight
22. Final QA
23. Submit

---

## 🧪 TESTING

### Unit Tests (mínimo)
```swift
@testable import Resumed
import XCTest

class LevelSystemTests: XCTestCase {
    func testXPCalculation() {
        XCTAssertEqual(LevelSystem.xpForLevel(1), 1000)
        XCTAssertEqual(LevelSystem.xpForLevel(2), 1414)
        XCTAssertEqual(LevelSystem.levelForXP(2500), 2)
    }
}

class SM2AlgorithmTests: XCTestCase {
    func testEasyCard() {
        let card = FlashCard(easinessFactor: 2.5, interval: 1, repetitions: 0)
        let (nextReview, newEF, newInterval) = calculateNextReview(quality: 3, card: card)

        XCTAssertEqual(newInterval, 1)
        XCTAssertGreaterThan(newEF, 2.5)
    }
}
```

### UI Tests (opcional)
```swift
func testLoginFlow() {
    let app = XCUIApplication()
    app.launch()

    let loginButton = app.buttons["Continuar com Google"]
    XCTAssertTrue(loginButton.exists)
}
```

---

## 📝 FINAL CHECKLIST

Antes de finalizar, verifique:

✅ **Código**
- [ ] Sem force unwraps (!)
- [ ] Sem prints desnecessários
- [ ] Tratamento de erros em todos os async calls
- [ ] Memory leaks verificados (Instruments)
- [ ] Código comentado (onde necessário)

✅ **Design**
- [ ] Todas as cores da paleta usadas consistentemente
- [ ] Spacing system (4/8/16/24/32/48) respeitado
- [ ] Fontes corretas (SF Pro)
- [ ] Ícones SF Symbols (system icons)

✅ **Funcionalidade**
- [ ] Todas as 6 telas implementadas
- [ ] API integration funcionando
- [ ] Core Data persistindo
- [ ] Gamificação completa (XP, levels, streaks, badges)
- [ ] Spaced repetition SM-2 correto

✅ **Performance**
- [ ] Scroll suave (60fps)
- [ ] Imagens otimizadas
- [ ] Requests cancelados quando necessário
- [ ] Memory warnings tratados

✅ **App Store**
- [ ] Info.plist completo
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] App Icon 1024x1024
- [ ] Screenshots (iPhone + iPad)

---

## 🎉 GO BUILD!

**Você tem TODA a informação necessária.**

Leia TODOS os documentos de referência em `docs/ios/` antes de começar.

Implemente com excelência. Pense em cada detalhe. Este app vai mudar vidas de estudantes de medicina.

**Boa sorte, e que o Gold (#D4A54A) esteja com você! 🏆**

---

**RESUMED iOS App**
*Revolucionando a preparação para residência médica*
Version 1.0.0 (MVP)
