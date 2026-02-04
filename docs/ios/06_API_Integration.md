# 06. API Integration - RESUMED iOS

## Base Configuration

### API Client Setup

```swift
@MainActor
class APIClient {
    static let shared = APIClient()

    private let baseURL = "https://api.resumed.app/v1"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true

        self.session = URLSession(configuration: config)
    }

    // Generic request method
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

        // Add auth token if required
        if requiresAuth {
            guard let token = AuthManager.shared.accessToken else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body if present
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle status codes
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            // Token expired, try to refresh
            try await AuthManager.shared.refreshToken()
            return try await self.request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.unknown(statusCode: httpResponse.statusCode)
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
    case forbidden
    case notFound
    case serverError(statusCode: Int)
    case unknown(statusCode: Int)
}
```

## Authentication Endpoints

### POST /auth/google

Login com Google (Firebase Auth)

**Request:**
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjFlOWdkazcifQ...",
  "deviceId": "iPhone14-ABC123"
}
```

**Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "def50200a1b2c3d4...",
  "expiresIn": 3600,
  "user": {
    "id": "usr_abc123",
    "email": "user@example.com",
    "name": "João Silva",
    "avatar": "https://cdn.resumed.app/avatars/usr_abc123.jpg",
    "isPro": false,
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

**Swift Implementation:**
```swift
struct GoogleAuthRequest: Codable {
    let idToken: String
    let deviceId: String
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: User
}

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let isPro: Bool
    let createdAt: Date
}

// Usage
let response: AuthResponse = try await APIClient.shared.request(
    endpoint: "/auth/google",
    method: .post,
    body: GoogleAuthRequest(
        idToken: firebaseToken,
        deviceId: UIDevice.current.identifierForVendor?.uuidString ?? ""
    ),
    requiresAuth: false
)
```

### POST /auth/refresh

Renovar token de acesso

**Request:**
```json
{
  "refreshToken": "def50200a1b2c3d4..."
}
```

**Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
```

### POST /auth/logout

Logout (invalidar tokens)

**Request:** Empty body

**Response:**
```json
{
  "message": "Logout successful"
}
```

## User Endpoints

### GET /user/profile

Buscar perfil do usuário

**Response:**
```json
{
  "id": "usr_abc123",
  "email": "user@example.com",
  "name": "João Silva",
  "avatar": "https://cdn.resumed.app/avatars/usr_abc123.jpg",
  "isPro": false,
  "subscription": {
    "plan": "free",
    "expiresAt": null
  },
  "preferences": {
    "dailyGoalMinutes": 120,
    "notificationsEnabled": true,
    "studyReminder": "20:00"
  },
  "createdAt": "2024-01-15T10:30:00Z"
}
```

### PATCH /user/profile

Atualizar perfil

**Request:**
```json
{
  "name": "João Silva Santos",
  "dailyGoalMinutes": 180,
  "studyReminder": "19:00"
}
```

**Response:** Updated user profile (same structure as GET /user/profile)

### GET /user/stats

Estatísticas do usuário

**Response:**
```json
{
  "level": 12,
  "xp": 2450,
  "xpToNextLevel": 3000,
  "streak": 7,
  "longestStreak": 21,
  "totalQuestionsAnswered": 1247,
  "totalCorrectAnswers": 892,
  "accuracy": 71.5,
  "studyTimeMinutes": 3420,
  "badges": ["first-question", "week-streak", "subject-master-clinica"],
  "subjectStats": [
    {
      "subject": "Clínica Médica",
      "questionsAnswered": 420,
      "correctAnswers": 315,
      "accuracy": 75.0,
      "timeSpentMinutes": 1200
    },
    {
      "subject": "Cirurgia",
      "questionsAnswered": 310,
      "correctAnswers": 198,
      "accuracy": 63.9,
      "timeSpentMinutes": 890
    }
  ]
}
```

**Swift Implementation:**
```swift
struct UserStats: Codable {
    let level: Int
    let xp: Int
    let xpToNextLevel: Int
    let streak: Int
    let longestStreak: Int
    let totalQuestionsAnswered: Int
    let totalCorrectAnswers: Int
    let accuracy: Double
    let studyTimeMinutes: Int
    let badges: [String]
    let subjectStats: [SubjectStat]
}

struct SubjectStat: Codable {
    let subject: String
    let questionsAnswered: Int
    let correctAnswers: Int
    let accuracy: Double
    let timeSpentMinutes: Int
}

// Usage
let stats: UserStats = try await APIClient.shared.request(
    endpoint: "/user/stats",
    method: .get
)
```

## Study Plan Endpoints

### GET /study-plan

Buscar plano de estudos do usuário

**Response:**
```json
{
  "id": "plan_abc123",
  "userId": "usr_abc123",
  "startDate": "2024-01-01",
  "endDate": "2024-12-31",
  "examDate": "2025-01-15",
  "dailyGoalMinutes": 120,
  "weeklyGoalHours": 14,
  "subjects": [
    {
      "subject": "Clínica Médica",
      "priority": 5,
      "weeklyHours": 4,
      "completed": false,
      "progress": 45.2
    },
    {
      "subject": "Cirurgia",
      "priority": 4,
      "weeklyHours": 3,
      "completed": false,
      "progress": 32.1
    }
  ],
  "tasks": [
    {
      "id": "task_001",
      "title": "Revisar Cardiologia",
      "subject": "Clínica Médica",
      "type": "review",
      "dueDate": "2024-01-20",
      "completed": false,
      "estimatedMinutes": 60
    }
  ],
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-18T14:22:00Z"
}
```

### POST /study-plan

Criar novo plano de estudos

**Request:**
```json
{
  "examDate": "2025-01-15",
  "dailyGoalMinutes": 120,
  "subjects": [
    {
      "subject": "Clínica Médica",
      "priority": 5,
      "weeklyHours": 4
    },
    {
      "subject": "Cirurgia",
      "priority": 4,
      "weeklyHours": 3
    }
  ]
}
```

**Response:** Created study plan (same structure as GET)

### PATCH /study-plan/:id

Atualizar plano de estudos

**Request:**
```json
{
  "dailyGoalMinutes": 150,
  "subjects": [
    {
      "subject": "Clínica Médica",
      "priority": 5,
      "weeklyHours": 5
    }
  ]
}
```

### POST /study-plan/tasks/:id/complete

Marcar tarefa como concluída

**Response:**
```json
{
  "taskId": "task_001",
  "completed": true,
  "xpEarned": 50,
  "completedAt": "2024-01-20T18:30:00Z"
}
```

## Questions Endpoints

### GET /questions/random

Buscar questão aleatória

**Query Parameters:**
- `subject` (optional): Filter by subject
- `difficulty` (optional): easy, medium, hard
- `year` (optional): Filter by exam year
- `institution` (optional): Filter by institution

**Example:** `/questions/random?subject=Clínica Médica&difficulty=medium`

**Response:**
```json
{
  "id": "q_abc123",
  "text": "Paciente de 45 anos, sexo masculino, apresenta dor torácica retroesternal...",
  "subject": "Clínica Médica",
  "topic": "Cardiologia",
  "difficulty": "medium",
  "year": 2023,
  "institution": "USP",
  "options": [
    {
      "id": 1,
      "text": "Infarto agudo do miocárdio"
    },
    {
      "id": 2,
      "text": "Angina estável"
    },
    {
      "id": 3,
      "text": "Pericardite aguda"
    },
    {
      "id": 4,
      "text": "Dissecção aórtica"
    }
  ],
  "correctOption": 1,
  "explanation": "O quadro clínico apresentado é compatível com infarto agudo do miocárdio...",
  "references": [
    "Harrison's Principles of Internal Medicine, 20th ed., p.1523"
  ],
  "tags": ["cardiologia", "emergência", "dor-torácica"]
}
```

### POST /questions/:id/answer

Submeter resposta de questão

**Request:**
```json
{
  "optionId": 1,
  "timeSpent": 45
}
```

**Response:**
```json
{
  "questionId": "q_abc123",
  "isCorrect": true,
  "correctOption": 1,
  "explanation": "O quadro clínico apresentado é compatível...",
  "xpEarned": 15,
  "streak": 3,
  "userStats": {
    "totalAnswered": 1248,
    "totalCorrect": 893,
    "accuracy": 71.6
  }
}
```

### GET /questions/due

Buscar questões para revisar (Spaced Repetition)

**Response:**
```json
{
  "questions": [
    {
      "id": "q_abc123",
      "text": "Paciente de 45 anos...",
      "subject": "Clínica Médica",
      "nextReview": "2024-01-20T10:00:00Z",
      "reviewCount": 3,
      "lastReviewedAt": "2024-01-17T14:30:00Z"
    }
  ],
  "total": 15
}
```

## FlashCards Endpoints

### GET /flashcards

Buscar flashcards do usuário

**Query Parameters:**
- `subject` (optional): Filter by subject
- `limit` (default: 20): Number of cards
- `offset` (default: 0): Pagination

**Response:**
```json
{
  "flashcards": [
    {
      "id": "fc_abc123",
      "front": "Quais são os critérios de ROME IV para constipação funcional?",
      "back": "1. Esforço evacuatório\n2. Fezes endurecidas\n3. Sensação de evacuação incompleta\n4. Sensação de obstrução anorretal...",
      "subject": "Gastroenterologia",
      "tags": ["rome-iv", "constipacao"],
      "nextReview": "2024-01-22T10:00:00Z",
      "easinessFactor": 2.5,
      "interval": 3,
      "repetitions": 2,
      "createdAt": "2024-01-10T08:00:00Z"
    }
  ],
  "total": 156,
  "hasMore": true
}
```

### POST /flashcards

Criar novo flashcard

**Request:**
```json
{
  "front": "Quais são os critérios de ROME IV?",
  "back": "1. Esforço evacuatório\n2. Fezes endurecidas...",
  "subject": "Gastroenterologia",
  "tags": ["rome-iv", "constipacao"]
}
```

**Response:**
```json
{
  "id": "fc_abc123",
  "front": "Quais são os critérios de ROME IV?",
  "back": "1. Esforço evacuatório...",
  "subject": "Gastroenterologia",
  "tags": ["rome-iv", "constipacao"],
  "nextReview": "2024-01-20T10:00:00Z",
  "easinessFactor": 2.5,
  "interval": 1,
  "repetitions": 0,
  "createdAt": "2024-01-20T10:00:00Z"
}
```

### GET /flashcards/due

Buscar flashcards para revisar

**Response:**
```json
{
  "flashcards": [
    {
      "id": "fc_abc123",
      "front": "Quais são os critérios de ROME IV?",
      "back": "1. Esforço evacuatório...",
      "subject": "Gastroenterologia",
      "nextReview": "2024-01-20T10:00:00Z",
      "reviewCount": 3
    }
  ],
  "total": 8
}
```

### POST /flashcards/:id/review

Submeter revisão de flashcard

**Request:**
```json
{
  "quality": 2
}
```

**Quality Scale:**
- 0: "Errei" (Não lembrou)
- 1: "Difícil" (Lembrou com dificuldade)
- 2: "Bom" (Lembrou bem)
- 3: "Fácil" (Lembrou facilmente)

**Response:**
```json
{
  "flashcardId": "fc_abc123",
  "nextReview": "2024-01-27T10:00:00Z",
  "interval": 7,
  "easinessFactor": 2.6,
  "repetitions": 3,
  "xpEarned": 15
}
```

### DELETE /flashcards/:id

Deletar flashcard

**Response:**
```json
{
  "message": "Flashcard deleted successfully"
}
```

## AI Chat (Grey) Endpoints

### POST /chat/message

Enviar mensagem para o Grey

**Request:**
```json
{
  "message": "Explica pra mim sobre insuficiência cardíaca congestiva",
  "conversationId": "conv_abc123",
  "context": {
    "currentSubject": "Cardiologia",
    "recentTopics": ["hipertensão", "arritmias"]
  }
}
```

**Response:**
```json
{
  "messageId": "msg_abc123",
  "conversationId": "conv_abc123",
  "response": "Insuficiência cardíaca congestiva (ICC) é uma síndrome clínica...",
  "sources": [
    {
      "title": "Diretriz Brasileira de ICC - SBC 2023",
      "url": "https://..."
    }
  ],
  "relatedTopics": ["edema pulmonar", "fração de ejeção", "BNP"],
  "suggestedQuestions": [
    "Quais são os critérios de Framingham para ICC?",
    "Como calcular a fração de ejeção?"
  ]
}
```

### GET /chat/conversations

Buscar histórico de conversas

**Response:**
```json
{
  "conversations": [
    {
      "id": "conv_abc123",
      "title": "Insuficiência Cardíaca",
      "lastMessage": "Obrigado pela explicação!",
      "messageCount": 8,
      "createdAt": "2024-01-20T10:00:00Z",
      "updatedAt": "2024-01-20T10:45:00Z"
    }
  ],
  "total": 42
}
```

### GET /chat/conversations/:id

Buscar mensagens de uma conversa

**Response:**
```json
{
  "conversationId": "conv_abc123",
  "messages": [
    {
      "id": "msg_001",
      "role": "user",
      "content": "Explica sobre ICC",
      "timestamp": "2024-01-20T10:00:00Z"
    },
    {
      "id": "msg_002",
      "role": "assistant",
      "content": "Insuficiência cardíaca congestiva...",
      "timestamp": "2024-01-20T10:00:15Z"
    }
  ]
}
```

## Past Exams Endpoints

### GET /exams

Listar provas anteriores

**Query Parameters:**
- `institution` (optional): Filter by institution
- `year` (optional): Filter by year
- `subject` (optional): Filter by subject

**Response:**
```json
{
  "exams": [
    {
      "id": "exam_abc123",
      "institution": "USP",
      "year": 2023,
      "name": "Residência Médica USP 2023",
      "questionCount": 100,
      "duration": 240,
      "subjects": ["Clínica Médica", "Cirurgia", "Pediatria"],
      "thumbnail": "https://cdn.resumed.app/exams/usp-2023.jpg",
      "difficulty": "hard",
      "averageScore": 68.5
    }
  ],
  "total": 156
}
```

### GET /exams/:id

Buscar detalhes de uma prova

**Response:**
```json
{
  "id": "exam_abc123",
  "institution": "USP",
  "year": 2023,
  "name": "Residência Médica USP 2023",
  "questionCount": 100,
  "duration": 240,
  "description": "Prova para seleção de residentes em diversas especialidades...",
  "subjects": ["Clínica Médica", "Cirurgia", "Pediatria"],
  "questions": [
    {
      "id": "q_001",
      "number": 1,
      "subject": "Clínica Médica",
      "text": "Paciente de 45 anos...",
      "options": [...]
    }
  ],
  "userProgress": {
    "started": true,
    "completed": false,
    "questionsAnswered": 45,
    "correctAnswers": 32,
    "currentScore": 71.1,
    "timeSpent": 120
  }
}
```

### POST /exams/:id/start

Iniciar simulado

**Response:**
```json
{
  "sessionId": "session_abc123",
  "examId": "exam_abc123",
  "startedAt": "2024-01-20T10:00:00Z",
  "expiresAt": "2024-01-20T14:00:00Z",
  "questions": [...]
}
```

### POST /exams/:id/submit

Submeter respostas do simulado

**Request:**
```json
{
  "sessionId": "session_abc123",
  "answers": [
    {
      "questionId": "q_001",
      "optionId": 2,
      "timeSpent": 90
    },
    {
      "questionId": "q_002",
      "optionId": 1,
      "timeSpent": 75
    }
  ]
}
```

**Response:**
```json
{
  "sessionId": "session_abc123",
  "score": 78.5,
  "correctAnswers": 78,
  "totalQuestions": 100,
  "timeSpent": 220,
  "xpEarned": 500,
  "ranking": {
    "position": 142,
    "total": 3420
  },
  "subjectBreakdown": [
    {
      "subject": "Clínica Médica",
      "correct": 28,
      "total": 35,
      "accuracy": 80.0
    }
  ],
  "detailedResults": [
    {
      "questionId": "q_001",
      "correct": true,
      "userAnswer": 2,
      "correctAnswer": 2,
      "timeSpent": 90
    }
  ]
}
```

### GET /exams/:id/leaderboard

Ranking do simulado

**Response:**
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "userId": "usr_xyz789",
      "name": "Maria Silva",
      "score": 95.0,
      "timeSpent": 180
    },
    {
      "rank": 2,
      "userId": "usr_abc123",
      "name": "João Santos",
      "score": 92.5,
      "timeSpent": 195
    }
  ],
  "userRank": {
    "rank": 142,
    "score": 78.5,
    "timeSpent": 220
  },
  "total": 3420
}
```

## Analytics Endpoints

### GET /analytics/progress

Progresso do usuário ao longo do tempo

**Query Parameters:**
- `period`: day, week, month, year
- `startDate`: ISO date
- `endDate`: ISO date

**Response:**
```json
{
  "period": "week",
  "data": [
    {
      "date": "2024-01-14",
      "questionsAnswered": 45,
      "correctAnswers": 32,
      "accuracy": 71.1,
      "studyTimeMinutes": 120,
      "xpEarned": 180
    },
    {
      "date": "2024-01-15",
      "questionsAnswered": 52,
      "correctAnswers": 39,
      "accuracy": 75.0,
      "studyTimeMinutes": 150,
      "xpEarned": 225
    }
  ]
}
```

### GET /analytics/weak-topics

Tópicos mais fracos do usuário

**Response:**
```json
{
  "weakTopics": [
    {
      "subject": "Pediatria",
      "topic": "Neonatologia",
      "questionsAnswered": 42,
      "correctAnswers": 18,
      "accuracy": 42.9,
      "recommendedActions": [
        "Revisar flashcards de Neonatologia",
        "Fazer questões focadas neste tópico"
      ]
    }
  ]
}
```

## Subscription Endpoints

### GET /subscription/plans

Listar planos disponíveis

**Response:**
```json
{
  "plans": [
    {
      "id": "plan_free",
      "name": "Gratuito",
      "price": 0,
      "features": [
        "10 questões por dia",
        "Estatísticas básicas",
        "1 simulado por mês"
      ]
    },
    {
      "id": "plan_pro",
      "name": "PRO",
      "price": 79.90,
      "interval": "month",
      "features": [
        "Questões ilimitadas",
        "Estatísticas avançadas",
        "Simulados ilimitados",
        "Grey AI sem limites",
        "Plano de estudos personalizado"
      ]
    }
  ]
}
```

### POST /subscription/checkout

Criar sessão de checkout (integração com Stripe/MercadoPago)

**Request:**
```json
{
  "planId": "plan_pro",
  "interval": "month"
}
```

**Response:**
```json
{
  "checkoutUrl": "https://checkout.stripe.com/...",
  "sessionId": "cs_abc123"
}
```

## Webhooks (Backend -> iOS via Push Notifications)

### Streak Reminder

Lembrete de streak diário (via APNS)

```json
{
  "type": "streak_reminder",
  "title": "Não perca seu streak! 🔥",
  "body": "Você está há 7 dias consecutivos estudando. Continue assim!",
  "data": {
    "streak": 7,
    "action": "open_app"
  }
}
```

### New Content Available

Novo conteúdo disponível

```json
{
  "type": "new_content",
  "title": "Novas questões adicionadas! 📚",
  "body": "50 questões de Cardiologia acabaram de ser adicionadas",
  "data": {
    "subject": "Cardiologia",
    "count": 50,
    "action": "open_questions"
  }
}
```

## Error Responses

Formato padrão de erro:

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Token inválido ou expirado",
    "details": {
      "field": "token",
      "reason": "expired"
    }
  }
}
```

**Códigos de erro comuns:**
- `UNAUTHORIZED` (401): Token inválido ou expirado
- `FORBIDDEN` (403): Usuário não tem permissão
- `NOT_FOUND` (404): Recurso não encontrado
- `VALIDATION_ERROR` (422): Dados inválidos
- `RATE_LIMIT_EXCEEDED` (429): Limite de requisições excedido
- `INTERNAL_ERROR` (500): Erro interno do servidor

## Rate Limiting

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1705750800
```

**Limites:**
- Free tier: 100 requests/hour
- PRO tier: 1000 requests/hour
- Endpoints de autenticação: 10 requests/hour (por IP)

## Pagination

Endpoints com listas suportam paginação:

**Query Parameters:**
- `limit` (default: 20, max: 100)
- `offset` (default: 0)

**Response Headers:**
```
X-Total-Count: 156
X-Page-Limit: 20
X-Page-Offset: 0
```

## Caching

**Headers de cache:**
```
Cache-Control: private, max-age=300
ETag: "33a64df551425fcc55e4d42a148795d9"
```

**Conditional requests:**
```
If-None-Match: "33a64df551425fcc55e4d42a148795d9"
```

Se não houver mudanças, retorna `304 Not Modified` sem body.
