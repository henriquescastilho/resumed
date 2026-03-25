//
//  StudyWidgetIntents.swift
//  ResumedWidget
//
//  Interactive widget intent for completing study tasks directly from the widget.
//  Requires iOS 17+.
//

import Foundation
import AppIntents
import WidgetKit

@available(iOS 17.0, *)
struct CompleteStudyTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Completar Tarefa"
    static var description = IntentDescription("Marca uma tarefa de estudo como concluída.")

    @Parameter(title: "ID da Tarefa")
    var taskId: String

    init() {}

    init(taskId: String) {
        self.taskId = taskId
    }

    func perform() async throws -> some IntentResult {
        // Write the taskId to the App Group pending completions list
        let suiteName = "group.com.resumed.app"
        if let defaults = UserDefaults(suiteName: suiteName) {
            var pending = defaults.stringArray(forKey: "widget_pending_completions") ?? []
            if !pending.contains(taskId) {
                pending.append(taskId)
            }
            defaults.set(pending, forKey: "widget_pending_completions")
        }
        // Tell WidgetKit to refresh so the checkbox updates optimistically
        WidgetCenter.shared.reloadTimelines(ofKind: "StudyDayProgressWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "StudyNextTaskWidget")
        return .result()
    }
}
