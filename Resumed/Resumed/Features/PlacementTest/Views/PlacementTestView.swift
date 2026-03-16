//
//  PlacementTestView.swift
//  Resumed
//
//  Full-screen placement test: Intro → Test → Results
//

import SwiftUI

struct PlacementTestView: View {
    @StateObject private var viewModel = PlacementTestViewModel()
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.resumed.black.ignoresSafeArea()

            switch viewModel.phase {
            case .intro:
                PlacementIntroScreen(viewModel: viewModel, onSkip: { viewModel.skip(); onFinish() })
            case .testing:
                PlacementTestingScreen(viewModel: viewModel)
            case .results:
                PlacementResultsScreen(viewModel: viewModel, onComplete: onFinish)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.phase)
    }
}

// MARK: - Intro

private struct PlacementIntroScreen: View {
    @ObservedObject var viewModel: PlacementTestViewModel
    let onSkip: () -> Void
    @State private var showContent = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle().fill(Color.resumed.gold.opacity(0.1)).frame(width: 160, height: 160)
                Circle().fill(Color.resumed.gold.opacity(0.2)).frame(width: 120, height: 120)
                Image(systemName: "brain.head.profile").font(.system(size: 60)).foregroundColor(.resumed.gold)
            }
            .scaleEffect(showContent ? 1 : 0.5)
            .opacity(showContent ? 1 : 0)

            VStack(spacing: Spacing.md) {
                Text("Teste de Nivelamento")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.resumed.white)
                Text("Responda ~10 questões adaptativas e descubra seus pontos fortes e fracos por especialidade.")
                    .font(.resumed.body)
                    .foregroundColor(.resumed.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            HStack(spacing: Spacing.sm) {
                ForEach(PlacementSpecialty.allCases, id: \.self) { s in
                    HStack(spacing: 4) {
                        Circle().fill(s.color).frame(width: 8, height: 8)
                        Text(s.rawValue.components(separatedBy: " ").first ?? "")
                            .font(.resumed.caption).foregroundColor(.resumed.grayLight)
                    }
                    .padding(.horizontal, Spacing.xs).padding(.vertical, 4)
                    .background(Color.resumed.blackSecondary).cornerRadius(CornerRadius.sm)
                }
            }
            .opacity(showContent ? 1 : 0)

            Spacer()

            VStack(spacing: Spacing.md) {
                ResumedButton(title: "Começar Teste", style: .primary, action: { viewModel.startTest() }, icon: "arrow.right", fullWidth: true)
                Button(action: onSkip) {
                    Text("Pular por Agora").font(.resumed.body).foregroundColor(.resumed.gray)
                        .frame(maxWidth: .infinity).padding(.vertical, Spacing.sm)
                }
            }
            .padding(.horizontal, Spacing.md).padding(.bottom, Spacing.xl)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { showContent = true } }
    }
}

// MARK: - Testing

private struct PlacementTestingScreen: View {
    @ObservedObject var viewModel: PlacementTestViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Spacing.sm) {
                HStack {
                    if let q = viewModel.currentQuestion {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: q.specialty.icon).font(.system(size: 12)).foregroundColor(q.specialty.color)
                            Text(q.specialty.rawValue).font(.resumed.caption).foregroundColor(q.specialty.color)
                        }
                        .padding(.horizontal, Spacing.sm).padding(.vertical, 4)
                        .background(q.specialty.color.opacity(0.15)).cornerRadius(CornerRadius.sm)
                    }
                    Spacer()
                    Text("\(viewModel.answeredCount)/\(viewModel.totalExpected)")
                        .font(.resumed.caption).foregroundColor(.resumed.gray)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.resumed.blackTertiary).frame(height: 4)
                        Capsule().fill(Color.resumed.gold)
                            .frame(width: geo.size.width * viewModel.progress, height: 4)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.progress)
                    }
                }.frame(height: 4)
            }
            .padding(.horizontal, Spacing.md).padding(.top, Spacing.md).padding(.bottom, Spacing.sm)

            // Question
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if let question = viewModel.currentQuestion {
                        QuestionCard(
                            question: question.asQuestion,
                            selectedOptionId: viewModel.selectedOptionId,
                            isAnswered: viewModel.isAnswered,
                            onSelect: { viewModel.selectOption($0) }
                        )
                        .id(question.id)

                        if viewModel.isAnswered {
                            FeedbackCard(
                                isCorrect: viewModel.isCorrect,
                                explanation: question.explanation,
                                socialMessage: viewModel.isCorrect ? "Boa! Continue assim." : "Vamos focar nessa área."
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .padding(.bottom, 120)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAnswered)
            }

            // CTA
            VStack {
                Divider().background(Color.resumed.border)
                if !viewModel.isAnswered {
                    ResumedButton(title: "Confirmar", style: .primary,
                        action: { withAnimation { viewModel.confirmAnswer() } },
                        fullWidth: true, isDisabled: viewModel.selectedOptionId == nil)
                } else {
                    ResumedButton(title: "Próxima", style: .primary,
                        action: { withAnimation { viewModel.nextQuestion() } },
                        icon: "arrow.right", fullWidth: true)
                }
            }
            .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.md)
            .background(Color.resumed.black)
        }
    }
}

// MARK: - Results

private struct PlacementResultsScreen: View {
    @ObservedObject var viewModel: PlacementTestViewModel
    let onComplete: () -> Void
    @State private var showCards = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                VStack(spacing: Spacing.md) {
                    ZStack {
                        Circle().fill(Color.resumed.gold.opacity(0.15)).frame(width: 120, height: 120)
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 56)).foregroundColor(.resumed.gold)
                    }
                    .scaleEffect(showCards ? 1 : 0.3).opacity(showCards ? 1 : 0)

                    Text("Nivelamento Concluído!")
                        .font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.resumed.white)
                    Text("Seu plano de estudos foi ajustado automaticamente.")
                        .font(.resumed.bodySmall).foregroundColor(.resumed.gray).multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xl)

                // Results
                if let result = viewModel.result {
                    VStack(spacing: Spacing.sm) {
                        Text("Resultado por Especialidade")
                            .font(.resumed.h4).foregroundColor(.resumed.white)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, Spacing.md)

                        ForEach(Array(PlacementSpecialty.allCases.enumerated()), id: \.element) { index, specialty in
                            SpecialtyResultRow(specialty: specialty, level: result.level(for: specialty))
                                .opacity(showCards ? 1 : 0)
                                .offset(x: showCards ? 0 : 50)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1 + Double(index) * 0.07), value: showCards)
                        }
                    }
                }

                ResumedButton(title: "Começar a Estudar", style: .primary, action: onComplete, icon: "arrow.right", fullWidth: true)
                    .padding(.horizontal, Spacing.md).padding(.bottom, Spacing.xl)
            }
        }
        .background(Color.resumed.black)
        .onAppear { withAnimation { showCards = true } }
    }
}

// MARK: - Specialty Result Row

struct SpecialtyResultRow: View {
    let specialty: PlacementSpecialty
    let level: SpecialtyLevel

    var body: some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 3).fill(specialty.color).frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: specialty.icon).font(.system(size: 12)).foregroundColor(specialty.color)
                    Text(specialty.rawValue).font(.resumed.bodySmall).foregroundColor(.resumed.white)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.resumed.blackTertiary).frame(height: 4)
                        Capsule().fill(level.color).frame(width: geo.size.width * strengthFraction, height: 4)
                    }
                }.frame(height: 4)
            }

            Spacer()

            Text(level.displayName).font(.resumed.caption).foregroundColor(level.color)
                .padding(.horizontal, Spacing.sm).padding(.vertical, 4)
                .background(level.color.opacity(0.15)).cornerRadius(CornerRadius.sm)

            Image(systemName: level.icon).font(.system(size: 14)).foregroundColor(level.color)
        }
        .padding(Spacing.md).background(Color.resumed.blackSecondary).cornerRadius(CornerRadius.md)
        .padding(.horizontal, Spacing.md)
    }

    private var strengthFraction: CGFloat {
        switch level { case .forte: return 1.0; case .medio: return 0.55; case .fraco: return 0.25 }
    }
}

#Preview {
    PlacementTestView { }
}
