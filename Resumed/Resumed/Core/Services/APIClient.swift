//
//  APIClient.swift
//  Resumed
//
//  Core Service - API Client
//

import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case validationError(message: String)
    case serverError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    case offline

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .invalidResponse: return "Resposta inválida"
        case .unauthorized: return "Sessão expirada"
        case .forbidden: return "Acesso negado"
        case .notFound: return "Não encontrado"
        case .validationError(let msg): return msg
        case .serverError(let code): return "Erro do servidor (\(code))"
        case .networkError: return "Erro de rede"
        case .decodingError: return "Erro ao processar dados"
        case .offline: return "Sem conexão"
        }
    }
}

// MARK: - API Client

@MainActor
class APIClient {
    static let shared = APIClient()

    #if DEBUG
    private let baseURL = "https://dev-api.resumed.app/v1"
    #else
    private let baseURL = "https://api.resumed.app/v1"
    #endif

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true,
        retryOnUnauthorized: Bool = true
    ) async throws -> T {
        // Check network connectivity first
        guard NetworkMonitor.shared.isConnected else {
            throw APIError.offline
        }

        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth, let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.decodingError(error)
            }
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            // Handle empty response for void endpoints
            if data.isEmpty, T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            // Try to refresh token and retry once
            if retryOnUnauthorized && requiresAuth {
                do {
                    try await AuthManager.shared.refreshToken()
                    return try await self.request(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        queryItems: queryItems,
                        requiresAuth: requiresAuth,
                        retryOnUnauthorized: false
                    )
                } catch {
                    throw APIError.unauthorized
                }
            }
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            // Validation error - try to parse error message
            if let errorResponse = try? decoder.decode(ValidationErrorResponse.self, from: data) {
                throw APIError.validationError(message: errorResponse.message)
            }
            throw APIError.validationError(message: "Dados inválidos")
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.invalidResponse
        }
    }
}

// MARK: - API Extensions

extension APIClient {
    // Auth
    func login(with idToken: String, deviceId: String) async throws -> AuthResponse {
        return try await request(
            endpoint: "/auth/google",
            method: .post,
            body: GoogleAuthRequest(idToken: idToken, deviceId: deviceId),
            requiresAuth: false
        )
    }

    // User
    func getUserProfile() async throws -> User {
        return try await request(endpoint: "/user/profile")
    }

    func getUserStats() async throws -> UserStats {
        return try await request(endpoint: "/user/stats")
    }

    // Study Plan
    func getStudyPlan() async throws -> StudyPlan {
        return try await request(endpoint: "/study-plan")
    }

    func completeTask(taskId: String) async throws -> CompleteTaskResponse {
        return try await request(endpoint: "/study-plan/tasks/\(taskId)/complete", method: .post)
    }

    // Questions
    func getQuestions(subjects: [String], count: Int, difficulty: QuestionDifficulty?) async throws -> [Question] {
        var queryItems = [URLQueryItem(name: "count", value: String(count))]
        for subject in subjects {
            queryItems.append(URLQueryItem(name: "subjects[]", value: subject))
        }
        return try await request(endpoint: "/questions", queryItems: queryItems)
    }

    // FlashCards
    func getFlashCardsDue() async throws -> FlashCardsDueResponse {
        return try await request(endpoint: "/flashcards/due")
    }

    func reviewFlashCard(cardId: String, quality: Int) async throws -> FlashCardReviewResponse {
        return try await request(
            endpoint: "/flashcards/\(cardId)/review",
            method: .post,
            body: FlashCardReviewRequest(quality: quality)
        )
    }

    func createFlashCard(front: String, back: String, subject: String, tags: [String]) async throws -> FlashCardDTO {
        return try await request(
            endpoint: "/flashcards",
            method: .post,
            body: CreateFlashCardRequest(front: front, back: back, subject: subject, tags: tags)
        )
    }

    // Exams
    func getPastExams() async throws -> [Exam] {
        return try await request(endpoint: "/exams")
    }

    // Gamification
    func updateUserXP(totalXP: Int, level: Int) async throws -> MessageResponse {
        return try await request(
            endpoint: "/user/xp",
            method: .put,
            body: UpdateXPRequest(totalXP: totalXP, level: level)
        )
    }

    func unlockBadge(_ badgeId: String) async throws -> MessageResponse {
        return try await request(endpoint: "/user/badges/\(badgeId)", method: .post)
    }
}

// MARK: - Response Models

struct MessageResponse: Codable {
    let message: String
}

struct EmptyResponse: Codable {}

struct ValidationErrorResponse: Codable {
    let message: String
    let errors: [String: [String]]?
}

// MARK: - Request Models

struct UpdateXPRequest: Codable {
    let totalXP: Int
    let level: Int
}

// MARK: - AnyEncodable Wrapper

struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        encodeClosure = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
