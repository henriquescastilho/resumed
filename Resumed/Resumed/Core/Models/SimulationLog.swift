//
//  SimulationLog.swift
//  Resumed
//
//  Simulation log — records every practice session with per-question detail
//

import Foundation

struct SimulationLog: Codable, Identifiable {
    let id: String
    let date: Date
    let title: String
    let mode: SimulationMode
    let totalQuestions: Int
    let correctCount: Int
    let wrongCount: Int
    let unansweredCount: Int
    let durationSeconds: Int
    let questions: [QuestionLog]

    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctCount) / Double(totalQuestions) * 100
    }

    var subjectBreakdown: [SubjectResult] {
        var map: [String: (correct: Int, total: Int)] = [:]
        for q in questions {
            var entry = map[q.subject] ?? (correct: 0, total: 0)
            entry.total += 1
            if q.isCorrect { entry.correct += 1 }
            map[q.subject] = entry
        }
        return map.map { SubjectResult(subject: $0.key, correct: $0.value.correct, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }

    var wrongQuestions: [QuestionLog] {
        questions.filter { !$0.isCorrect && $0.selectedAnswer != nil }
    }

    var correctQuestions: [QuestionLog] {
        questions.filter { $0.isCorrect }
    }
}

enum SimulationMode: String, Codable {
    case study = "Modo Estudo"
    case timed = "Simulado Cronometrado"
    case endless = "Treinar até Morrer"
    case quickPractice = "Prática Rápida"
    case subjectDrill = "Simulado por Matéria"
    case errorReview = "Revisão de Erros"
    case marathon = "Maratona Aleatória"

    var icon: String {
        switch self {
        case .study: return "book.fill"
        case .timed: return "timer"
        case .endless: return "skull.fill"
        case .quickPractice: return "bolt.fill"
        case .subjectDrill: return "list.clipboard.fill"
        case .errorReview: return "xmark.circle.fill"
        case .marathon: return "shuffle"
        }
    }
}

struct QuestionLog: Codable, Identifiable {
    let id: String
    let questionId: String
    let subject: String
    let enunciado: String  // first 200 chars
    let selectedAnswer: String?
    let correctAnswer: String
    let isCorrect: Bool
    let timeSpentSeconds: Int
}

struct SubjectResult: Identifiable {
    let id = UUID()
    let subject: String
    let correct: Int
    let total: Int

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }
}
