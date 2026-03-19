//
//  MockAPIClient.swift
//  Resumed
//
//  Mock API Client for Development & Testing
//

import Foundation

// MARK: - Mock API Client

@MainActor
class MockAPIClient {
    static let shared = MockAPIClient()
    private init() {}

    // Simulate network delay
    private func simulateDelay() async {
        try? await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...800_000_000))
    }

    // MARK: - Auth

    func login(with idToken: String, deviceId: String) async throws -> AuthResponse {
        await simulateDelay()
        return AuthResponse(
            user: MockData.user,
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresIn: 3600
        )
    }

    // MARK: - User

    func getUserProfile() async throws -> User {
        await simulateDelay()
        return MockData.user
    }

    func getUserStats() async throws -> UserStats {
        await simulateDelay()

        // Build real stats from local data instead of hardcoded mock
        let snapshot = ProgressTracker.shared.snapshot()
        let gamification = GamificationManager.shared

        // If no local data exists yet, return mock as starter
        guard snapshot.totalQuestions > 0 else {
            return MockData.userStats
        }

        let subjectStats = snapshot.subjectStats.map { (subject, progress) in
            SubjectStat(
                subject: subject,
                questionsAnswered: progress.questionsAnswered,
                correctAnswers: progress.correctAnswers
            )
        }.sorted { $0.questionsAnswered > $1.questionsAnswered }

        return UserStats(
            level: gamification.level,
            xp: gamification.currentXP,
            xpToNextLevel: gamification.xpToNextLevel(),
            streak: gamification.streak,
            totalQuestionsAnswered: snapshot.totalQuestions,
            totalCorrectAnswers: snapshot.totalCorrect,
            studyTimeMinutes: snapshot.studyMinutes,
            subjectStats: subjectStats,
            badges: gamification.unlockedBadges.map { $0.rawValue }
        )
    }

    // MARK: - Study Plan

    func getStudyPlan() async throws -> StudyPlan {
        await simulateDelay()
        return MockData.studyPlan
    }

    func completeTask(taskId: String) async throws -> CompleteTaskResponse {
        await simulateDelay()
        return CompleteTaskResponse(success: true, xpEarned: XPReward.completeTask, newStreak: 8)
    }

    // MARK: - Questions

    func getQuestions(subjects: [String], count: Int, difficulty: QuestionDifficulty?) async throws -> [Question] {
        await simulateDelay()
        return MockData.generateQuestions(subjects: subjects, count: count, difficulty: difficulty)
    }

    func submitAnswer(questionId: String, answer: String) async throws -> AnswerResponse {
        await simulateDelay()
        let isCorrect = Bool.random()
        return AnswerResponse(
            correct: isCorrect,
            correctAnswer: "a",
            explanation: MockData.explanations.randomElement() ?? "",
            xpEarned: isCorrect ? XPReward.correctAnswer : 0
        )
    }

    // MARK: - FlashCards

    func getFlashCardsDue() async throws -> FlashCardsDueResponse {
        await simulateDelay()
        return FlashCardsDueResponse(flashcards: MockData.flashCardDTOs, total: 15)
    }

    func reviewFlashCard(cardId: String, quality: Int) async throws -> FlashCardReviewResponse {
        await simulateDelay()
        return FlashCardReviewResponse(
            success: true,
            nextReviewAt: Date().addingTimeInterval(Double(quality) * 86400),
            xpEarned: SM2Algorithm.Quality(rawValue: quality)?.xpReward ?? 5
        )
    }

    func createFlashCard(front: String, back: String, subject: String, tags: [String]) async throws -> FlashCardDTO {
        await simulateDelay()
        return FlashCardDTO(
            id: UUID().uuidString,
            front: front,
            back: back,
            subject: subject,
            tags: tags,
            easinessFactor: 2.5,
            interval: 1,
            repetitions: 0,
            nextReviewAt: Date(),
            lastReviewedAt: nil
        )
    }

    // MARK: - Exams

    func getPastExams() async throws -> [Exam] {
        await simulateDelay()
        return MockData.exams
    }

    func getExamQuestions(examId: String) async throws -> [Question] {
        await simulateDelay()
        return MockData.generateQuestions(subjects: ["Clínica Médica", "Cirurgia", "Pediatria"], count: 100, difficulty: nil)
    }

    // MARK: - Gamification

    func updateUserXP(totalXP: Int, level: Int) async throws -> MessageResponse {
        await simulateDelay()
        return MessageResponse(message: "XP updated successfully")
    }

    func unlockBadge(_ badgeId: String) async throws -> MessageResponse {
        await simulateDelay()
        return MessageResponse(message: "Badge unlocked: \(badgeId)")
    }

    func getLeaderboard(type: LeaderboardType, limit: Int) async throws -> [LeaderboardEntry] {
        await simulateDelay()
        return MockData.generateLeaderboard(limit: limit)
    }

    // MARK: - Grey AI

    func sendGreyMessage(_ message: String, context: [GreyMessage]) async throws -> GreyResponse {
        await simulateDelay()
        return GreyResponse(
            message: MockData.greyResponses.randomElement() ?? "Ótima pergunta! Vamos analisar...",
            suggestions: ["Explique mais sobre isso", "Mostre um exemplo", "Quais são as exceções?"]
        )
    }
}

// MARK: - Additional Response Models

struct AnswerResponse: Codable {
    let correct: Bool
    let correctAnswer: String
    let explanation: String
    let xpEarned: Int
}

struct GreyMessage: Codable, Identifiable {
    let id: String
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date
}

struct GreyResponse: Codable {
    let message: String
    let suggestions: [String]
}

enum LeaderboardType: String, Codable {
    case weekly, monthly, allTime, subject
}

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let avatar: String?
    let score: Int
    let rank: Int
    let isCurrentUser: Bool
}

// MARK: - Mock Data

struct MockData {

    // MARK: - User

    static let user = User(
        id: "user_123",
        email: "estudante@resumed.app",
        name: "João Silva",
        avatar: nil,
        targetExam: "ENAMED",
        examDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
        studyHoursPerDay: 4,
        createdAt: Date().addingTimeInterval(-30 * 86400),
        onboardingCompleted: true
    )

    static let userStats = UserStats(
        level: 12,
        xp: 1240,
        xpToNextLevel: 2000,
        streak: 7,
        totalQuestionsAnswered: 1247,
        totalCorrectAnswers: 972,
        studyTimeMinutes: 2520,
        subjectStats: [
            SubjectStat(subject: "Clínica Médica", questionsAnswered: 450, correctAnswers: 369),
            SubjectStat(subject: "Cirurgia Geral", questionsAnswered: 280, correctAnswers: 190),
            SubjectStat(subject: "Pediatria", questionsAnswered: 200, correctAnswers: 150),
            SubjectStat(subject: "Ginecologia e Obstetrícia", questionsAnswered: 180, correctAnswers: 133),
            SubjectStat(subject: "Medicina Preventiva", questionsAnswered: 137, correctAnswers: 130)
        ],
        badges: ["first_question", "hundred_questions", "week_streak"]
    )

    // MARK: - Study Plan

    static let studyPlan = StudyPlan(
        id: "plan_123",
        userId: "user_123",
        startDate: Date().addingTimeInterval(-14 * 86400),
        targetExamDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!,
        targetExam: "ENAMED",
        tasks: [
            StudyTask(id: "task_1", title: "Revisar IAM", subject: "Cardiologia", type: .review, dueDate: Date(), completed: false, estimatedMinutes: 45, theme: "Síndromes Coronarianas", topics: ["IAM com supra", "IAM sem supra"]),
            StudyTask(id: "task_2", title: "Revisão de Pneumonia", subject: "Pneumologia", type: .review, dueDate: Date(), completed: true, estimatedMinutes: 30, theme: "Infecções Respiratórias", topics: ["PAC", "Pneumonia nosocomial"]),
            StudyTask(id: "task_3", title: "ResuCard - Antibióticos", subject: "Farmacologia", type: .flashcards, dueDate: Date(), completed: false, estimatedMinutes: 20, theme: "Antibioticoterapia", topics: nil),
            StudyTask(id: "task_4", title: "Leitura - Diabetes", subject: "Endocrinologia", type: .reading, dueDate: Date().addingTimeInterval(86400), completed: false, estimatedMinutes: 60, theme: "Diabetes Mellitus", topics: ["DM1", "DM2", "Complicações"]),
            StudyTask(id: "task_5", title: "Vídeo - Pré-natal", subject: "Obstetrícia", type: .video, dueDate: Date().addingTimeInterval(86400), completed: false, estimatedMinutes: 40, theme: "Assistência Pré-natal", topics: nil)
        ],
        subjectPlans: [
            SubjectPlan(id: "sp_1", subject: "Clínica Médica", totalHours: 120, completedHours: 45, themes: ["Cardiologia", "Pneumologia", "Endocrinologia", "Nefrologia", "Gastroenterologia"]),
            SubjectPlan(id: "sp_2", subject: "Cirurgia", totalHours: 80, completedHours: 30, themes: ["Trauma", "Abdome Agudo", "Hérnias", "Oncologia Cirúrgica"]),
            SubjectPlan(id: "sp_3", subject: "Pediatria", totalHours: 70, completedHours: 25, themes: ["Neonatologia", "Puericultura", "Infectologia Pediátrica"]),
            SubjectPlan(id: "sp_4", subject: "GO", totalHours: 70, completedHours: 20, themes: ["Pré-natal", "Parto", "Ginecologia", "Oncologia Ginecológica"]),
            SubjectPlan(id: "sp_5", subject: "Preventiva", totalHours: 50, completedHours: 15, themes: ["Epidemiologia", "Vigilância", "SUS", "Políticas de Saúde"])
        ],
        createdAt: Date().addingTimeInterval(-14 * 86400),
        updatedAt: Date()
    )

    // MARK: - Questions

    static let questionStatements = [
        "Paciente de 58 anos, hipertenso e diabético, apresenta dor precordial há 2 horas, irradiando para MSE. ECG mostra supra de ST em DII, DIII e aVF. Qual o diagnóstico mais provável?",
        "Criança de 3 anos apresenta febre alta, tosse seca e coriza há 3 dias. Ao exame: manchas de Koplik na mucosa oral. Qual a conduta inicial?",
        "Gestante de 32 semanas com quadro de pré-eclâmpsia grave. Qual a conduta obstétrica?",
        "Paciente com dor abdominal em fossa ilíaca direita, febre e leucocitose. Blumberg positivo. Qual o diagnóstico?",
        "Idoso de 75 anos com dispneia progressiva, edema de MMII e estase jugular. RX mostra cardiomegalia. Qual a principal hipótese?",
        "RN de 2 dias de vida com icterícia zona III de Kramer. Qual a conduta?",
        "Paciente de 45 anos com nódulo tireoidiano de 2cm. TSH normal. Qual o próximo passo?",
        "Mulher de 28 anos com amenorreia há 3 meses, galactorreia e cefaleia. Qual exame solicitar primeiro?",
        "Paciente HIV+ com CD4 < 200 apresenta dispneia e infiltrado intersticial bilateral. Qual a principal hipótese?",
        "Criança de 5 anos com edema facial matinal, proteinúria maciça e hipoalbuminemia. Diagnóstico?"
    ]

    static let questionOptions = [
        [
            QuestionOption(id: "a", text: "IAM de parede inferior"),
            QuestionOption(id: "b", text: "Angina instável"),
            QuestionOption(id: "c", text: "Pericardite aguda"),
            QuestionOption(id: "d", text: "Dissecção aórtica")
        ],
        [
            QuestionOption(id: "a", text: "Iniciar antibioticoterapia"),
            QuestionOption(id: "b", text: "Notificação compulsória e isolamento"),
            QuestionOption(id: "c", text: "Solicitar sorologia"),
            QuestionOption(id: "d", text: "Administrar vitamina A")
        ],
        [
            QuestionOption(id: "a", text: "Conduta expectante até termo"),
            QuestionOption(id: "b", text: "Sulfato de magnésio e resolução da gestação"),
            QuestionOption(id: "c", text: "Apenas anti-hipertensivos"),
            QuestionOption(id: "d", text: "Repouso absoluto e hidralazina")
        ],
        [
            QuestionOption(id: "a", text: "Apendicite aguda"),
            QuestionOption(id: "b", text: "Diverticulite"),
            QuestionOption(id: "c", text: "Cólica renal"),
            QuestionOption(id: "d", text: "Doença inflamatória pélvica")
        ],
        [
            QuestionOption(id: "a", text: "Insuficiência cardíaca congestiva"),
            QuestionOption(id: "b", text: "DPOC descompensado"),
            QuestionOption(id: "c", text: "Pneumonia"),
            QuestionOption(id: "d", text: "TEP")
        ]
    ]

    static let explanations = [
        "O supra de ST em DII, DIII e aVF indica comprometimento da parede inferior do coração, caracterizando IAM de parede inferior. A artéria coronária direita é responsável pela irrigação desta região na maioria dos casos.",
        "As manchas de Koplik são patognomônicas do sarampo. A conduta inclui notificação compulsória, isolamento respiratório e suplementação de vitamina A para reduzir complicações.",
        "A pré-eclâmpsia grave requer estabilização materna com sulfato de magnésio para prevenção de eclâmpsia e resolução da gestação, considerando a idade gestacional e condições materno-fetais.",
        "O quadro clássico de dor em FID, febre, leucocitose e sinal de Blumberg positivo (irritação peritoneal) é altamente sugestivo de apendicite aguda, requerendo avaliação cirúrgica.",
        "A tríade de dispneia progressiva, edema de membros inferiores e estase jugular, associada a cardiomegalia no RX, é característica de insuficiência cardíaca congestiva."
    ]

    static func generateQuestions(subjects: [String], count: Int, difficulty: QuestionDifficulty?) -> [Question] {
        return (0..<count).map { index in
            let statementIndex = index % questionStatements.count
            let optionsIndex = index % questionOptions.count
            let subject = subjects[index % subjects.count]

            return Question(
                id: "q_\(UUID().uuidString.prefix(8))",
                statement: questionStatements[statementIndex],
                options: questionOptions[optionsIndex],
                correctOptionId: ["a", "b", "a", "a", "a"][optionsIndex],
                explanation: explanations[optionsIndex % explanations.count],
                subject: subject,
                source: ["ENAMED 2023", "USP 2022", "UNICAMP 2023", "UNIFESP 2022", "SUS-SP 2023"].randomElement()!
            )
        }
    }

    // MARK: - FlashCards

    static let flashCardDTOs: [FlashCardDTO] = [
        FlashCardDTO(
            id: "fc_1",
            front: "Quais são os critérios de Framingham para IC?",
            back: "**Maiores:** Dispneia paroxística noturna, Estase jugular, Estertores, Cardiomegalia, EAP, B3, Refluxo hepatojugular\n\n**Menores:** Edema MMII, Tosse noturna, Hepatomegalia, Derrame pleural, Taquicardia > 120",
            subject: "Cardiologia",
            tags: ["cardiologia", "IC", "diagnóstico"],
            easinessFactor: 2.5,
            interval: 1,
            repetitions: 0,
            nextReviewAt: Date(),
            lastReviewedAt: nil
        ),
        FlashCardDTO(
            id: "fc_2",
            front: "Tríade de Beck?",
            back: "1. **Hipotensão arterial**\n2. **Hipofonese de bulhas** (abafamento)\n3. **Turgência jugular**\n\n→ Característico de **Tamponamento Cardíaco**",
            subject: "Cardiologia",
            tags: ["cardiologia", "emergência", "tamponamento"],
            easinessFactor: 2.5,
            interval: 1,
            repetitions: 0,
            nextReviewAt: Date(),
            lastReviewedAt: nil
        ),
        FlashCardDTO(
            id: "fc_3",
            front: "CURB-65 - O que significa cada letra?",
            back: "**C** - Confusão mental\n**U** - Ureia > 50 mg/dL (ou BUN > 19)\n**R** - Respiratory rate ≥ 30 irpm\n**B** - Blood pressure < 90/60 mmHg\n**65** - Idade ≥ 65 anos\n\n**Conduta:**\n• 0-1: Ambulatorial\n• 2: Internação\n• 3-5: UTI",
            subject: "Pneumologia",
            tags: ["pneumologia", "PAC", "escore"],
            easinessFactor: 2.5,
            interval: 1,
            repetitions: 0,
            nextReviewAt: Date(),
            lastReviewedAt: nil
        ),
        FlashCardDTO(
            id: "fc_4",
            front: "Sinais de irritação meníngea",
            back: "1. **Rigidez de nuca** - resistência à flexão passiva\n2. **Sinal de Kernig** - dor ao estender joelho com quadril fletido\n3. **Sinal de Brudzinski** - flexão involuntária das pernas ao fletir pescoço",
            subject: "Neurologia",
            tags: ["neurologia", "meningite", "semiologia"],
            easinessFactor: 2.5,
            interval: 1,
            repetitions: 0,
            nextReviewAt: Date(),
            lastReviewedAt: nil
        ),
        FlashCardDTO(
            id: "fc_5",
            front: "Critérios de Light para derrame pleural",
            back: "**Exsudato** se qualquer um:\n\n1. Proteína pleural/sérica **> 0,5**\n2. LDH pleural/sérica **> 0,6**\n3. LDH pleural **> 2/3** do limite superior sérico\n\n*Se nenhum critério → Transudato*",
            subject: "Pneumologia",
            tags: ["pneumologia", "derrame pleural", "diagnóstico"],
            easinessFactor: 2.5,
            interval: 1,
            repetitions: 0,
            nextReviewAt: Date(),
            lastReviewedAt: nil
        )
    ]

    // MARK: - Exams

    static let exams = ExamCalendar.exams

    // MARK: - Grey AI Responses

    static let greyResponses = [
        "Excelente pergunta! Vamos analisar os critérios diagnósticos passo a passo...",
        "Esse é um tema frequente em provas! O mais importante é lembrar que...",
        "Para memorizar isso, sugiro usar a seguinte mnemônica...",
        "Na prática clínica, o mais comum é encontrar essa apresentação quando...",
        "Esse conceito é fundamental! Deixa eu te explicar de forma simplificada...",
        "Boa dúvida! A diferença principal entre esses dois conceitos é...",
        "Vamos revisar os pontos-chave desse tema para a prova...",
        "Isso já caiu na USP 2022! A pegadinha costuma ser..."
    ]

    // MARK: - Leaderboard

    static func generateLeaderboard(limit: Int) -> [LeaderboardEntry] {
        let names = ["Ana Santos", "Pedro Lima", "Carla Oliveira", "Lucas Silva", "Marina Costa", "João Pereira", "Fernanda Souza", "Rafael Mendes", "Juliana Alves", "Bruno Ferreira"]

        return (0..<min(limit, names.count)).map { index in
            LeaderboardEntry(
                id: "leader_\(index)",
                userId: "user_\(index)",
                userName: names[index],
                avatar: nil,
                score: Int.random(in: 5000...15000) - (index * 500),
                rank: index + 1,
                isCurrentUser: index == 4
            )
        }
    }

    // MARK: - Daily Quotes

    static let motivationalQuotes = [
        "A persistência é o caminho do êxito. - Charles Chaplin",
        "O sucesso é a soma de pequenos esforços repetidos dia após dia.",
        "Estudar não é um sacrifício, é uma oportunidade.",
        "Cada questão errada é uma chance de aprender.",
        "A aprovação é construída um dia de cada vez.",
        "Você não precisa ser perfeito, precisa ser persistente.",
        "O melhor momento para estudar foi ontem. O segundo melhor é agora.",
        "Residência não é destino, é construção diária."
    ]
}

// MARK: - API Client Mode Switching

enum APIMode {
    case mock
    case production
}

extension APIClient {
    static var mode: APIMode = .mock

    static func switchToMock() {
        mode = .mock
    }

    static func switchToProduction() {
        mode = .production
    }
}
