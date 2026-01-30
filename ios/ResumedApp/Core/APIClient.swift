import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
    case unauthorized
}

class APIClient {
    static let shared = APIClient()
    
    #if DEBUG
    private let baseURL = "http://localhost:8000/api/v1"
    #else
    // TODO: Replace with your actual Cloud Run URL
    private let baseURL = "https://YOUR-CLOUD-RUN-URL.run.app/api/v1" 
    #endif
    
    private init() {}
    
    // Helper to create requests with Auth header
    private func makeRequest(endpoint: String, method: String, body: Data? = nil, token: String? = nil) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }
        
        return data
    }
    
    // Models
    struct ProfileUpdatePayload: Encodable {
        let full_name: String?
        let target_exams: [String]
        let available_days: [Int]
        let hours_per_day: Int
        let level_assessment: [String: String]?
    }
    
    // Auth
    func login(idToken: String) async throws -> UserResponse {
        let payload = ["id_token": idToken]
        let body = try JSONEncoder().encode(payload)
        let data = try await makeRequest(endpoint: "/auth/login", method: "POST", body: body)
        let response = try JSONDecoder().decode(LoginResponse.self, from: data)
        return response.user
    }
    
    // Profile
    func getProfile(token: String) async throws -> UserProfile {
        let data = try await makeRequest(endpoint: "/profile/", method: "GET", token: token)
        let response = try JSONDecoder().decode(UserProfile.self, from: data)
        return response
    }
    
    func updateProfile(token: String, payload: ProfileUpdatePayload) async throws -> UserProfile {
        let body = try JSONEncoder().encode(payload)
        let data = try await makeRequest(endpoint: "/profile/", method: "PUT", body: body, token: token)
        let response = try JSONDecoder().decode(UserProfile.self, from: data)
        return response
    }
}

// Response Models needed for decoding
struct LoginResponse: Decodable {
    let user: UserResponse
}

struct UserResponse: Decodable {
    let id: String
    let full_name: String?
    let email: String
    let avatar_url: String?
}
