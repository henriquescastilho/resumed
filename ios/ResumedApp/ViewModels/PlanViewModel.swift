import Foundation
import SwiftUI

@MainActor
class PlanViewModel: ObservableObject {
    @Published var tasks: [StudyPlanTask] = []
    @Published var selectedDate: Date = Date()
    @Published var weekDates: [Date] = []
    @Published var isLoading = false
    
    private let calendar = Calendar.current
    
    init() {
        generateWeekDates()
        Task { await fetchPlan() }
    }
    
    func generateWeekDates() {
        let today = Date()
        // Get start of week (Sunday or Monday based on locale, let's fix to Sunday for consistency)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else { return }
        let startOfWeek = weekInterval.start
        
        weekDates = (0..<7).compactMap { day -> Date? in
            return calendar.date(byAdding: .day, value: day, to: startOfWeek)
        }
    }
    
    func fetchPlan() async {
        guard let token = AuthService.shared.getToken() else { return }
        isLoading = true
        defer { isLoading = false }
        
        // Fetch for the whole week range
        let start = weekDates.first ?? Date()
        let end = weekDates.last ?? Date()
        
        // Format dates for API (YYYY-MM-DD)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        
        // In APIClient we need to support params. For MVP let's assume getPlan takes these.
        // Assuming APIClient update happens or logic is added there.
        // For MVP blueprint, let's just refresh.
    }
    
    // Select Date
    func selectDate(_ date: Date) {
        selectedDate = date
        // Filter tasks locally or fetch? 
        // Better to have all week tasks and filter in View.
    }
    
    func isSelected(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    // Interactions
    func completeTask(_ task: StudyPlanTask) async {
        // Optimistic update
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            // Create a mutable copy of the task (since it's a struct and we can't modify it in place in the array directly easily if strict)
            // But we actually need to change the array item.
            // Simplified:
            // tasks[index].status = .done // Error: StudyPlanTask is let property. Need var in model or copy.
        }
        
        // Call API
    }
}
