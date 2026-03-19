//
//  ExportPlanSheet.swift
//  Resumed
//
//  Phase 4 — Export options: ICS file + week image share
//

import SwiftUI

struct ExportPlanSheet: View {
    let days: [DayPlan]
    let weekRange: String
    @Environment(\.dismiss) var dismiss

    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isGenerating = false
    @State private var icsExported = false
    @State private var imageExported = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color.resumed.gold.opacity(0.1))
                                .frame(width: 64, height: 64)
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.resumed.gold)
                        }
                        .padding(.top, Spacing.md)

                        Text("Exportar Plano")
                            .font(.resumed.h4)
                            .foregroundColor(.resumed.white)

                        Text("Semana: \(weekRange)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }

                    // Summary
                    let taskCount = days.reduce(0) { $0 + $1.tasks.count }
                    let totalMins = days.reduce(0) { $0 + $1.totalMinutes }

                    ResumedCard(background: Color.resumed.blackTertiary) {
                        HStack(spacing: 0) {
                            ExportSummaryItem(
                                value: "\(days.filter { !$0.tasks.isEmpty }.count)",
                                label: "dias"
                            )
                            Divider()
                                .background(Color.resumed.border)
                                .frame(height: 32)
                            ExportSummaryItem(
                                value: "\(taskCount)",
                                label: "tarefas"
                            )
                            Divider()
                                .background(Color.resumed.border)
                                .frame(height: 32)
                            ExportSummaryItem(
                                value: totalMins >= 60 ? "\(totalMins / 60)h" : "\(totalMins)min",
                                label: "de estudo"
                            )
                        }
                    }

                    VStack(spacing: Spacing.sm) {
                        // ICS export
                        ExportOptionCard(
                            icon: "calendar.badge.plus",
                            iconColor: .resumed.info,
                            title: "Exportar como .ics",
                            subtitle: "Adicione as tarefas ao Apple Calendário, Google Calendar ou Outlook.",
                            badge: icsExported ? "Exportado" : nil,
                            badgeColor: .resumed.success,
                            isLoading: isGenerating,
                            action: { exportICS() }
                        )

                        // Image export
                        ExportOptionCard(
                            icon: "photo.fill",
                            iconColor: .resumed.gold,
                            title: "Compartilhar como Imagem",
                            subtitle: "Gere uma imagem do plano semanal para compartilhar em grupos e redes sociais.",
                            badge: imageExported ? "Compartilhado" : nil,
                            badgeColor: .resumed.success,
                            isLoading: false,
                            action: { exportImage() }
                        )
                    }

                    if let error = errorMessage {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.resumed.error)
                            Text(error)
                                .font(.resumed.caption)
                                .foregroundColor(.resumed.error)
                        }
                        .padding(Spacing.sm)
                        .background(Color.resumed.error.opacity(0.08))
                        .cornerRadius(CornerRadius.md)
                    }

                    Spacer(minLength: Spacing.lg)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.resumed.black)
            .navigationTitle("Exportar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: shareItems)
            }
        }
    }

    // MARK: - Actions

    private func exportICS() {
        isGenerating = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) { [days] in
            let url = CalendarExportService.shared.exportICSFile(for: days)
            await MainActor.run {
                isGenerating = false
                if let url {
                    shareItems = [url]
                    showShareSheet = true
                    icsExported = true
                    HapticManager.shared.success()
                } else {
                    errorMessage = "Não foi possível gerar o arquivo .ics."
                    HapticManager.shared.notification(.error)
                }
            }
        }
    }

    @MainActor
    private func exportImage() {
        errorMessage = nil
        Task {
            let image = await CalendarExportService.shared.renderWeekAsImage(days: days, weekRange: weekRange)
            if let image {
                shareItems = [image]
                showShareSheet = true
                imageExported = true
                HapticManager.shared.success()
            } else {
                errorMessage = "Não foi possível gerar a imagem."
                HapticManager.shared.notification(.error)
            }
        }
    }
}

// MARK: - Export Option Card

private struct ExportOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let badge: String?
    let badgeColor: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ResumedCard {
                HStack(spacing: Spacing.md) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(iconColor.opacity(0.12))
                            .frame(width: 48, height: 48)

                        if isLoading {
                            ProgressView()
                                .tint(iconColor)
                        } else {
                            Image(systemName: icon)
                                .font(.system(size: IconSize.lg))
                                .foregroundColor(iconColor)
                        }
                    }

                    // Text
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(spacing: Spacing.sm) {
                            Text(title)
                                .font(.resumed.body)
                                .fontWeight(.medium)
                                .foregroundColor(.resumed.white)

                            if let badge {
                                Text(badge)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(badgeColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(badgeColor.opacity(0.12))
                                    .cornerRadius(CornerRadius.sm)
                            }
                        }

                        Text(subtitle)
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.resumed.gray)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - Export Summary Item

private struct ExportSummaryItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.resumed.white)
            Text(label)
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)
        }
        .frame(maxWidth: .infinity)
    }
}
