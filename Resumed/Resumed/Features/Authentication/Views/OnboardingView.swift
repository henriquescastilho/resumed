//
//  OnboardingView.swift
//  Resumed
//
//  Onboarding Flow - 7 Steps with Smooth Animations
//

import SwiftUI
import Combine

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.resumed.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Animated Progress
                AnimatedProgressBar(
                    current: viewModel.currentStep,
                    total: viewModel.totalSteps
                )
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

                // Content with gesture support
                GeometryReader { geometry in
                    let stepWidth = geometry.size.width
                    HStack(spacing: 0) {
                        ForEach(1...viewModel.totalSteps, id: \.self) { step in
                            stepContent(for: step)
                                .frame(width: stepWidth)
                                .clipped()
                        }
                    }
                    .offset(x: -CGFloat(viewModel.currentStep - 1) * stepWidth + dragOffset)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentStep)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Allow swipe back only
                                if value.translation.width > 0 && viewModel.currentStep > 1 {
                                    dragOffset = value.translation.width * 0.3
                                }
                            }
                            .onEnded { value in
                                if value.translation.width > 100 && viewModel.currentStep > 1 {
                                    viewModel.previousStep()
                                }
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                }
                            }
                    )
                }
                .clipped()
            }
        }
        .onAppear {
        }
    }

    @ViewBuilder
    private func stepContent(for step: Int) -> some View {
        Group {
            switch step {
            case 1: WelcomeStep(viewModel: viewModel)
            case 2: NameStep(viewModel: viewModel)
            case 3: ProfileStep(viewModel: viewModel)
            case 4: ExamStep(viewModel: viewModel)
            case 5: DateStep(viewModel: viewModel)
            case 6: HoursStep(viewModel: viewModel)
            case 7: PriorityStep(viewModel: viewModel)
            case 8: SpecialtyStep(viewModel: viewModel)
            case 9: ProcessingStep(viewModel: viewModel) {
                appState.completeOnboarding()
            }
            default: EmptyView()
            }
        }
        .adaptiveWidth(540)
    }
}

// MARK: - Animated Progress Bar

struct AnimatedProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(1...total, id: \.self) { step in
                Capsule()
                    .fill(step <= current ? Color.resumed.gold : Color.resumed.blackTertiary)
                    .frame(height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
            }
        }
    }
}

// MARK: - View Model

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 1
    @Published var data = OnboardingData()

    let totalSteps = 9

    let exams = ["ENAMED", "USP", "UNICAMP", "UNIFESP", "ENARE", "SUS-SP", "Outro"]
    let specialties = ["Clínica Médica", "Cirurgia Geral", "Pediatria", "Ginecologia e Obstetrícia", "Medicina de Família", "Outras"]
    let subjects = ["Clínica Médica", "Pediatria", "Cirurgia Geral", "Ginecologia e Obstetrícia", "Medicina Preventiva", "Outras"]

    init() {
        if data.subjectPriority.isEmpty {
            data.subjectPriority = subjects
        }
    }

    func nextStep() {
        guard currentStep < totalSteps else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep += 1
        }
        HapticManager.shared.selection()
    }

    func previousStep() {
        guard currentStep > 1 else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep -= 1
        }
        HapticManager.shared.selection()
    }

    func persistOnboarding() {
        if !data.subjectPriority.isEmpty {
            UserDefaults.standard.set(data.subjectPriority, forKey: "subjectPriority")
        }
        if !data.targetExam.isEmpty {
            UserDefaults.standard.set(data.targetExam, forKey: "targetExam")
        }
        UserDefaults.standard.set(data.studyHoursPerDay, forKey: "studyHoursPerDay")
        if let examDate = data.examDate {
            UserDefaults.standard.set(examDate, forKey: "examDate")
        }

        // Sync to Supabase profiles table
        Task {
            try? await SupabaseManager.shared.syncOnboardingData(data)
        }
    }
}

// MARK: - Step 1: Welcome

struct WelcomeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Animated Logo
            ZStack {
                Circle()
                    .fill(Color.resumed.gold.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)

                Circle()
                    .fill(Color.resumed.gold.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showContent ? 1 : 0.3)
                    .opacity(showContent ? 1 : 0)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.resumed.gold)
                    .scaleEffect(showContent ? 1 : 0)
                    .rotationEffect(.degrees(showContent ? 0 : -30))
            }
            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: showContent)

            VStack(spacing: Spacing.md) {
                Text("Bem-vindo ao")
                    .font(.resumed.h3)
                    .foregroundColor(.resumed.gray)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text("RESUMED")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.resumed.gold)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text("Sua plataforma inteligente de preparação para a residência médica")
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gray)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            .padding(.horizontal, Spacing.lg)
            .animation(.easeOut(duration: 0.6).delay(0.4), value: showContent)

            Spacer()

            VStack(spacing: Spacing.md) {
                ResumedButton(
                title: "Começar",
                style: .primary,
                action: { viewModel.nextStep() },
                icon: "arrow.right",
                fullWidth: true
            )
                .padding(.horizontal, Spacing.md)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 30)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8), value: showButton)

                Text("Desenvolvido por DME TECHNOLOGY")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.resumed.gray.opacity(0.5))
                    .opacity(showButton ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(1.0), value: showButton)
            }
            .padding(.bottom, Spacing.xl)
        }
        .onAppear {
            showContent = true
            showButton = true
        }
    }
}

// MARK: - Step 2: Name

struct NameStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        OnboardingStepLayout(
            onBack: { viewModel.previousStep() },
            onNext: { viewModel.nextStep() },
            nextDisabled: viewModel.data.name.trimmingCharacters(in: .whitespaces).isEmpty
        ) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.resumed.gold)
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

            Text("Como devemos te chamar?")
                .font(.resumed.h2)
                .foregroundColor(.resumed.white)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)

            ResumedTextField(
                placeholder: "Seu nome",
                text: $viewModel.data.name,
                icon: "person"
            )
            .focused($isNameFocused)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
        }
        .onAppear {
            showContent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
}

// MARK: - Step 3: Profile (City, Phone, University)

struct ProfileStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false
    @FocusState private var focusedField: ProfileField?

    enum ProfileField {
        case phone, city, university
    }

    var body: some View {
        OnboardingStepLayout(
            onBack: { viewModel.previousStep() },
            onNext: { viewModel.nextStep() }
        ) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 60))
                .foregroundColor(.resumed.gold)
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

            Text("Seus dados acadêmicos")
                .font(.resumed.h2)
                .foregroundColor(.resumed.white)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)

            VStack(spacing: Spacing.md) {
                ResumedTextField(
                    placeholder: "Telefone (com DDD)",
                    text: $viewModel.data.phone,
                    icon: "phone",
                    keyboardType: .phonePad
                )
                .focused($focusedField, equals: .phone)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)

                ResumedTextField(
                    placeholder: "Cidade",
                    text: $viewModel.data.city,
                    icon: "mappin.and.ellipse"
                )
                .focused($focusedField, equals: .city)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)

                ResumedTextField(
                    placeholder: "Faculdade",
                    text: $viewModel.data.university,
                    icon: "graduationcap"
                )
                .focused($focusedField, equals: .university)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
            }
        }
        .onAppear {
            showContent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .phone
            }
        }
    }
}

// MARK: - Step 4: Exam Selection

struct ExamStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false

    var body: some View {
        OnboardingStepLayout(
            onBack: { viewModel.previousStep() },
            onNext: { viewModel.nextStep() },
            nextDisabled: viewModel.data.targetExam.isEmpty
        ) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.resumed.gold)
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

            Text("Qual sua prova alvo?")
                .font(.resumed.h2)
                .foregroundColor(.resumed.white)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(Array(viewModel.exams.enumerated()), id: \.element) { index, exam in
                    AnimatedChipButton(
                        title: exam,
                        isSelected: viewModel.data.targetExam == exam,
                        delay: Double(index) * 0.05
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.data.targetExam = exam
                        }
                        HapticManager.shared.selection()
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(0.2 + Double(index) * 0.05), value: showContent)
                }
            }
        }
        .onAppear { showContent = true }
    }
}

// MARK: - Step 4: Date

struct DateStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false
    @State private var selectedDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

    var body: some View {
        OnboardingStepLayout(
            onBack: { viewModel.previousStep() },
            onNext: { viewModel.nextStep() }
        ) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.resumed.gold)
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

            VStack(spacing: Spacing.sm) {
                Text("Quando é sua prova?")
                    .font(.resumed.h2)
                    .foregroundColor(.resumed.white)

                Text(daysUntilExam)
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gold)
            }
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)

            DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .scaleEffect(showContent ? 1 : 0.9)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
                .onChange(of: selectedDate) { _, newValue in
                    viewModel.data.examDate = newValue
                }
        }
        .onAppear {
            showContent = true
            viewModel.data.examDate = selectedDate
        }
    }

    var daysUntilExam: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: selectedDate).day ?? 0
        return "Faltam \(days) dias"
    }
}

// MARK: - Step 5: Study Hours

struct HoursStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false

    var body: some View {
        OnboardingStepLayout(
            onBack: { viewModel.previousStep() },
            onNext: { viewModel.nextStep() }
        ) {
            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundColor(.resumed.gold)
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

            Text("Quantas horas por dia você pode estudar?")
                .font(.resumed.h2)
                .foregroundColor(.resumed.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)

            ZStack {
                Circle()
                    .stroke(Color.resumed.gold.opacity(0.2), lineWidth: 8)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.data.studyHoursPerDay) / 12)
                    .stroke(Color.resumed.gold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.data.studyHoursPerDay)

                Text("\(viewModel.data.studyHoursPerDay)h")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.resumed.gold)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: viewModel.data.studyHoursPerDay)
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: showContent)

            Slider(value: Binding(
                get: { Double(viewModel.data.studyHoursPerDay) },
                set: {
                    viewModel.data.studyHoursPerDay = Int($0)
                    HapticManager.shared.impact(.light)
                }
            ), in: 1...12, step: 1)
            .tint(.resumed.gold)
            .padding(.horizontal, Spacing.xl)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)

            Text(hoursDescription)
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
        }
        .onAppear { showContent = true }
    }

    var hoursDescription: String {
        switch viewModel.data.studyHoursPerDay {
        case 1...2: return "Ideal para quem tem pouco tempo"
        case 3...4: return "Ótimo ritmo de estudo"
        case 5...6: return "Dedicação intensa"
        case 7...8: return "Estudo em tempo integral"
        default: return "Maratonista! 💪"
        }
    }
}

// MARK: - Step 6: Priority

struct PriorityStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false

    var body: some View {
        OnboardingStepLayout(
            onBack: { viewModel.previousStep() },
            onNext: { viewModel.nextStep() }
        ) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.resumed.gold)
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

            Text("Qual a ordem de prioridade das matérias?")
                .font(.resumed.h2)
                .foregroundColor(.resumed.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)

            Text("Você pode reorganizar a qualquer momento")
                .font(.resumed.caption)
                .foregroundColor(.resumed.gray)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)

            List {
                ForEach(viewModel.data.subjectPriority, id: \.self) { subject in
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.resumed.gray)
                        Text(subject)
                            .font(.resumed.body)
                            .foregroundColor(.resumed.white)
                        Spacer()
                    }
                    .padding(.vertical, Spacing.xs)
                    .listRowBackground(Color.resumed.blackSecondary)
                }
                .onMove { indices, newOffset in
                    viewModel.data.subjectPriority.move(fromOffsets: indices, toOffset: newOffset)
                    HapticManager.shared.selection()
                }
            }
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .background(Color.resumed.black)
            .frame(maxHeight: 360)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)
        }
        .onAppear { showContent = true }
    }
}

// MARK: - Step 7: Specialty

struct SpecialtyStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false

    var body: some View {
        OnboardingStepLayout(
            onBack: { viewModel.previousStep() },
            onNext: { viewModel.nextStep() }
        ) {
            Image(systemName: "stethoscope")
                .font(.system(size: 60))
                .foregroundColor(.resumed.gold)
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)

            Text("Qual especialidade te interessa?")
                .font(.resumed.h2)
                .foregroundColor(.resumed.white)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)

            VStack(spacing: Spacing.sm) {
                ForEach(Array(viewModel.specialties.enumerated()), id: \.element) { index, specialty in
                    SpecialtyOptionButton(
                        title: specialty,
                        isSelected: viewModel.data.specialty == specialty
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.data.specialty = specialty
                        }
                        HapticManager.shared.selection()
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -50)
                    .animation(.easeOut(duration: 0.4).delay(0.15 + Double(index) * 0.05), value: showContent)
                }
            }
        }
        .onAppear { showContent = true }
    }
}

struct SpecialtyOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.resumed.body)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.resumed.gold : Color.resumed.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.resumed.gold)
                            .frame(width: 14, height: 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .foregroundColor(.resumed.white)
            .padding(Spacing.md)
            .background(isSelected ? Color.resumed.gold.opacity(0.1) : Color.resumed.blackSecondary)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.resumed.gold : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Step 9: Processing

struct ProcessingStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var currentPhase = 0
    @State private var showComplete = false

    let phases = [
        "Analisando seu perfil...",
        "Calculando carga de estudos...",
        "Gerando plano personalizado...",
        "Preparando ResuCard..."
    ]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            if !showComplete {
                // Processing Animation
                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.resumed.gold.opacity(0.3), lineWidth: 4)
                            .frame(width: 100 + CGFloat(index * 40), height: 100 + CGFloat(index * 40))
                            .rotationEffect(.degrees(Double(index * 60)))
                            .animation(
                                .linear(duration: 2 + Double(index) * 0.5)
                                .repeatForever(autoreverses: false),
                                value: currentPhase
                            )
                    }

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.resumed.gold)
                        .scaleEffect(currentPhase > 0 ? 1 : 0.8)
                        .animation(.spring(response: 0.5).repeatForever(autoreverses: true), value: currentPhase)
                }

                VStack(spacing: Spacing.md) {
                    Text(phases[min(currentPhase, phases.count - 1)])
                        .font(.resumed.h3)
                        .foregroundColor(.resumed.white)
                        .animation(.easeInOut, value: currentPhase)
                        .id(currentPhase)

                    // Phase indicators
                    HStack(spacing: Spacing.sm) {
                        ForEach(0..<phases.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentPhase ? Color.resumed.gold : Color.resumed.blackTertiary)
                                .frame(width: 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPhase)
                        }
                    }
                }
            } else {
                // Complete Animation
                ZStack {
                    Circle()
                        .fill(Color.resumed.success.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .scaleEffect(showComplete ? 1 : 0)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.resumed.success)
                        .scaleEffect(showComplete ? 1 : 0)
                        .rotationEffect(.degrees(showComplete ? 0 : -90))
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showComplete)

                VStack(spacing: Spacing.sm) {
                    Text("Tudo pronto, \(viewModel.data.name.components(separatedBy: " ").first ?? "")!")
                        .font(.resumed.h2)
                        .foregroundColor(.resumed.white)

                    Text("Seu plano de estudos está criado")
                        .font(.resumed.body)
                        .foregroundColor(.resumed.gray)
                }
                .opacity(showComplete ? 1 : 0)
                .offset(y: showComplete ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showComplete)

                ResumedButton(
                    title: "Começar a estudar",
                    style: .primary,
                    action: {
                        viewModel.persistOnboarding()
                        onComplete()
                    },
                    icon: "arrow.right",
                    fullWidth: true
                )
                .padding(.horizontal, Spacing.md)
                .opacity(showComplete ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: showComplete)
            }

            Spacer()
        }
        .onAppear {
            runProcessingAnimation()
        }
    }

    private func runProcessingAnimation() {
        for i in 0..<phases.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) {
                withAnimation {
                    currentPhase = i
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(phases.count) * 0.6 + 0.5) {
            withAnimation {
                showComplete = true
            }
            HapticManager.shared.celebration()
        }
    }
}

// MARK: - Helper Components

/// Scrollable step layout that pins NavigationButtons at the bottom.
/// Fixes iPad compatibility mode where keyboard hides the forward button.
struct OnboardingStepLayout<Content: View>: View {
    let onBack: () -> Void
    let onNext: () -> Void
    var nextDisabled: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    content()
                }
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.md)
                .padding(.horizontal, Spacing.md)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)

            NavigationButtons(
                onBack: onBack,
                onNext: onNext,
                nextDisabled: nextDisabled
            )
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
            .padding(.top, Spacing.sm)
        }
    }
}

struct NavigationButtons: View {
    let onBack: () -> Void
    let onNext: () -> Void
    var nextDisabled: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            ResumedButton(
                title: "Voltar",
                style: .ghost,
                action: onBack
            )

            ResumedButton(
                title: "Continuar",
                style: .primary,
                action: onNext,
                icon: "arrow.right",
                isDisabled: nextDisabled
            )
        }
    }
}

struct AnimatedChipButton: View {
    let title: String
    let isSelected: Bool
    let delay: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.resumed.body)
                .foregroundColor(isSelected ? .resumed.black : .resumed.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.resumed.gold : Color.resumed.blackSecondary)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(isSelected ? Color.resumed.gold : Color.resumed.border, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
