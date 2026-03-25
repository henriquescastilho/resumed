//
//  SettingsView.swift
//  Resumed
//
//  Settings View - App Configuration
//

import SwiftUI
import Combine

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Profile Section
                ProfileSection(user: appState.user)

                // Study Preferences
                StudyPreferencesSection(viewModel: viewModel)

                // Notifications
                NotificationsSection(viewModel: viewModel)

                // App Settings
                AppSettingsSection(viewModel: viewModel)

                // Data & Storage
                DataStorageSection(viewModel: viewModel)

                // About
                AboutSection()

                // Logout
                LogoutSection(viewModel: viewModel)

                // Delete Account
                DeleteAccountSection(viewModel: viewModel)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Layout.tabBarHeight + Spacing.lg)
        }
        .background(Color.resumed.black)
        .navigationTitle("Configurações")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sair da conta?", isPresented: $viewModel.showLogoutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Sair", role: .destructive) {
                Task { await viewModel.logout(appState: appState) }
            }
        } message: {
            Text("Você precisará fazer login novamente.")
        }
        .alert("Limpar dados?", isPresented: $viewModel.showClearDataAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Limpar", role: .destructive) {
                viewModel.clearLocalData()
            }
        } message: {
            Text("Isso irá remover todos os dados locais. Seus dados na nuvem serão mantidos.")
        }
        .alert("Excluir conta?", isPresented: $viewModel.showDeleteAccountAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Quero excluir", role: .destructive) {
                viewModel.showDeleteAccountConfirmation = true
            }
        } message: {
            Text("Todos os seus dados serão permanentemente removidos, incluindo progresso, questões respondidas e flashcards. Essa ação não pode ser desfeita.")
        }
        .alert("Tem certeza absoluta?", isPresented: $viewModel.showDeleteAccountConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Excluir minha conta", role: .destructive) {
                Task { await viewModel.deleteAccount(appState: appState) }
            }
        } message: {
            Text("Última chance. Ao confirmar, sua conta e todos os dados associados serão excluídos permanentemente.")
        }
    }
}

@MainActor
class SettingsViewModel: ObservableObject {
    // Study Preferences
    @Published var dailyGoal: Int = 20
    @Published var selectedExam: String = "ENAMED"
    @Published var examDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 180) // 6 months
    @Published var studyHoursPerDay: Int = 4
    @Published var subjectPriority: [String] = []
    @Published var showPrioritySheet = false

    // Notifications
    @Published var notificationsEnabled = true
    @Published var dailyReminderEnabled = true
    @Published var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var streakReminder = true

    // App Settings
    @Published var hapticFeedback = true
    @Published var soundEffects = true
    @Published var autoPlayExplanations = false

    // Alerts
    @Published var showLogoutAlert = false
    @Published var showClearDataAlert = false
    @Published var showDeleteAccountAlert = false
    @Published var showDeleteAccountConfirmation = false
    @Published var isDeletingAccount = false

    let examOptions = ["ENAMED", "USP", "UNICAMP", "UNIFESP", "SUS-SP", "ENARE", "Outro"]
    let dailyGoalOptions = [10, 15, 20, 30, 50]
    let subjects = [
        "Clínica Médica",
        "Cirurgia Geral",
        "Ginecologia e Obstetrícia",
        "Pediatria",
        "MFC",
        "Saúde Mental",
        "Saúde Coletiva"
    ]

    init() {
        loadSettings()
    }

    func loadSettings() {
        dailyGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
        if dailyGoal == 0 { dailyGoal = 20 }

        selectedExam = UserDefaults.standard.string(forKey: "targetExam")
            ?? UserDefaults.standard.string(forKey: "selectedExam")
            ?? "ENAMED"
        studyHoursPerDay = UserDefaults.standard.integer(forKey: "studyHoursPerDay")
        if studyHoursPerDay == 0 { studyHoursPerDay = 4 }
        subjectPriority = UserDefaults.standard.stringArray(forKey: "subjectPriority") ?? subjects
        hapticFeedback = UserDefaults.standard.bool(forKey: "hapticFeedback")
        soundEffects = UserDefaults.standard.bool(forKey: "soundEffects")
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        dailyReminderEnabled = UserDefaults.standard.bool(forKey: "dailyReminderEnabled")
        streakReminder = UserDefaults.standard.bool(forKey: "streakReminder")

        if let examDateTimestamp = UserDefaults.standard.object(forKey: "examDate") as? Date {
            examDate = examDateTimestamp
        }

        if let reminderTimestamp = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
            reminderTime = reminderTimestamp
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
        UserDefaults.standard.set(selectedExam, forKey: "selectedExam")
        UserDefaults.standard.set(selectedExam, forKey: "targetExam")
        UserDefaults.standard.set(examDate, forKey: "examDate")
        UserDefaults.standard.set(studyHoursPerDay, forKey: "studyHoursPerDay")
        UserDefaults.standard.set(subjectPriority, forKey: "subjectPriority")
        UserDefaults.standard.set(hapticFeedback, forKey: "hapticFeedback")
        UserDefaults.standard.set(soundEffects, forKey: "soundEffects")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(dailyReminderEnabled, forKey: "dailyReminderEnabled")
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
        UserDefaults.standard.set(streakReminder, forKey: "streakReminder")
    }

    func logout(appState: AppState) async {
        await AuthManager.shared.signOut()
        appState.isAuthenticated = false
        appState.user = nil
    }

    func deleteAccount(appState: AppState) async {
        isDeletingAccount = true
        await appState.deleteAccount()
        isDeletingAccount = false
    }

    func clearLocalData() {
        CoreDataManager.shared.clearAllData()
        let keysToClear = [
            "hasCompletedOnboarding",
            "subjectPriority",
            "targetExam",
            "selectedExam",
            "examDate",
            "studyHoursPerDay",
            "dailyGoal",
            "hapticFeedback",
            "soundEffects",
            "notificationsEnabled",
            "dailyReminderEnabled",
            "reminderTime",
            "streakReminder",
            "grey_last_interaction_date",
            "grey_interaction_count",
            "grey_saved_drafts"
        ]
        keysToClear.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        HapticManager.shared.notification(.success)
    }

    func calculateStorageUsed() -> String {
        // Simplified - in real app would calculate actual Core Data size
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var totalSize: Int64 = 0

        if let enumerator = FileManager.default.enumerator(at: documentsPath, includingPropertiesForKeys: [.fileSizeKey]) {
            while let fileURL = enumerator.nextObject() as? URL {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}

// MARK: - Profile Section

struct ProfileSection: View {
    let user: User?

    var body: some View {
        ResumedCard {
            HStack(spacing: Spacing.md) {
                // Avatar
                Circle()
                    .fill(Color.resumed.gold.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(user?.name.prefix(1).uppercased() ?? "R")
                            .font(.resumed.h2)
                            .foregroundColor(.resumed.gold)
                    )

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(user?.name ?? "Estudante")
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.white)

                    Text(user?.email ?? "")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gray)

                    Text("Level \(GamificationManager.shared.level)")
                        .font(.resumed.caption)
                        .foregroundColor(.resumed.gold)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.resumed.gray)
            }
        }
    }
}

// MARK: - Study Preferences Section

struct StudyPreferencesSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Preferências de Estudo", icon: "book.fill")

            ResumedCard {
                VStack(spacing: Spacing.md) {
                    // Target Exam
                    SettingsRow(title: "Prova Alvo", value: viewModel.selectedExam) {
                        Picker("Prova", selection: $viewModel.selectedExam) {
                            ForEach(viewModel.examOptions, id: \.self) { exam in
                                Text(exam).tag(exam)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.resumed.gold)
                    }

                    Divider().background(Color.resumed.border)

                    SettingsRow(title: "Horas por dia", value: "\(viewModel.studyHoursPerDay)h") {
                        Stepper(value: $viewModel.studyHoursPerDay, in: 1...12, step: 1) {
                            Text("\(viewModel.studyHoursPerDay)h")
                                .font(.resumed.bodySmall)
                                .foregroundColor(.resumed.white)
                        }
                    }

                    Divider().background(Color.resumed.border)

                    SettingsRow(title: "Prioridade de matérias", value: "Editar") {
                        Button("Editar") { viewModel.showPrioritySheet = true }
                            .foregroundColor(.resumed.gold)
                    }

                    Divider().background(Color.resumed.border)

                    // Exam Date
                    HStack {
                        Text("Data da Prova")
                            .font(.resumed.body)
                            .foregroundColor(.resumed.white)

                        Spacer()

                        DatePicker("", selection: $viewModel.examDate, displayedComponents: .date)
                            .labelsHidden()
                            .tint(.resumed.gold)
                            .colorScheme(.dark)
                    }

                    Divider().background(Color.resumed.border)

                    // Daily Goal
                    SettingsRow(title: "Meta Diária", value: "\(viewModel.dailyGoal) questões") {
                        Picker("Meta", selection: $viewModel.dailyGoal) {
                            ForEach(viewModel.dailyGoalOptions, id: \.self) { goal in
                                Text("\(goal)").tag(goal)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.resumed.gold)
                    }
                }
            }
        }
        .onChange(of: viewModel.dailyGoal) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.selectedExam) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.studyHoursPerDay) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.examDate) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.subjectPriority) { _, _ in viewModel.saveSettings() }
        .sheet(isPresented: $viewModel.showPrioritySheet) {
            SubjectPrioritySheet(subjects: $viewModel.subjectPriority)
        }
    }
}

private struct SubjectPrioritySheet: View {
    @Binding var subjects: [String]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(subjects, id: \.self) { subject in
                    Text(subject)
                        .font(.resumed.body)
                        .foregroundColor(.resumed.white)
                }
                .onMove { indices, newOffset in
                    subjects.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.resumed.black)
            .navigationTitle("Prioridade de matérias")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .foregroundColor(.resumed.gold)
                }
            }
        }
    }
}

// MARK: - Notifications Section

struct NotificationsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Notificações", icon: "bell.fill")

            ResumedCard {
                VStack(spacing: Spacing.md) {
                    SettingsToggle(title: "Notificações", isOn: $viewModel.notificationsEnabled)

                    if viewModel.notificationsEnabled {
                        Divider().background(Color.resumed.border)

                        SettingsToggle(title: "Lembrete Diário", isOn: $viewModel.dailyReminderEnabled)

                        if viewModel.dailyReminderEnabled {
                            HStack {
                                Text("Horário")
                                    .font(.resumed.body)
                                    .foregroundColor(.resumed.gray)

                                Spacer()

                                DatePicker("", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .tint(.resumed.gold)
                                    .colorScheme(.dark)
                            }
                        }

                        Divider().background(Color.resumed.border)

                        SettingsToggle(title: "Alerta de Streak", isOn: $viewModel.streakReminder)
                    }
                }
            }
        }
        .onChange(of: viewModel.notificationsEnabled) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.dailyReminderEnabled) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.reminderTime) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.streakReminder) { _, _ in viewModel.saveSettings() }
    }
}

// MARK: - App Settings Section

struct AppSettingsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Aplicativo", icon: "gearshape.fill")

            ResumedCard {
                VStack(spacing: Spacing.md) {
                    SettingsToggle(title: "Vibração", isOn: $viewModel.hapticFeedback)

                    Divider().background(Color.resumed.border)

                    SettingsToggle(title: "Sons", isOn: $viewModel.soundEffects)

                    Divider().background(Color.resumed.border)

                    SettingsToggle(title: "Auto-play Explicações", isOn: $viewModel.autoPlayExplanations)
                }
            }
        }
        .onChange(of: viewModel.hapticFeedback) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.soundEffects) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.autoPlayExplanations) { _, _ in viewModel.saveSettings() }
    }
}

// MARK: - Data & Storage Section

struct DataStorageSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Dados e Armazenamento", icon: "internaldrive.fill")

            ResumedCard {
                VStack(spacing: Spacing.md) {
                    HStack {
                        Text("Armazenamento Local")
                            .font(.resumed.body)
                            .foregroundColor(.resumed.white)

                        Spacer()

                        Text(viewModel.calculateStorageUsed())
                            .font(.resumed.body)
                            .foregroundColor(.resumed.gray)
                    }

                    Divider().background(Color.resumed.border)

                    Button {
                        viewModel.showClearDataAlert = true
                    } label: {
                        HStack {
                            Text("Limpar Dados Locais")
                                .font(.resumed.body)
                                .foregroundColor(.resumed.error)

                            Spacer()

                            Image(systemName: "trash")
                                .foregroundColor(.resumed.error)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Sobre", icon: "info.circle.fill")

            ResumedCard {
                VStack(spacing: Spacing.md) {
                    SettingsLinkRow(title: "Versão", value: "1.0.0 (1)")

                    Divider().background(Color.resumed.border)

                    SettingsLinkRow(title: "Termos de Uso", icon: "doc.text") {
                        showTerms = true
                    }

                    Divider().background(Color.resumed.border)

                    SettingsLinkRow(title: "Política de Privacidade", icon: "hand.raised") {
                        showPrivacy = true
                    }

                    Divider().background(Color.resumed.border)

                    SettingsLinkRow(title: "Suporte", icon: "questionmark.circle") {
                        // Open support
                    }

                    Divider().background(Color.resumed.border)

                    SettingsLinkRow(title: "Avaliar App", icon: "star") {
                        // Open App Store review
                    }

                    Divider().background(Color.resumed.border)

                    HStack {
                        Spacer()
                        Text("Desenvolvido por DME TECHNOLOGY")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.resumed.gray.opacity(0.5))
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            LegalView(type: .termsOfUse)
        }
        .sheet(isPresented: $showPrivacy) {
            LegalView(type: .privacyPolicy)
        }
    }
}

// MARK: - Logout Section

struct LogoutSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Button {
            viewModel.showLogoutAlert = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sair da Conta")
            }
            .font(.resumed.body)
            .foregroundColor(.resumed.error)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(Color.resumed.error.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Delete Account Section

struct DeleteAccountSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Button {
            viewModel.showDeleteAccountAlert = true
        } label: {
            HStack {
                if viewModel.isDeletingAccount {
                    ProgressView()
                        .tint(.resumed.error)
                } else {
                    Image(systemName: "person.crop.circle.badge.minus")
                    Text("Excluir Conta")
                }
            }
            .font(.resumed.bodySmall)
            .foregroundColor(.resumed.error.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(Spacing.sm)
        }
        .disabled(viewModel.isDeletingAccount)
    }
}

// MARK: - Helper Components

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.resumed.gold)

            Text(title)
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)
        }
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let value: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(title)
                .font(.resumed.body)
                .foregroundColor(.resumed.white)

            Spacer()

            content
        }
    }
}

struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.resumed.body)
                .foregroundColor(.resumed.white)
        }
        .tint(.resumed.gold)
    }
}

struct SettingsLinkRow: View {
    let title: String
    var value: String? = nil
    var icon: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(title)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.white)

                Spacer()

                if let value = value {
                    Text(value)
                        .font(.resumed.body)
                        .foregroundColor(.resumed.gray)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.resumed.gray)
                }

                if action != nil && value == nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.resumed.gray)
                }
            }
        }
        .disabled(action == nil)
    }
}
