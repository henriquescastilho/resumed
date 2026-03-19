//
//  QuestionBankLoader.swift
//  Resumed
//
//  Parses questions_bank.json (bundled in app Resources) into typed models.
//  Provides per-exam edition filtering and subject-level breakdowns.
//

import Foundation

// MARK: - Raw JSON Models (matches questions_bank.json schema)

private struct BankRoot: Decodable {
    let metadata: BankMetadata
    let questions: [BankQuestionRaw]
}

private struct BankMetadata: Decodable {
    let total_questions: Int
}

private struct BankQuestionRaw: Decodable {
    let id: String
    let exam: String
    let year: Int
    let edition: Int
    let number: Int
    let enunciado: String
    let alternatives: [String: String]
    let correct_answer: String
    let subject: String
    let is_annulled: Bool
    let explanation: String?
}

// MARK: - Public Domain Models

/// A single question from the bundled bank, ready for a session.
struct BankQuestion: Identifiable {
    let id: String
    let exam: String
    let year: Int
    let edition: Int
    let number: Int
    let subject: String
    let statement: String
    let options: [QuestionOption]
    let correctOptionId: String
    let isAnnulled: Bool
    let explanation: String

    /// Bridge to the app's Question model used by QuestionSessionManager.
    func toQuestion() -> Question {
        Question(
            id: id,
            statement: statement,
            options: options,
            correctOptionId: correctOptionId,
            explanation: explanation,
            subject: subject,
            topic: nil,
            difficulty: .medium,
            source: "\(exam) \(year)/\(edition)"
        )
    }
}

/// One distinct exam edition (e.g. Revalida 2024 Ed.1).
struct BankExamEdition: Identifiable {
    let id: String                       // "revalida_2024_1"
    let exam: String                     // "Revalida" | "ENAMED"
    let year: Int
    let edition: Int
    let questionCount: Int
    let subjectBreakdown: [SubjectCount] // sorted descending by count

    var displayTitle: String {
        edition > 1 ? "\(exam) \(year)/\(edition)" : "\(exam) \(year)"
    }

    struct SubjectCount: Identifiable {
        let id: String   // subject name
        let subject: String
        let count: Int
    }
}

// MARK: - Loader

final class QuestionBankLoader {
    static let shared = QuestionBankLoader()

    private var bankQuestions: [BankQuestion] = []
    private(set) var isLoaded = false

    private let loadLock = NSLock()

    private init() {}

    // MARK: - Load

    /// Call once (idempotent) to parse the bundled JSON into memory.
    func load() {
        loadLock.lock()
        defer { loadLock.unlock() }
        guard !isLoaded else { return }
        guard let url = Bundle.main.url(forResource: "questions_bank", withExtension: "json") else {
            print("QuestionBankLoader: questions_bank.json not found in bundle.")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let root = try JSONDecoder().decode(BankRoot.self, from: data)
            bankQuestions = root.questions
                .filter { !$0.is_annulled }
                .map { raw in
                    // Sort alternatives by key (A, B, C, D) to guarantee order
                    let sorted = raw.alternatives.sorted { $0.key < $1.key }
                    let options = sorted.map { QuestionOption(id: $0.key, text: $0.value) }
                    return BankQuestion(
                        id: raw.id,
                        exam: raw.exam,
                        year: raw.year,
                        edition: raw.edition,
                        number: raw.number,
                        subject: raw.subject,
                        statement: raw.enunciado,
                        options: options,
                        correctOptionId: raw.correct_answer,
                        isAnnulled: raw.is_annulled,
                        explanation: raw.explanation ?? ""
                    )
                }
            isLoaded = true
        } catch {
            print("QuestionBankLoader: Failed to parse JSON — \(error)")
        }
    }

    // MARK: - Compatibility API (used by QuestionBank + MockAPIClient)

    /// All non-annulled questions as the app's Question model.
    func allQuestions() -> [Question] {
        load()
        return bankQuestions.map { $0.toQuestion() }
    }

    /// Random selection of up to `count` questions for a given subject.
    func questions(for subject: String, count: Int) -> [Question] {
        load()
        let filtered = bankQuestions.filter { $0.subject == subject }.map { $0.toQuestion() }
        return Array(filtered.shuffled().prefix(count))
    }

    /// All questions from a specific exam and year.
    func questions(for exam: String, year: Int) -> [Question] {
        load()
        return bankQuestions
            .filter { $0.exam.lowercased() == exam.lowercased() && $0.year == year }
            .map { $0.toQuestion() }
    }

    // MARK: - Queries

    /// All distinct exam editions sorted newest first.
    func availableEditions() -> [BankExamEdition] {
        load()
        // Group by (exam, year, edition)
        var groups: [String: [BankQuestion]] = [:]
        for q in bankQuestions {
            let key = "\(q.exam)_\(q.year)_\(q.edition)"
            groups[key, default: []].append(q)
        }
        return groups.map { key, questions in
            let first = questions[0]
            // Subject breakdown
            var subjectMap: [String: Int] = [:]
            for q in questions { subjectMap[q.subject, default: 0] += 1 }
            let breakdown = subjectMap
                .map { BankExamEdition.SubjectCount(id: $0.key, subject: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
            return BankExamEdition(
                id: key,
                exam: first.exam,
                year: first.year,
                edition: first.edition,
                questionCount: questions.count,
                subjectBreakdown: breakdown
            )
        }
        .sorted { lhs, rhs in
            if lhs.year != rhs.year { return lhs.year > rhs.year }
            if lhs.exam != rhs.exam { return lhs.exam < rhs.exam }
            return lhs.edition > rhs.edition
        }
    }

    /// All non-annulled questions for a specific edition.
    func questions(for edition: BankExamEdition) -> [BankQuestion] {
        load()
        return bankQuestions
            .filter { $0.exam == edition.exam && $0.year == edition.year && $0.edition == edition.edition }
            .sorted { $0.number < $1.number }
    }

    /// Total number of distinct (non-annulled) questions across all exams.
    var totalCount: Int {
        load()
        return bankQuestions.count
    }
}
