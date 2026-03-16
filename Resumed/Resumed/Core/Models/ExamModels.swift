//
//  ExamModels.swift
//  Resumed
//
//  Data Models — Exams, Ementas, Calendar
//

import Foundation

// MARK: - Exam

struct Exam: Identifiable, Codable {
    let id: String
    let institution: String
    let name: String
    let year: Int
    let examDate: Date?
    let registrationDeadline: Date?
    let subjects: [ExamSubject]
    let questionCount: Int
    let durationMinutes: Int
    let difficulty: ExamDifficultyLevel
    let ementa: ExamEmenta?
    let sourceURL: String?

    var subjectNames: [String] {
        subjects.map { $0.name }
    }

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)min" : "\(minutes)min"
    }

    var isUpcoming: Bool {
        guard let date = examDate else { return false }
        return date > Date()
    }

    var daysUntilExam: Int? {
        guard let date = examDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }
}

struct ExamSubject: Codable {
    let name: String
    let questionCount: Int
    let topics: [String]
}

struct ExamEmenta: Codable {
    let version: String
    let areas: [EmentaArea]
}

struct EmentaArea: Codable {
    let subject: String
    let themes: [EmentaTheme]
}

struct EmentaTheme: Codable {
    let name: String
    let topics: [String]
    let frequencyScore: Int? // 1-5 based on historical recurrence
}

enum ExamDifficultyLevel: String, Codable {
    case easy = "Fácil"
    case medium = "Médio"
    case hard = "Difícil"
}

// MARK: - Exam Calendar (bundled data)

struct ExamCalendar {
    /// All known exam dates and metadata for Brazilian medical residency exams
    static let exams: [Exam] = [
        // ENAMED 2026
        Exam(
            id: "enamed_2026",
            institution: "ENAMED",
            name: "ENAMED 2026",
            year: 2026,
            examDate: Self.date("2026-11-08"),
            registrationDeadline: Self.date("2026-08-15"),
            subjects: [
                ExamSubject(name: "Clínica Médica", questionCount: 20, topics: ["Cardiologia", "Pneumologia", "Endocrinologia", "Nefrologia", "Infectologia", "Reumatologia", "Gastroenterologia", "Hematologia", "Neurologia"]),
                ExamSubject(name: "Cirurgia Geral", questionCount: 20, topics: ["Trauma", "Abdome Agudo", "Hérnias", "Vias Biliares", "Oncologia Cirúrgica", "Pré/Pós-Operatório", "Cirurgia Vascular"]),
                ExamSubject(name: "Pediatria", questionCount: 20, topics: ["Neonatologia", "Puericultura", "DNPM", "Imunizações", "Doenças Exantemáticas", "IVAS/Pneumonia", "Diarreia/Desidratação"]),
                ExamSubject(name: "Ginecologia e Obstetrícia", questionCount: 20, topics: ["Pré-Natal", "Parto", "Síndromes Hipertensivas", "Sangramento 1º/2º Tri", "Vulvovaginites", "Rastreamento Ca Colo/Mama", "Contracepção"]),
                ExamSubject(name: "Medicina Preventiva", questionCount: 20, topics: ["Epidemiologia", "Bioestatística", "SUS/Legislação", "Vigilância Epidemiológica", "APS/ESF", "Saúde do Trabalhador", "Política Nacional de Saúde"])
            ],
            questionCount: 100,
            durationMinutes: 300,
            difficulty: .medium,
            ementa: Self.enamed2026Ementa,
            sourceURL: "https://www.gov.br/saude/pt-br/composicao/sgtes/enamed"
        ),

        // USP-SP
        Exam(
            id: "usp_2026",
            institution: "USP",
            name: "USP-SP 2026",
            year: 2026,
            examDate: Self.date("2026-11-24"),
            registrationDeadline: Self.date("2026-09-01"),
            subjects: [
                ExamSubject(name: "Clínica Médica", questionCount: 25, topics: ["Cardiologia", "Pneumologia", "Infectologia", "Nefrologia", "Endocrinologia"]),
                ExamSubject(name: "Cirurgia Geral", questionCount: 25, topics: ["Trauma", "Abdome Agudo", "Oncologia", "Vascular"]),
                ExamSubject(name: "Pediatria", questionCount: 20, topics: ["Neonatologia", "Infecciosas", "Puericultura"]),
                ExamSubject(name: "Ginecologia e Obstetrícia", questionCount: 20, topics: ["Obstetrícia", "Ginecologia"]),
                ExamSubject(name: "Medicina Preventiva", questionCount: 10, topics: ["Epidemiologia", "SUS"])
            ],
            questionCount: 100,
            durationMinutes: 300,
            difficulty: .hard,
            ementa: nil,
            sourceURL: nil
        ),

        // UNICAMP
        Exam(
            id: "unicamp_2026",
            institution: "UNICAMP",
            name: "UNICAMP 2026",
            year: 2026,
            examDate: Self.date("2026-12-01"),
            registrationDeadline: Self.date("2026-09-15"),
            subjects: [
                ExamSubject(name: "Clínica Médica", questionCount: 30, topics: ["Cardiologia", "Pneumologia", "Gastro", "Nefro", "Infecto"]),
                ExamSubject(name: "Cirurgia Geral", questionCount: 25, topics: ["Trauma", "Abdome Agudo", "Hérnias"]),
                ExamSubject(name: "Pediatria", questionCount: 25, topics: ["Neonatologia", "Puericultura", "Infectologia"]),
                ExamSubject(name: "Ginecologia e Obstetrícia", questionCount: 20, topics: ["Obstetrícia", "Ginecologia"]),
                ExamSubject(name: "Medicina Preventiva", questionCount: 20, topics: ["Epidemiologia", "Bioestatística", "SUS"])
            ],
            questionCount: 120,
            durationMinutes: 300,
            difficulty: .hard,
            ementa: nil,
            sourceURL: nil
        ),

        // ENARE
        Exam(
            id: "enare_2026",
            institution: "ENARE",
            name: "ENARE 2026",
            year: 2026,
            examDate: Self.date("2026-10-20"),
            registrationDeadline: Self.date("2026-07-31"),
            subjects: [
                ExamSubject(name: "Clínica Médica", questionCount: 20, topics: ["Cardiologia", "Pneumologia", "Infecto"]),
                ExamSubject(name: "Cirurgia Geral", questionCount: 20, topics: ["Trauma", "Abdome Agudo"]),
                ExamSubject(name: "Pediatria", questionCount: 20, topics: ["Neo", "Puericultura"]),
                ExamSubject(name: "Ginecologia e Obstetrícia", questionCount: 20, topics: ["Obstetrícia", "Ginecologia"]),
                ExamSubject(name: "Medicina Preventiva", questionCount: 20, topics: ["SUS", "Epidemiologia"])
            ],
            questionCount: 100,
            durationMinutes: 300,
            difficulty: .medium,
            ementa: nil,
            sourceURL: nil
        ),

        // SUS-SP
        Exam(
            id: "sus_sp_2026",
            institution: "SUS-SP",
            name: "SUS-SP 2026",
            year: 2026,
            examDate: Self.date("2026-11-17"),
            registrationDeadline: Self.date("2026-08-20"),
            subjects: [
                ExamSubject(name: "Clínica Médica", questionCount: 20, topics: ["Cardiologia", "Infectologia"]),
                ExamSubject(name: "Cirurgia Geral", questionCount: 20, topics: ["Trauma", "Abdome Agudo"]),
                ExamSubject(name: "Pediatria", questionCount: 15, topics: ["Neo", "Puericultura"]),
                ExamSubject(name: "Ginecologia e Obstetrícia", questionCount: 15, topics: ["Obstetrícia"]),
                ExamSubject(name: "Medicina Preventiva", questionCount: 10, topics: ["SUS", "APS"])
            ],
            questionCount: 80,
            durationMinutes: 240,
            difficulty: .medium,
            ementa: nil,
            sourceURL: nil
        ),

        // UNIFESP
        Exam(
            id: "unifesp_2026",
            institution: "UNIFESP",
            name: "UNIFESP 2026",
            year: 2026,
            examDate: Self.date("2026-12-08"),
            registrationDeadline: Self.date("2026-09-30"),
            subjects: [
                ExamSubject(name: "Clínica Médica", questionCount: 25, topics: ["Cardiologia", "Pneumo", "Infecto"]),
                ExamSubject(name: "Cirurgia Geral", questionCount: 25, topics: ["Trauma", "Oncologia"]),
                ExamSubject(name: "Pediatria", questionCount: 20, topics: ["Neo", "Exantemáticas"]),
                ExamSubject(name: "Ginecologia e Obstetrícia", questionCount: 20, topics: ["Alto Risco", "Gineco"]),
                ExamSubject(name: "Medicina Preventiva", questionCount: 10, topics: ["Epidemiologia"])
            ],
            questionCount: 100,
            durationMinutes: 300,
            difficulty: .hard,
            ementa: nil,
            sourceURL: nil
        ),
    ]

    // MARK: - ENAMED 2026 Ementa

    private static let enamed2026Ementa = ExamEmenta(
        version: "2026",
        areas: [
            EmentaArea(subject: "Clínica Médica", themes: [
                EmentaTheme(name: "Cardiologia", topics: ["IAM", "IC", "HAS", "FA", "Valvopatias", "Endocardite"], frequencyScore: 5),
                EmentaTheme(name: "Pneumologia", topics: ["DPOC", "Asma", "TEP", "Pneumonias", "Derrame Pleural"], frequencyScore: 4),
                EmentaTheme(name: "Endocrinologia", topics: ["DM", "Tireoide", "Suprarrenal", "Hipófise"], frequencyScore: 4),
                EmentaTheme(name: "Nefrologia", topics: ["IRA", "IRC", "Distúrbios Eletrolíticos", "Síndrome Nefrótica/Nefrítica"], frequencyScore: 4),
                EmentaTheme(name: "Infectologia", topics: ["HIV/AIDS", "Tuberculose", "Hepatites", "Dengue", "Sífilis"], frequencyScore: 5),
                EmentaTheme(name: "Gastroenterologia", topics: ["Hepatopatias", "DII", "DRGE", "Pancreatite"], frequencyScore: 3),
                EmentaTheme(name: "Hematologia", topics: ["Anemias", "Leucemias", "Distúrbios de Coagulação"], frequencyScore: 3),
                EmentaTheme(name: "Reumatologia", topics: ["LES", "AR", "Vasculites"], frequencyScore: 2),
            ]),
            EmentaArea(subject: "Cirurgia Geral", themes: [
                EmentaTheme(name: "Trauma", topics: ["ATLS", "Trauma Abdominal", "TCE", "Trauma Torácico"], frequencyScore: 5),
                EmentaTheme(name: "Abdome Agudo", topics: ["Apendicite", "Colecistite", "Obstrução Intestinal", "Úlcera Perfurada"], frequencyScore: 5),
                EmentaTheme(name: "Hérnias", topics: ["Inguinal", "Incisional", "Umbilical"], frequencyScore: 4),
                EmentaTheme(name: "Vias Biliares", topics: ["Colelitíase", "Colangite", "CPRE"], frequencyScore: 4),
                EmentaTheme(name: "Pré/Pós-Operatório", topics: ["Avaliação Pré-Operatória", "Complicações", "Cicatrização"], frequencyScore: 3),
            ]),
            EmentaArea(subject: "Pediatria", themes: [
                EmentaTheme(name: "Neonatologia", topics: ["RN Prematuro", "Icterícia Neonatal", "Sepse Neonatal", "Reanimação"], frequencyScore: 5),
                EmentaTheme(name: "Puericultura", topics: ["DNPM", "Aleitamento", "Alimentação Complementar", "Crescimento"], frequencyScore: 4),
                EmentaTheme(name: "Imunizações", topics: ["Calendário Vacinal", "Eventos Adversos", "Contraindicações"], frequencyScore: 5),
                EmentaTheme(name: "Infectologia Pediátrica", topics: ["Exantemáticas", "IVAS", "Pneumonia", "Meningite"], frequencyScore: 4),
                EmentaTheme(name: "Diarreia e Desidratação", topics: ["TRO", "Classificação", "Desnutrição"], frequencyScore: 4),
            ]),
            EmentaArea(subject: "Ginecologia e Obstetrícia", themes: [
                EmentaTheme(name: "Pré-Natal", topics: ["Rotina", "Exames", "Suplementação", "Imunização"], frequencyScore: 5),
                EmentaTheme(name: "Parto", topics: ["Assistência ao Parto", "Indicações de Cesárea", "Partograma"], frequencyScore: 4),
                EmentaTheme(name: "Síndromes Hipertensivas", topics: ["Pré-eclâmpsia", "Eclâmpsia", "HELLP"], frequencyScore: 5),
                EmentaTheme(name: "Sangramento na Gestação", topics: ["DPP", "Placenta Prévia", "Gravidez Ectópica"], frequencyScore: 4),
                EmentaTheme(name: "Rastreamento", topics: ["Ca Colo Uterino", "Ca Mama", "Papanicolau"], frequencyScore: 4),
                EmentaTheme(name: "Contracepção", topics: ["Métodos", "Contraindicações", "Planejamento Familiar"], frequencyScore: 3),
            ]),
            EmentaArea(subject: "Medicina Preventiva", themes: [
                EmentaTheme(name: "Epidemiologia", topics: ["Medidas de Frequência", "Estudos Epidemiológicos", "Causalidade"], frequencyScore: 5),
                EmentaTheme(name: "Bioestatística", topics: ["Sensibilidade", "Especificidade", "VPP/VPN", "Curva ROC"], frequencyScore: 4),
                EmentaTheme(name: "SUS", topics: ["Princípios e Diretrizes", "Leis 8080/8142", "PNAB", "Redes de Atenção"], frequencyScore: 5),
                EmentaTheme(name: "Vigilância", topics: ["Doenças de Notificação", "Surtos", "Investigação Epidemiológica"], frequencyScore: 4),
                EmentaTheme(name: "APS/ESF", topics: ["Atributos da APS", "Território", "Visita Domiciliar"], frequencyScore: 3),
            ]),
        ]
    )

    // MARK: - Helpers

    static func examsForInstitution(_ institution: String) -> [Exam] {
        exams.filter { $0.institution == institution }
    }

    static func upcomingExams() -> [Exam] {
        exams.filter { $0.isUpcoming }.sorted { ($0.examDate ?? .distantFuture) < ($1.examDate ?? .distantFuture) }
    }

    static func examDate(institution: String, year: Int) -> Date? {
        exams.first { $0.institution == institution && $0.year == year }?.examDate
    }

    private static func date(_ string: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "pt_BR")
        return f.date(from: string)
    }
}
