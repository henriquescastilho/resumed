//
//  PaywallView.swift
//  Resumed
//
//  PRO Subscription Paywall
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var storeKit = StoreKitManager.shared
    @State private var selectedProduct: ProductID = .yearly
    @State private var showRestoreAlert = false
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.resumed.black, Color.resumed.blackSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    PaywallHeader()

                    // Features
                    ProFeaturesSection()

                    // Plans
                    PlansSection(selectedProduct: $selectedProduct, storeKit: storeKit)

                    // Subscribe Button
                    SubscribeButton(selectedProduct: selectedProduct, storeKit: storeKit) {
                        showErrorAlert = true
                    }

                    // Restore & Terms
                    FooterLinks(storeKit: storeKit) {
                        showRestoreAlert = true
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.resumed.gray)
                    }
                    .padding(Spacing.md)
                }
                Spacer()
            }

            // Loading overlay
            if storeKit.isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .resumed.gold))
                            .scaleEffect(1.5)
                    )
            }
        }
        .alert("Compras restauradas", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(storeKit.isPro ? "Seu acesso PRO foi restaurado!" : "Nenhuma compra encontrada.")
        }
        .alert("Erro", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(storeKit.errorMessage ?? "Ocorreu um erro. Tente novamente.")
        }
        .onAppear {
        }
    }
}

// MARK: - Header

struct PaywallHeader: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            // PRO Badge
            ZStack {
                Circle()
                    .fill(Color.resumed.gold.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animate ? 1.1 : 1)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)

                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.resumed.gold, Color.resumed.goldLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("RESUMED PRO")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.resumed.gold, Color.resumed.goldLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Desbloqueie todo o potencial para sua aprovação")
                .font(.resumed.body)
                .foregroundColor(.resumed.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.xl)
        .onAppear { animate = true }
    }
}

// MARK: - Features Section

struct ProFeaturesSection: View {
    let features = [
        ProFeatureItem(icon: "infinity", title: "Questões ilimitadas", description: "Sem limite diário"),
        ProFeatureItem(icon: "rectangle.stack.fill", title: "Flashcards ilimitados", description: "Revise à vontade"),
        ProFeatureItem(icon: "doc.text.fill", title: "Simulados ilimitados", description: "Pratique sem restrições"),
        ProFeatureItem(icon: "brain.head.profile", title: "Grey AI ilimitado", description: "Pergunte o quanto quiser"),
        ProFeatureItem(icon: "chart.bar.fill", title: "Estatísticas avançadas", description: "Radar chart, predições"),
        ProFeatureItem(icon: "calendar.badge.clock", title: "Plano personalizado", description: "Criado por IA"),
        ProFeatureItem(icon: "arrow.down.circle.fill", title: "Modo offline", description: "Estude sem internet"),
        ProFeatureItem(icon: "crown.fill", title: "Badge exclusivo", description: "Destaque seu perfil")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("O que você ganha")
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)

            VStack(spacing: Spacing.sm) {
                ForEach(features, id: \.title) { feature in
                    HStack(spacing: Spacing.md) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 18))
                            .foregroundColor(.resumed.gold)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(.resumed.body)
                                .foregroundColor(.resumed.white)

                            Text(feature.description)
                                .font(.resumed.caption)
                                .foregroundColor(.resumed.gray)
                        }

                        Spacer()

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.resumed.success)
                    }
                    .padding(Spacing.sm)
                    .background(Color.resumed.blackSecondary)
                    .cornerRadius(CornerRadius.md)
                }
            }
        }
    }
}

struct ProFeatureItem {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Plans Section

struct PlansSection: View {
    @Binding var selectedProduct: ProductID
    @ObservedObject var storeKit: StoreKitManager

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Escolha seu plano")
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)

            VStack(spacing: Spacing.sm) {
                // Use real products if available, otherwise mock
                if storeKit.products.isEmpty {
                    // Mock plans for development
                    ForEach(StoreKitManager.MockProduct.all, id: \.id) { mockProduct in
                        PlanCard(
                            productID: mockProduct.id,
                            price: mockProduct.price,
                            pricePerMonth: mockProduct.id == .yearly ? "R$ 49,99/mês" : nil,
                            isSelected: selectedProduct == mockProduct.id,
                            badge: mockProduct.id.badge
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedProduct = mockProduct.id
                            }
                            HapticManager.shared.selection()
                        }
                    }
                } else {
                    // Real StoreKit products
                    ForEach(storeKit.products, id: \.id) { product in
                        if let productID = ProductID(rawValue: product.id) {
                            PlanCard(
                                productID: productID,
                                price: product.displayPrice,
                                pricePerMonth: storeKit.pricePerMonth(for: product),
                                isSelected: selectedProduct == productID,
                                badge: productID.badge
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedProduct = productID
                                }
                                HapticManager.shared.selection()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PlanCard: View {
    let productID: ProductID
    let price: String
    let pricePerMonth: String?
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.resumed.gold : Color.resumed.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.resumed.gold)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(productID.displayName)
                            .font(.resumed.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.resumed.white)

                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.resumed.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.resumed.gold)
                                .cornerRadius(4)
                        }
                    }

                    Text(productID.description)
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.resumed.h4)
                        .foregroundColor(isSelected ? .resumed.gold : .resumed.white)

                    if let perMonth = pricePerMonth {
                        Text(perMonth)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.resumed.gold.opacity(0.1) : Color.resumed.blackSecondary)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.resumed.gold : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Subscribe Button

struct SubscribeButton: View {
    let selectedProduct: ProductID
    @ObservedObject var storeKit: StoreKitManager
    let onError: () -> Void

    var body: some View {
        Button {
            Task {
                if let product = storeKit.product(for: selectedProduct) {
                    do {
                        _ = try await storeKit.purchase(product)
                    } catch {
                        onError()
                    }
                } else {
                    // Mock purchase for development
                    HapticManager.shared.success()
                    // In production, show error
                }
            }
        } label: {
            HStack {
                Image(systemName: "crown.fill")
                Text("Assinar \(selectedProduct.displayName)")
            }
            .font(.resumed.button)
            .foregroundColor(.resumed.black)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
            .background(
                LinearGradient(
                    colors: [Color.resumed.gold, Color.resumed.goldLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(CornerRadius.md)
            .shadow(color: Color.resumed.gold.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(storeKit.isLoading)
    }
}

// MARK: - Footer Links

struct FooterLinks: View {
    @ObservedObject var storeKit: StoreKitManager
    let onRestore: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Restore purchases
            Button {
                Task {
                    await storeKit.restorePurchases()
                    onRestore()
                }
            } label: {
                Text("Restaurar compras")
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gold)
            }

            // Terms & Privacy
            HStack(spacing: Spacing.md) {
                Link("Termos de Uso", destination: URL(string: "https://resumed.app/terms")!)
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)

                Text("•")
                    .foregroundColor(.resumed.gray)

                Link("Política de Privacidade", destination: URL(string: "https://resumed.app/privacy")!)
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gray)
            }

            // Subscription info
            Text("A assinatura será renovada automaticamente. Você pode cancelar a qualquer momento nas configurações do iPhone.")
                .font(.system(size: 10))
                .foregroundColor(.resumed.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
    }
}

// MARK: - Compact Paywall (for inline usage)

struct CompactPaywallBanner: View {
    @State private var showPaywall = false

    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.resumed.gold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Desbloqueie o PRO")
                        .font(.resumed.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.resumed.white)

                    Text("Questões e flashcards ilimitados")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)
                }

                Spacer()

                Text("Ver planos")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.gold)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.resumed.gold)
            }
            .padding(Spacing.md)
            .background(
                LinearGradient(
                    colors: [Color.resumed.gold.opacity(0.1), Color.resumed.blackSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.resumed.gold.opacity(0.3), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Limit Reached View

struct LimitReachedView: View {
    let limitType: String
    let currentCount: Int
    let maxCount: Int
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.resumed.gold)

            Text("Limite atingido")
                .font(.resumed.h3)
                .foregroundColor(.resumed.white)

            Text("Você usou \(currentCount)/\(maxCount) \(limitType) gratuitos hoje.")
                .font(.resumed.body)
                .foregroundColor(.resumed.gray)
                .multilineTextAlignment(.center)

            ResumedButton(
                title: "Desbloquear PRO",
                style: .primary,
                action: { showPaywall = true },
                icon: "crown.fill",
                fullWidth: true
            )
            .padding(.horizontal, Spacing.lg)
        }
        .padding(Spacing.xl)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
