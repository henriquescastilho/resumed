//
//  MockData.swift
//  ResumedTests
//
//  Mock Data for Testing
//

import Foundation
@testable import Resumed

// MARK: - Mock Data Provider

struct MockTestData {

    // MARK: - FlashCards

    static let flashCards: [FlashCard] = [
        FlashCard(
            id: "test-card-1",
            front: "Quais sao os criterios diagnosticos de Hipertensao Arterial?",
            back: "PA sistolica >= 140 mmHg e/ou PA diastolica >= 90 mmHg em medicoes repetidas.",
            subject: "Cardiologia",
            tags: ["HAS", "Diagnostico"]
        ),
        FlashCard(
            id: "test-card-2",
            front: "Qual o tratamento de primeira linha para IAM com supra de ST?",
            back: "Angioplastia primaria em ate 90 minutos ou trombolitico em ate 30 minutos.",
            subject: "Cardiologia",
            tags: ["IAM", "Tratamento", "Emergencia"]
        ),
        FlashCard(
            id: "test-card-3",
            front: "Quais sao os criterios de Light para derrame pleural?",
            back: "Exsudato se: Proteina pleural/serica > 0.5, LDH pleural/serica > 0.6, LDH pleural > 2/3 limite superior.",
            subject: "Pneumologia",
            tags: ["Derrame Pleural", "Diagnostico"]
        ),
        FlashCard(
            id: "test-card-4",
            front: "Qual a tríade de Cushing?",
            back: "Hipertensão, bradicardia e alteração do padrão respiratório. Indica hipertensão intracraniana.",
            subject: "Neurologia",
            tags: ["HIC", "Emergencia"]
        ),
        FlashCard(
            id: "test-card-5",
            front: "Quais são os critérios de Framingham para IC?",
            back: "Maiores: DPN, estase jugular, estertores, cardiomegalia, EAP, B3, PVC > 16. Menores: edema MMII, tosse noturna, dispneia aos esforços.",
            subject: "Cardiologia",
            tags: ["IC", "Diagnostico"]
        )
    ]

    // MARK: - Questions

    static let questions: [Question] = [
        Question(
            id: "test-q-1",
            statement: "Paciente de 58 anos, hipertenso, apresenta dor precordial há 2 horas irradiando para MSE. ECG mostra supra de ST em DII, DIII e aVF. Qual o diagnóstico?",
            options: [
                QuestionOption(id: "a", text: "IAM de parede inferior"),
                QuestionOption(id: "b", text: "Angina instável"),
                QuestionOption(id: "c", text: "Pericardite aguda"),
                QuestionOption(id: "d", text: "Dissecção aórtica")
            ],
            correctOptionId: "a",
            explanation: "O supra de ST em DII, DIII e aVF indica IAM de parede inferior.",
            subject: "Cardiologia",
            topic: "IAM",
            difficulty: .hard,
            source: "USP 2023"
        ),
        Question(
            id: "test-q-2",
            statement: "Criança de 2 anos com febre há 3 dias, exantema maculopapular iniciado na face. Qual o diagnóstico mais provável?",
            options: [
                QuestionOption(id: "a", text: "Sarampo"),
                QuestionOption(id: "b", text: "Rubéola"),
                QuestionOption(id: "c", text: "Escarlatina"),
                QuestionOption(id: "d", text: "Eritema infeccioso")
            ],
            correctOptionId: "a",
            explanation: "Sarampo: febre alta, exantema crânio-caudal, manchas de Koplik.",
            subject: "Pediatria",
            topic: "Exantemas",
            difficulty: .medium,
            source: "UNICAMP 2022"
        ),
        Question(
            id: "test-q-3",
            statement: "Gestante de 32 semanas com PA 160/110 mmHg e proteinúria 3+. Qual a conduta?",
            options: [
                QuestionOption(id: "a", text: "Sulfato de magnésio e parto"),
                QuestionOption(id: "b", text: "Nifedipina e observação"),
                QuestionOption(id: "c", text: "Hidralazina e expectante"),
                QuestionOption(id: "d", text: "Metildopa e alta")
            ],
            correctOptionId: "a",
            explanation: "Pré-eclâmpsia grave: sulfato de magnésio para profilaxia de eclâmpsia e resolução da gestação.",
            subject: "Ginecologia e Obstetrícia",
            topic: "Pré-eclâmpsia",
            difficulty: .hard,
            source: "UNIFESP 2023"
        )
    ]

    // MARK: - User Stats

    static let userStats = UserStats(
        level: 12,
        xp: 2450,
        xpToNextLevel: 3000,
        streak: 7,
        totalQuestionsAnswered: 847,
        totalCorrectAnswers: 678,
        studyTimeMinutes: 1260,
        subjectStats: [
            SubjectStat(subject: "Cardiologia", questionsAnswered: 200, correctAnswers: 164),
            SubjectStat(subject: "Pediatria", questionsAnswered: 150, correctAnswers: 120),
            SubjectStat(subject: "Cirurgia", questionsAnswered: 180, correctAnswers: 135)
        ],
        badges: ["first_question", "week_streak", "hundred_questions"]
    )

    // MARK: - User

    static let testUser = User(
        id: "test-user-123",
        email: "test@resumed.app",
        name: "Estudante Teste",
        avatar: nil,
        targetExam: "ENAMED",
        examDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
        studyHoursPerDay: 4,
        createdAt: Date(),
        onboardingCompleted: true
    )
}

// MARK: - Mock API Responses

struct MockAPIResponses {

    static let loginSuccess = AuthResponse(
        user: MockTestData.testUser,
        accessToken: "mock-access-token-12345",
        refreshToken: "mock-refresh-token-67890",
        expiresIn: 3600
    )

    static let flashCardsDue = FlashCardsDueResponse(
        flashcards: MockTestData.flashCards.map { FlashCardDTO(from: $0) },
        total: MockTestData.flashCards.count
    )
}

// MARK: - FlashCardDTO Extension for Testing

extension FlashCardDTO {
    init(from card: FlashCard) {
        self.init(
            id: card.id,
            front: card.front,
            back: card.back,
            subject: card.subject,
            tags: card.tags,
            easinessFactor: card.easinessFactor,
            interval: card.interval,
            repetitions: card.repetitions,
            nextReviewAt: card.nextReviewDate,
            lastReviewedAt: card.lastReviewDate
        )
    }
}
