//
//  EventKitService.swift
//  Resumed
//
//  Apple Calendar integration for study plan export
//

import EventKit
import SwiftUI
import Combine

enum EventKitError: LocalizedError {
    case accessDenied
    case calendarNotFound
    case eventSaveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Acesso ao calendário negado. Verifique as permissões nas Configurações."
        case .calendarNotFound:
            return "Não foi possível encontrar ou criar o calendário de estudos."
        case .eventSaveFailed(let error):
            return "Erro ao salvar evento: \(error.localizedDescription)"
        }
    }
}

@MainActor
final class EventKitService: ObservableObject {
    static let shared = EventKitService()

    private let store = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    private static let calendarName = "Resumed — Plano de Estudos"

    private init() {
        refreshStatus()
    }

    // MARK: - Authorization

    func refreshStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        let granted: Bool
        if #available(iOS 17.0, *) {
            do {
                granted = try await store.requestFullAccessToEvents()
            } catch {
                granted = false
            }
        } else {
            granted = await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { success, _ in
                    continuation.resume(returning: success)
                }
            }
        }
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        return granted
    }

    // MARK: - Export

    /// Export a single task to Calendar. Returns the EKEvent identifier.
    func exportTask(_ task: StudyTask, on date: Date) async throws -> String {
        guard await ensureAccess() else { throw EventKitError.accessDenied }

        let calendar = try findOrCreateCalendar()
        let event = EKEvent(eventStore: store)

        event.calendar = calendar
        event.title = "[\(task.subject)] \(task.theme ?? "Estudo")"

        let startDate: Date
        if let specificTime = task.startTime {
            startDate = specificTime
        } else {
            startDate = defaultStartTime(on: date, hour: 8, minute: 0)
        }

        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(TimeInterval(task.estimatedMinutes * 60))

        // 5-minute alarm
        let alarm = EKAlarm(relativeOffset: -5 * 60)
        event.addAlarm(alarm)

        do {
            try store.save(event, span: .thisEvent)
        } catch {
            throw EventKitError.eventSaveFailed(error)
        }

        return event.eventIdentifier ?? UUID().uuidString
    }

    /// Export all tasks in a DayPlan to Calendar, stacking sequentially from 08:00.
    func exportDayPlan(_ day: DayPlan) async throws {
        guard await ensureAccess() else { throw EventKitError.accessDenied }

        let calendar = try findOrCreateCalendar()

        var cursor = defaultStartTime(on: day.date, hour: 8, minute: 0)

        for task in day.tasks {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = "[\(task.subject)] \(task.theme ?? "Estudo")"

            let startDate: Date
            if let specificTime = task.startTime {
                startDate = specificTime
            } else {
                startDate = cursor
            }

            let endDate = startDate.addingTimeInterval(TimeInterval(task.estimatedMinutes * 60))
            event.startDate = startDate
            event.endDate = endDate

            let alarm = EKAlarm(relativeOffset: -5 * 60)
            event.addAlarm(alarm)

            do {
                try store.save(event, span: .thisEvent)
                // Advance cursor for next task (5-min break between blocks)
                cursor = endDate.addingTimeInterval(5 * 60)
            } catch {
                throw EventKitError.eventSaveFailed(error)
            }
        }
    }

    /// Remove all events from the Resumed calendar.
    func deleteAllResumedEvents() async throws {
        guard await ensureAccess() else { throw EventKitError.accessDenied }

        let predicate = store.predicateForEvents(
            withStart: Date.distantPast,
            end: Date.distantFuture,
            calendars: [try findOrCreateCalendar()]
        )

        let events = store.events(matching: predicate)
        for event in events {
            do {
                try store.remove(event, span: .thisEvent)
            } catch {
                // Continue removing remaining events even if one fails
                print("[EventKitService] Warning: failed to remove event: \(error)")
            }
        }
    }

    // MARK: - Private helpers

    private func ensureAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess:
            return true
        case .authorized:
            return true
        case .notDetermined:
            return await requestAccess()
        default:
            return false
        }
    }

    private func findOrCreateCalendar() throws -> EKCalendar {
        // Look for existing Resumed calendar
        if let existing = store.calendars(for: .event).first(where: { $0.title == Self.calendarName }) {
            return existing
        }

        // Create new calendar
        guard let source = bestSource() else {
            throw EventKitError.calendarNotFound
        }

        let newCalendar = EKCalendar(for: .event, eventStore: store)
        newCalendar.title = Self.calendarName
        newCalendar.source = source
        newCalendar.cgColor = UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0).cgColor // Gold

        do {
            try store.saveCalendar(newCalendar, commit: true)
            return newCalendar
        } catch {
            throw EventKitError.calendarNotFound
        }
    }

    private func bestSource() -> EKSource? {
        // Prefer iCloud, then local
        let sources = store.sources
        if let icloud = sources.first(where: { $0.sourceType == .calDAV && $0.title.lowercased().contains("icloud") }) {
            return icloud
        }
        if let calDAV = sources.first(where: { $0.sourceType == .calDAV }) {
            return calDAV
        }
        return sources.first(where: { $0.sourceType == .local })
    }

    private func defaultStartTime(on date: Date, hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? date
    }
}
