//
//  User.swift
//  Resumed
//
//  Data Models - User & Authentication
//

import Foundation

// MARK: - User Model

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let targetExam: String?
    let examDate: Date?
    let studyHoursPerDay: Int
    let createdAt: Date
    var onboardingCompleted: Bool
}

// MARK: - User Stats

struct UserStats: Codable {
    let level: Int
    let xp: Int
    let xpToNextLevel: Int
    let streak: Int
    let totalQuestionsAnswered: Int
    let totalCorrectAnswers: Int
    let studyTimeMinutes: Int
    let subjectStats: [SubjectStat]
    let badges: [String]

    var accuracyPercentage: String {
        guard totalQuestionsAnswered > 0 else { return "0%" }
        let accuracy = Double(totalCorrectAnswers) / Double(totalQuestionsAnswered) * 100
        return "\(Int(accuracy))%"
    }

    var studyTimeFormatted: String {
        let hours = studyTimeMinutes / 60
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(studyTimeMinutes)min"
    }
}

struct SubjectStat: Codable {
    let subject: String
    let questionsAnswered: Int
    let correctAnswers: Int

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }
}

// MARK: - Auth Models

struct GoogleAuthRequest: Codable {
    let idToken: String
    let deviceId: String
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
}

// MARK: - Onboarding Data

struct OnboardingData: Codable {
    var name: String = ""
    var phone: String = ""
    var city: String = ""
    var university: String = ""
    var targetExam: String = ""
    var examDate: Date?
    var studyHoursPerDay: Int = 4
    var subjectPriority: [String] = []
    var specialty: String?
    var previousAttempts: Int = 0
    var studyPreferences: [String] = []
    var birthDate: Date?
    var state: String?
}

// MARK: - Badge

enum Badge: String, CaseIterable, Codable {
    // Question Badges
    case firstQuestion = "first_question"
    case hundredQuestions = "hundred_questions"
    case fiveHundredQuestions = "five_hundred_questions"
    case thousandQuestions = "thousand_questions"
    case fiveThousandQuestions = "five_thousand_questions"

    // Streak Badges
    case weekStreak = "week_streak"
    case monthStreak = "month_streak"
    case hundredDayStreak = "hundred_day_streak"
    case yearStreak = "year_streak"

    // FlashCard Badges
    case flashcardFan = "flashcard_fan"
    case memoryMaster = "memory_master"
    case flashcardGuru = "flashcard_guru"

    // Performance Badges
    case perfectScore = "perfect_score"
    case perfectWeek = "perfect_week"
    case examAce = "exam_ace"
    case speedDemon = "speed_demon"

    // Time Badges
    case nightOwl = "night_owl"
    case earlyBird = "early_bird"
    case marathonStudier = "marathon_studier"
    case weekendWarrior = "weekend_warrior"

    // Level Badges
    case levelTen = "level_ten"
    case levelTwentyFive = "level_twenty_five"
    case levelFifty = "level_fifty"
    case levelHundred = "level_hundred"

    // Special Badges
    case betaTester = "beta_tester"
    case firstExamComplete = "first_exam_complete"
    case allSubjectsMastered = "all_subjects_mastered"
    case comeback = "comeback"

    var title: String {
        switch self {
        case .firstQuestion: return "Primeira Questão"
        case .hundredQuestions: return "Centenário"
        case .fiveHundredQuestions: return "Dedicado"
        case .thousandQuestions: return "Mestre"
        case .fiveThousandQuestions: return "Lenda"
        case .weekStreak: return "Semana Perfeita"
        case .monthStreak: return "Mês Perfeito"
        case .hundredDayStreak: return "100 Dias"
        case .yearStreak: return "1 Ano Seguido"
        case .flashcardFan: return "Fã de Cards"
        case .memoryMaster: return "Memória de Elefante"
        case .flashcardGuru: return "Guru dos Cards"
        case .perfectScore: return "Perfeição"
        case .perfectWeek: return "Semana 100%"
        case .examAce: return "Ás dos Simulados"
        case .speedDemon: return "Velocista"
        case .nightOwl: return "Coruja"
        case .earlyBird: return "Madrugador"
        case .marathonStudier: return "Maratonista"
        case .weekendWarrior: return "Guerreiro de FDS"
        case .levelTen: return "Level 10"
        case .levelTwentyFive: return "Level 25"
        case .levelFifty: return "Level 50"
        case .levelHundred: return "Level 100"
        case .betaTester: return "Beta Tester"
        case .firstExamComplete: return "Primeiro Simulado"
        case .allSubjectsMastered: return "Mestre Completo"
        case .comeback: return "Retorno Triunfal"
        }
    }

    var description: String {
        switch self {
        case .firstQuestion: return "Respondeu sua primeira questão"
        case .hundredQuestions: return "Respondeu 100 questões"
        case .fiveHundredQuestions: return "Respondeu 500 questões"
        case .thousandQuestions: return "Respondeu 1000 questões"
        case .fiveThousandQuestions: return "Respondeu 5000 questões"
        case .weekStreak: return "Estudou por 7 dias seguidos"
        case .monthStreak: return "Estudou por 30 dias seguidos"
        case .hundredDayStreak: return "Estudou por 100 dias seguidos"
        case .yearStreak: return "Estudou por 365 dias seguidos"
        case .flashcardFan: return "Revisou 50 flashcards"
        case .memoryMaster: return "Revisou 500 flashcards"
        case .flashcardGuru: return "Revisou 2000 flashcards"
        case .perfectScore: return "100% em um simulado"
        case .perfectWeek: return "100% de acertos na semana"
        case .examAce: return "Completou 10 simulados com 80%+"
        case .speedDemon: return "Respondeu 50 questões em 30min"
        case .nightOwl: return "Estudou após meia-noite"
        case .earlyBird: return "Estudou antes das 6h"
        case .marathonStudier: return "Estudou por 5h seguidas"
        case .weekendWarrior: return "Estudou 4h em um fim de semana"
        case .levelTen: return "Alcançou o nível 10"
        case .levelTwentyFive: return "Alcançou o nível 25"
        case .levelFifty: return "Alcançou o nível 50"
        case .levelHundred: return "Alcançou o nível 100"
        case .betaTester: return "Usuário da versão beta"
        case .firstExamComplete: return "Completou seu primeiro simulado"
        case .allSubjectsMastered: return "80%+ em todas as matérias"
        case .comeback: return "Voltou após 7 dias ausente"
        }
    }

    var icon: String {
        switch self {
        case .firstQuestion: return "star.fill"
        case .hundredQuestions: return "checkmark.seal.fill"
        case .fiveHundredQuestions: return "medal.fill"
        case .thousandQuestions: return "crown.fill"
        case .fiveThousandQuestions: return "trophy.fill"
        case .weekStreak: return "flame.fill"
        case .monthStreak: return "flame.circle.fill"
        case .hundredDayStreak: return "bolt.fill"
        case .yearStreak: return "sparkles"
        case .flashcardFan: return "rectangle.stack.fill"
        case .memoryMaster: return "brain.head.profile"
        case .flashcardGuru: return "graduationcap.fill"
        case .perfectScore: return "target"
        case .perfectWeek: return "checkmark.seal.fill"
        case .examAce: return "rosette"
        case .speedDemon: return "hare.fill"
        case .nightOwl: return "moon.stars.fill"
        case .earlyBird: return "sunrise.fill"
        case .marathonStudier: return "figure.run"
        case .weekendWarrior: return "shield.fill"
        case .levelTen: return "10.circle.fill"
        case .levelTwentyFive: return "25.circle.fill"
        case .levelFifty: return "50.circle.fill"
        case .levelHundred: return "crown.fill"
        case .betaTester: return "testtube.2"
        case .firstExamComplete: return "doc.text.fill"
        case .allSubjectsMastered: return "books.vertical.fill"
        case .comeback: return "arrow.uturn.up.circle.fill"
        }
    }

    var xpReward: Int {
        switch self {
        case .firstQuestion: return 10
        case .hundredQuestions: return 50
        case .fiveHundredQuestions: return 100
        case .thousandQuestions: return 200
        case .fiveThousandQuestions: return 500
        case .weekStreak: return 50
        case .monthStreak: return 150
        case .hundredDayStreak: return 300
        case .yearStreak: return 1000
        case .flashcardFan: return 30
        case .memoryMaster: return 100
        case .flashcardGuru: return 250
        case .perfectScore: return 100
        case .perfectWeek: return 75
        case .examAce: return 200
        case .speedDemon: return 50
        case .nightOwl: return 20
        case .earlyBird: return 20
        case .marathonStudier: return 75
        case .weekendWarrior: return 40
        case .levelTen: return 100
        case .levelTwentyFive: return 250
        case .levelFifty: return 500
        case .levelHundred: return 1000
        case .betaTester: return 100
        case .firstExamComplete: return 50
        case .allSubjectsMastered: return 500
        case .comeback: return 30
        }
    }
}

// MARK: - Badge Display Info

extension Badge: Identifiable {
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .firstQuestion: return "Primeira Questão"
        case .hundredQuestions: return "100 Questões"
        case .fiveHundredQuestions: return "500 Questões"
        case .thousandQuestions: return "1.000 Questões"
        case .fiveThousandQuestions: return "5.000 Questões"
        case .weekStreak: return "Streak de 7 dias"
        case .monthStreak: return "Streak de 30 dias"
        case .hundredDayStreak: return "Streak de 100 dias"
        case .yearStreak: return "Streak de 365 dias"
        case .flashcardFan: return "Fã de ResuCards"
        case .memoryMaster: return "Mestre da Memória"
        case .flashcardGuru: return "Guru dos Cards"
        case .perfectScore: return "Nota Perfeita"
        case .perfectWeek: return "Semana Perfeita"
        case .examAce: return "Ás do Simulado"
        case .speedDemon: return "Velocista"
        case .nightOwl: return "Coruja Noturna"
        case .earlyBird: return "Madrugador"
        case .marathonStudier: return "Maratonista"
        case .weekendWarrior: return "Guerreiro do Fim de Semana"
        case .levelTen: return "Nível 10"
        case .levelTwentyFive: return "Nível 25"
        case .levelFifty: return "Nível 50"
        case .levelHundred: return "Nível 100"
        case .betaTester: return "Beta Tester"
        case .firstExamComplete: return "Primeiro Simulado"
        case .allSubjectsMastered: return "Mestre Geral"
        case .comeback: return "Volta por Cima"
        }
    }

    var unlockHint: String {
        switch self {
        case .firstQuestion: return "Responda sua primeira questão"
        case .hundredQuestions: return "Responda 100 questões"
        case .fiveHundredQuestions: return "Responda 500 questões"
        case .thousandQuestions: return "Responda 1.000 questões"
        case .fiveThousandQuestions: return "Responda 5.000 questões"
        case .weekStreak: return "Estude por 7 dias seguidos"
        case .monthStreak: return "Estude por 30 dias seguidos"
        case .hundredDayStreak: return "Estude por 100 dias seguidos"
        case .yearStreak: return "Estude por 365 dias seguidos"
        case .flashcardFan: return "Revise 50 ResuCards"
        case .memoryMaster: return "Revise 200 ResuCards"
        case .flashcardGuru: return "Revise 500 ResuCards"
        case .perfectScore: return "Acerte 100% em uma sessão de 10+ questões"
        case .perfectWeek: return "Complete todas as tarefas de uma semana"
        case .examAce: return "Acerte 90%+ em um simulado completo"
        case .speedDemon: return "Responda 20 questões em menos de 10 minutos"
        case .nightOwl: return "Estude após as 22h"
        case .earlyBird: return "Estude antes das 7h"
        case .marathonStudier: return "Estude por 4+ horas em um dia"
        case .weekendWarrior: return "Estude no sábado e domingo"
        case .levelTen: return "Alcance o nível 10"
        case .levelTwentyFive: return "Alcance o nível 25"
        case .levelFifty: return "Alcance o nível 50"
        case .levelHundred: return "Alcance o nível 100"
        case .betaTester: return "Usar o app durante a fase beta"
        case .firstExamComplete: return "Complete seu primeiro simulado"
        case .allSubjectsMastered: return "Acerte 80%+ em todas as matérias"
        case .comeback: return "Volte a estudar após 7+ dias de inatividade"
        }
    }
}

// MARK: - Complete Task Response

struct CompleteTaskResponse: Codable {
    let success: Bool
    let xpEarned: Int
    let newStreak: Int?
}
