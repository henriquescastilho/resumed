//
//  NetworkMonitor.swift
//  Resumed
//
//  Core Service - Network Connectivity Monitor
//

import Foundation
import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false // Cellular or hotspot

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown

        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "cellularbars"
            case .ethernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            }
        }

        var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Dados Móveis"
            case .ethernet: return "Ethernet"
            case .unknown: return "Desconhecido"
            }
        }
    }

    private init() {
        startMonitoring()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let isConnected = path.status == .satisfied
            let isExpensive = path.isExpensive
            let connectionType = self.getConnectionType(path)

            Task { @MainActor [weak self] in
                self?.isConnected = isConnected
                self?.isExpensive = isExpensive
                self?.connectionType = connectionType
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private nonisolated func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }

    // Check if we can make API calls
    var canMakeRequests: Bool {
        isConnected
    }

    // Check if we should download large content
    var shouldDownloadLargeContent: Bool {
        isConnected && !isExpensive
    }
}

// MARK: - Network Status View

import SwiftUI

struct NetworkStatusBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: IconSize.sm))

                Text("Sem conexão com a internet")
                    .font(.resumed.bodySmall)

                Spacer()

                Button("Tentar") {
                    // Trigger a refresh
                }
                .font(.resumed.caption)
                .foregroundColor(.resumed.gold)
            }
            .foregroundColor(.resumed.white)
            .padding(Spacing.sm)
            .background(Color.resumed.error)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

struct OfflineIndicator: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(Color.resumed.error)
                    .frame(width: 8, height: 8)

                Text("Offline")
                    .font(.resumed.caption)
                    .foregroundColor(.resumed.error)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.resumed.error.opacity(0.1))
            .cornerRadius(CornerRadius.round)
        }
    }
}

// MARK: - View Modifier

struct NetworkAwareModifier: ViewModifier {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    let showBanner: Bool

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if showBanner {
                NetworkStatusBanner()
            }
            content
        }
        .animation(.easeInOut, value: networkMonitor.isConnected)
    }
}

extension View {
    func networkAware(showBanner: Bool = true) -> some View {
        modifier(NetworkAwareModifier(showBanner: showBanner))
    }
}
