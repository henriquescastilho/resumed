//
//  AuthManager.swift
//  Resumed
//
//  Core Service - Authentication Manager
//

import Foundation
import SwiftUI
import Combine

// MARK: - Auth Manager

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false

    var accessToken: String? {
        KeychainHelper.get(key: "accessToken")
    }

    private var refreshToken: String? {
        KeychainHelper.get(key: "refreshToken")
    }

    private init() {
        checkAuthStatus()
    }

    private func checkAuthStatus() {
        isAuthenticated = accessToken != nil
    }

    func signInWithGoogle(idToken: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

        let response: AuthResponse
        if APIClient.mode == .mock {
            response = try await MockAPIClient.shared.login(with: idToken, deviceId: deviceId)
        } else {
            response = try await APIClient.shared.login(with: idToken, deviceId: deviceId)
        }

        KeychainHelper.save(key: "accessToken", value: response.accessToken)
        KeychainHelper.save(key: "refreshToken", value: response.refreshToken)

        currentUser = response.user
        isAuthenticated = true
    }

    func signOut() async {
        KeychainHelper.delete(key: "accessToken")
        KeychainHelper.delete(key: "refreshToken")

        currentUser = nil
        isAuthenticated = false
    }

    func refreshToken() async throws {
        // Skip refresh in mock mode
        guard APIClient.mode != .mock else { return }

        guard let refresh = refreshToken else {
            throw APIError.unauthorized
        }

        let response = try await APIClient.shared.request(
            endpoint: "/auth/refresh",
            method: .post,
            body: RefreshTokenRequest(refreshToken: refresh),
            requiresAuth: false
        ) as RefreshTokenResponse

        KeychainHelper.save(key: "accessToken", value: response.accessToken)
    }
}

// MARK: - Keychain Helper

class KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
