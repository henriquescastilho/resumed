//
//  StoreKitManager.swift
//  Resumed
//
//  StoreKit 2 - In-App Purchases & Subscriptions
//

import Foundation
import StoreKit
import Combine

// MARK: - Product IDs

enum ProductID: String, CaseIterable {
    case monthly = "com.resumed.pro.monthly"
    case yearly = "com.resumed.pro.yearly"
    case lifetime = "com.resumed.pro.lifetime"

    var displayName: String {
        switch self {
        case .monthly: return "Mensal"
        case .yearly: return "Anual"
        case .lifetime: return "Lifetime"
        }
    }

    var description: String {
        switch self {
        case .monthly: return "Acesso PRO por 1 mês"
        case .yearly: return "Acesso PRO por 1 ano (50% off)"
        case .lifetime: return "Acesso PRO para sempre"
        }
    }

    var badge: String? {
        switch self {
        case .yearly: return "POPULAR"
        case .lifetime: return "MELHOR VALOR"
        default: return nil
        }
    }
}

// MARK: - Store Kit Manager

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var isPro: Bool = false

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            products.sort { p1, p2 in
                p1.price < p2.price
            }
            isLoading = false
        } catch {
            errorMessage = "Erro ao carregar planos: \(error.localizedDescription)"
            isLoading = false
            print("❌ Failed to load products: \(error)")

            // Load mock products for development
            loadMockProducts()
        }
    }

    private func loadMockProducts() {
        // Mock products for development when StoreKit isn't configured
        // In production, remove this
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Update purchased products
                await updatePurchasedProducts()

                // Finish transaction
                await transaction.finish()

                isLoading = false

                // Track purchase
                FirebaseManager.shared.trackSubscription(
                    plan: product.id,
                    price: NSDecimalNumber(decimal: product.price).doubleValue,
                    currency: product.priceFormatStyle.currencyCode
                )

                return transaction

            case .userCancelled:
                isLoading = false
                return nil

            case .pending:
                isLoading = false
                errorMessage = "Compra pendente de aprovação"
                return nil

            @unknown default:
                isLoading = false
                return nil
            }
        } catch {
            isLoading = false
            errorMessage = "Erro na compra: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            isLoading = false

            if purchasedProductIDs.isEmpty {
                errorMessage = "Nenhuma compra encontrada para restaurar"
            }
        } catch {
            isLoading = false
            errorMessage = "Erro ao restaurar: \(error.localizedDescription)"
        }
    }

    // MARK: - Update Purchased Products

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if subscription is still valid
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }

        purchasedProductIDs = purchased
        isPro = !purchased.isEmpty

        // Update user defaults for quick access
        UserDefaults.standard.set(isPro, forKey: "isPro")

        // Update Firebase user property
        FirebaseManager.shared.setUserProperty(isPro ? "pro" : "free", forName: "subscription_status")
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    await self.updatePurchasedProducts()

                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helpers

    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    func isPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }

    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    func pricePerMonth(for product: Product) -> String? {
        guard let subscription = product.subscription else { return nil }

        let price = product.price
        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value

        let monthlyPrice: Decimal
        switch unit {
        case .year:
            monthlyPrice = price / Decimal(12 * value)
        case .month:
            monthlyPrice = price / Decimal(value)
        case .week:
            monthlyPrice = price * Decimal(4) / Decimal(value)
        case .day:
            monthlyPrice = price * Decimal(30) / Decimal(value)
        @unknown default:
            return nil
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")

        return formatter.string(from: monthlyPrice as NSDecimalNumber)
    }
}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Falha na verificação da compra"
        case .productNotFound:
            return "Produto não encontrado"
        case .purchaseFailed:
            return "Falha na compra"
        }
    }
}

// MARK: - Pro Features

struct ProFeatures {
    static let shared = ProFeatures()

    private var isPro: Bool {
        UserDefaults.standard.bool(forKey: "isPro")
    }

    // MARK: - Feature Limits

    var dailyQuestionLimit: Int {
        isPro ? .max : 10
    }

    var dailyFlashcardLimit: Int {
        isPro ? .max : 5
    }

    var monthlyExamLimit: Int {
        isPro ? .max : 1
    }

    var dailyGreyQuestionLimit: Int {
        isPro ? .max : 5
    }

    var canAccessAdvancedStats: Bool {
        isPro
    }

    var canAccessPersonalizedPlan: Bool {
        isPro
    }

    var canAccessOfflineMode: Bool {
        isPro
    }

    var hasAds: Bool {
        !isPro
    }

    var hasExclusiveBadge: Bool {
        isPro
    }

    // MARK: - Check Usage

    func canAnswerMoreQuestions(todayCount: Int) -> Bool {
        isPro || todayCount < dailyQuestionLimit
    }

    func canReviewMoreFlashcards(todayCount: Int) -> Bool {
        isPro || todayCount < dailyFlashcardLimit
    }

    func canTakeMoreExams(monthCount: Int) -> Bool {
        isPro || monthCount < monthlyExamLimit
    }

    func canAskGrey(todayCount: Int) -> Bool {
        isPro || todayCount < dailyGreyQuestionLimit
    }

    // MARK: - Remaining

    func remainingQuestions(todayCount: Int) -> Int {
        max(0, dailyQuestionLimit - todayCount)
    }

    func remainingFlashcards(todayCount: Int) -> Int {
        max(0, dailyFlashcardLimit - todayCount)
    }

    func remainingGreyQuestions(todayCount: Int) -> Int {
        max(0, dailyGreyQuestionLimit - todayCount)
    }
}

// MARK: - Mock Products for Development

extension StoreKitManager {
    struct MockProduct {
        let id: ProductID
        let price: String
        let priceValue: Decimal

        static let monthly = MockProduct(id: .monthly, price: "R$ 79,90", priceValue: 79.90)
        static let yearly = MockProduct(id: .yearly, price: "R$ 599,90", priceValue: 599.90)
        static let lifetime = MockProduct(id: .lifetime, price: "R$ 1.999,90", priceValue: 1999.90)

        static let all = [monthly, yearly, lifetime]
    }
}
