//
//  PlacementTestModels.swift
//  Resumed
//
//  Placement Test — Value Types & Embedded Question Bank
//

import SwiftUI

// MARK: - Specialty

enum PlacementSpecialty: String, CaseIterable, Codable {
    case clinica    = "Clínica Médica"
    case cirurgia   = "Cirurgia Geral"
    case pediatria  = "Pediatria"
    case gineco     = "Ginecologia e Obstetrícia"
    case preventiva = "Medicina Preventiva"

    var color: Color {
        switch self {
        case .clinica:    return .resumed.clinicaMedica
        case .cirurgia:   return .resumed.cirurgia
        case .pediatria:  return .resumed.pediatria
        case .gineco:     return .resumed.ginecologia
        case .preventiva: return .resumed.preventiva
        }
    }

    var icon: String {
        switch self {
        case .clinica:    return "stethoscope"
        case .cirurgia:   return "scissors"
        case .pediatria:  return "figure.child"
        case .gineco:     return "heart.fill"
        case .preventiva: return "shield.fill"
        }
    }
}

// MARK: - Level

enum SpecialtyLevel: String, Codable, CaseIterable {
    case forte, medio, fraco

    var displayName: String {
        switch self {
        case .forte: return "Forte"
        case .medio: return "Médio"
        case .fraco: return "Fraco"
        }
    }

    var color: Color {
        switch self {
        case .forte: return .resumed.success
        case .medio: return .resumed.warning
        case .fraco: return .resumed.error
        }
    }

    var icon: String {
        switch self {
        case .forte: return "star.fill"
        case .medio: return "star.leadinghalf.filled"
        case .fraco: return "star"
        }
    }

    var studyWeight: Double {
        switch self {
        case .forte: return 0.6
        case .medio: return 1.0
        case .fraco: return 1.5
        }
    }
}

// MARK: - Result

struct PlacementTestResult: Codable {
    let completedAt: Date
    var specialtyLevels: [String: String]
    var suggestedPriority: [String]

    func level(for specialty: PlacementSpecialty) -> SpecialtyLevel {
        guard let raw = specialtyLevels[specialty.rawValue],
              let level = SpecialtyLevel(rawValue: raw) else { return .medio }
        return level
    }
}

// MARK: - Placement Question

struct PlacementQuestion: Identifiable {
    let id: String
    let specialty: PlacementSpecialty
    let difficulty: QuestionDifficulty
    let statement: String
    let options: [QuestionOption]
    let correctOptionId: String
    let explanation: String

    var asQuestion: Question {
        Question(
            id: id,
            statement: statement,
            options: options,
            correctOptionId: correctOptionId,
            explanation: explanation,
            subject: specialty.rawValue,
            difficulty: difficulty
        )
    }
}

// MARK: - Embedded Question Bank

extension PlacementQuestion {
    static let bank: [PlacementQuestion] = clinicaQ + cirurgiaQ + pediatriaQ + ginecoQ + preventivaQ

    static func questions(for specialty: PlacementSpecialty, difficulty: QuestionDifficulty) -> [PlacementQuestion] {
        bank.filter { $0.specialty == specialty && $0.difficulty == difficulty }
    }

    // MARK: Clínica Médica

    static let clinicaQ: [PlacementQuestion] = [
        PlacementQuestion(id: "pt_cm_m1", specialty: .clinica, difficulty: .medium,
            statement: "Homem de 62 anos, diabético tipo 2 (HbA1c 8,5%), com creatinina 1,8 mg/dL. Qual hipoglicemiante está contraindicado?",
            options: [
                QuestionOption(id: "A", text: "Empagliflozina"),
                QuestionOption(id: "B", text: "Sitagliptina"),
                QuestionOption(id: "C", text: "Metformina"),
                QuestionOption(id: "D", text: "Insulina glargina")
            ],
            correctOptionId: "C",
            explanation: "Metformina é contraindicada com TFG < 30 mL/min pelo risco de acidose lática. Com creatinina 1,8 em idoso, a TFG estimada está frequentemente abaixo desse limiar."
        ),
        PlacementQuestion(id: "pt_cm_h1", specialty: .clinica, difficulty: .hard,
            statement: "Mulher de 45 anos com LES desenvolve nefrite lúpica classe IV (biópsia). Qual esquema de indução é padrão-ouro?",
            options: [
                QuestionOption(id: "A", text: "Prednisona isolada"),
                QuestionOption(id: "B", text: "Hidroxicloroquina + azatioprina"),
                QuestionOption(id: "C", text: "Pulsoterapia com metilprednisolona + ciclofosfamida"),
                QuestionOption(id: "D", text: "Micofenolato mofetil isolado")
            ],
            correctOptionId: "C",
            explanation: "Nefrite lúpica classe IV: pulsoterapia com metilprednisolona EV + ciclofosfamida (protocolo NIH). Micofenolato é alternativa não inferior, mas o padrão clássico cobrado em residência é ciclofosfamida."
        ),
    ]

    // MARK: Cirurgia Geral

    static let cirurgiaQ: [PlacementQuestion] = [
        PlacementQuestion(id: "pt_cg_m1", specialty: .cirurgia, difficulty: .medium,
            statement: "Paciente pós-colecistectomia laparoscópica evolui no 2° PO com icterícia e dilatação de vias biliares na USG. Diagnóstico mais provável?",
            options: [
                QuestionOption(id: "A", text: "Coledocolitíase residual"),
                QuestionOption(id: "B", text: "Lesão iatrogênica da via biliar"),
                QuestionOption(id: "C", text: "Pancreatite pós-operatória"),
                QuestionOption(id: "D", text: "Fístula biliar")
            ],
            correctOptionId: "B",
            explanation: "Icterícia progressiva + dilatação biliar no PO imediato de colecistectomia = lesão iatrogênica da via biliar. Complicação mais temida do procedimento."
        ),
        PlacementQuestion(id: "pt_cg_h1", specialty: .cirurgia, difficulty: .hard,
            statement: "Hérnia inguinal indireta irredutível há 12h, sem sinais de isquemia. Conduta inicial?",
            options: [
                QuestionOption(id: "A", text: "Cirurgia de emergência imediata"),
                QuestionOption(id: "B", text: "Tentativa de redução manual sob analgesia e sedação"),
                QuestionOption(id: "C", text: "Antibióticos e aguardar 24h"),
                QuestionOption(id: "D", text: "Herniotomia laparoscópica eletiva")
            ],
            correctOptionId: "B",
            explanation: "Hérnia encarcerada sem estrangulamento (< 12h, sem eritema/febre) admite tentativa de redução manual (taxis). Se sucesso, cirurgia eletiva em 24-48h. Na falha ou estrangulamento, cirurgia de urgência."
        ),
    ]

    // MARK: Pediatria

    static let pediatriaQ: [PlacementQuestion] = [
        PlacementQuestion(id: "pt_ped_m1", specialty: .pediatria, difficulty: .medium,
            statement: "Menino de 8 anos com sopro sistólico III/VI em foco pulmonar e desdobramento fixo de B2, acianótico. Cardiopatia mais compatível?",
            options: [
                QuestionOption(id: "A", text: "CIV"),
                QuestionOption(id: "B", text: "CIA"),
                QuestionOption(id: "C", text: "PCA"),
                QuestionOption(id: "D", text: "Estenose pulmonar valvar")
            ],
            correctOptionId: "B",
            explanation: "Desdobramento fixo de B2 (não varia com respiração) é patognomônico de CIA. O shunt E→D mantém enchimento do VD constante. Sopro em foco pulmonar pelo aumento do fluxo transpulmonar."
        ),
        PlacementQuestion(id: "pt_ped_h1", specialty: .pediatria, difficulty: .hard,
            statement: "RN a termo com hipoglicemia persistente (< 40 mg/dL) refratária à glicose 10% a 8 mg/kg/min. Investigar:",
            options: [
                QuestionOption(id: "A", text: "Hipoglicemia transitória do RN"),
                QuestionOption(id: "B", text: "Hiperinsulinismo congênito"),
                QuestionOption(id: "C", text: "Galactosemia"),
                QuestionOption(id: "D", text: "Sepse neonatal")
            ],
            correctOptionId: "B",
            explanation: "Hipoglicemia refratária (necessita > 8 mg/kg/min) em RN a termo sem fatores de risco = hiperinsulinismo congênito. Dosagem de insulina durante hipoglicemia confirma."
        ),
    ]

    // MARK: Ginecologia e Obstetrícia

    static let ginecoQ: [PlacementQuestion] = [
        PlacementQuestion(id: "pt_go_m1", specialty: .gineco, difficulty: .medium,
            statement: "Mulher de 32 anos, nulípara, mioma intramural 4cm, menorragia, Hb 8,5. Deseja fertilidade. Tratamento?",
            options: [
                QuestionOption(id: "A", text: "Histerectomia total"),
                QuestionOption(id: "B", text: "Miomectomia"),
                QuestionOption(id: "C", text: "Embolização da artéria uterina"),
                QuestionOption(id: "D", text: "Análogo de GnRH definitivo")
            ],
            correctOptionId: "B",
            explanation: "Miomectomia é o tratamento padrão para mioma sintomático em mulher que deseja preservar o útero e a fertilidade."
        ),
        PlacementQuestion(id: "pt_go_h1", specialty: .gineco, difficulty: .hard,
            statement: "Gestante 36 semanas com placenta prévia total assintomática confirmada por USG. Conduta?",
            options: [
                QuestionOption(id: "A", text: "Parto normal se sem sangramento"),
                QuestionOption(id: "B", text: "Cesariana eletiva 36-37 semanas"),
                QuestionOption(id: "C", text: "Aguardar TP espontâneo"),
                QuestionOption(id: "D", text: "Indução com ocitocina após 37s")
            ],
            correctOptionId: "B",
            explanation: "Placenta prévia total = indicação absoluta de cesárea. Momento ideal: 36-37 semanas, antes do TP espontâneo que aumenta risco de sangramento."
        ),
    ]

    // MARK: Medicina Preventiva

    static let preventivaQ: [PlacementQuestion] = [
        PlacementQuestion(id: "pt_mp_m1", specialty: .preventiva, difficulty: .medium,
            statement: "Teste para TB: sensibilidade 80%, especificidade 90%. Prevalência 10%. VPP?",
            options: [
                QuestionOption(id: "A", text: "47%"),
                QuestionOption(id: "B", text: "80%"),
                QuestionOption(id: "C", text: "89%"),
                QuestionOption(id: "D", text: "99%")
            ],
            correctOptionId: "A",
            explanation: "VP = 80, FP = 90. VPP = 80/(80+90) ≈ 47%. Baixa prevalência dilui o VPP mesmo com boa especificidade."
        ),
        PlacementQuestion(id: "pt_mp_h1", specialty: .preventiva, difficulty: .hard,
            statement: "No modelo de Determinantes Sociais de Dahlgren e Whitehead, qual camada representa fatores socioeconômicos, culturais e ambientais gerais?",
            options: [
                QuestionOption(id: "A", text: "Camada mais interna — constitucionais"),
                QuestionOption(id: "B", text: "Segunda camada — estilo de vida"),
                QuestionOption(id: "C", text: "Terceira camada — redes sociais"),
                QuestionOption(id: "D", text: "Camada mais externa — condições macro")
            ],
            correctOptionId: "D",
            explanation: "A camada mais externa (4ª) engloba condições socioeconômicas, culturais e ambientais gerais. É o foco das políticas públicas de maior escopo."
        ),
    ]
}
