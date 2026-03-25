//
//  StudyTemplateLibrary.swift
//  Resumed
//
//  Pre-built and user-created study plan templates.
//

import Foundation
import UIKit

@MainActor
final class StudyTemplateLibrary {
    static let shared = StudyTemplateLibrary()

    private let customKey = "customStudyTemplates"
    private let activeKey = "activeStudyTemplateId"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Pre-built Templates

    var prebuiltTemplates: [StudyPlanTemplate] {
        [
            StudyPlanTemplate(
                id: "enamed-intensivo",
                name: "ENAMED Intensivo",
                description: "Foco em Clínica Médica e Cirurgia com alta carga diária. Ideal para 3-6 meses antes da prova.",
                targetExam: "ENAMED",
                weeklyHours: 42, // 6h/dia
                subjectWeights: [
                    "Clínica Médica": 1.8,
                    "Cirurgia Geral": 1.3,
                    "Pediatria": 1.2,
                    "Ginecologia e Obstetrícia": 1.2,
                    "MFC": 0.8,
                    "Saúde Mental": 0.7,
                    "Saúde Coletiva": 0.7
                ],
                createdByUser: false,
                isActive: false
            ),
            StudyPlanTemplate(
                id: "revalida-equilibrado",
                name: "Revalida Equilibrado",
                description: "Distribuição igual entre todas as matérias. Ideal para cobertura ampla.",
                targetExam: "Revalida",
                weeklyHours: 35, // 5h/dia
                subjectWeights: [
                    "Clínica Médica": 1.0,
                    "Cirurgia Geral": 1.0,
                    "Pediatria": 1.0,
                    "Ginecologia e Obstetrícia": 1.0,
                    "MFC": 1.0,
                    "Saúde Mental": 1.0,
                    "Saúde Coletiva": 1.0
                ],
                createdByUser: false,
                isActive: false
            ),
            StudyPlanTemplate(
                id: "reta-final-30",
                name: "Reta Final (30 dias)",
                description: "Intensivo de último mês com foco nas matérias mais cobradas. Alta carga diária.",
                targetExam: "ENAMED",
                weeklyHours: 56, // 8h/dia
                subjectWeights: [
                    "Clínica Médica": 2.0,
                    "Ginecologia e Obstetrícia": 1.5,
                    "Pediatria": 1.3,
                    "Cirurgia Geral": 1.2,
                    "MFC": 0.7,
                    "Saúde Mental": 0.7,
                    "Saúde Coletiva": 0.7
                ],
                createdByUser: false,
                isActive: false
            )
        ]
    }

    // MARK: - Custom Templates

    var customTemplates: [StudyPlanTemplate] {
        guard let data = UserDefaults.standard.data(forKey: customKey),
              let templates = try? decoder.decode([StudyPlanTemplate].self, from: data)
        else { return [] }
        return templates
    }

    var allTemplates: [StudyPlanTemplate] {
        prebuiltTemplates + customTemplates
    }

    // MARK: - Active Template

    func activeTemplate() -> StudyPlanTemplate? {
        guard let activeId = UserDefaults.standard.string(forKey: activeKey) else { return nil }
        return allTemplates.first { $0.id == activeId }
    }

    // MARK: - Apply Template

    /// Writes template settings to UserDefaults keys used by SettingsViewModel and StudyPlanViewModel.
    func apply(_ template: StudyPlanTemplate) {
        // Mark as active
        UserDefaults.standard.set(template.id, forKey: activeKey)

        // Apply hours/day (weeklyHours / 7, rounded)
        let hoursPerDay = max(1, template.weeklyHours / 7)
        UserDefaults.standard.set(hoursPerDay, forKey: "studyHoursPerDay")

        // Apply target exam
        UserDefaults.standard.set(template.targetExam, forKey: "targetExam")
        UserDefaults.standard.set(template.targetExam, forKey: "selectedExam")

        // Apply subject weights — store as JSON for buildWeeklyAllocation to consume
        if let data = try? encoder.encode(template.subjectWeights) {
            UserDefaults.standard.set(data, forKey: "templateSubjectWeights")
        }

        // Build a priority order from weights (highest weight first)
        let sortedSubjects = template.subjectWeights
            .sorted { $0.value > $1.value }
            .map { $0.key }
        UserDefaults.standard.set(sortedSubjects, forKey: "subjectPriority")

        HapticManager.shared.notification(.success)
    }

    // MARK: - Custom Template CRUD

    func saveCustom(_ template: StudyPlanTemplate) {
        var templates = customTemplates
        // Replace if same id, otherwise append
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
        if let data = try? encoder.encode(templates) {
            UserDefaults.standard.set(data, forKey: customKey)
        }
    }

    func deleteCustom(id: String) {
        var templates = customTemplates
        templates.removeAll { $0.id == id }
        if let data = try? encoder.encode(templates) {
            UserDefaults.standard.set(data, forKey: customKey)
        }
        // Clear active if it was this one
        if UserDefaults.standard.string(forKey: activeKey) == id {
            UserDefaults.standard.removeObject(forKey: activeKey)
        }
    }
}
