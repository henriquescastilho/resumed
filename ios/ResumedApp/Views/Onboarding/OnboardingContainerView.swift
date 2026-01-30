import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var currentPage = 0
    @State private var profileData = APIClient.ProfileUpdatePayload(
        full_name: nil,
        target_exams: [],
        available_days: [],
        hours_per_day: 4,
        level_assessment: [:]
    )
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A0A").ignoresSafeArea()
            
            VStack {
                // Progress Bar
                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        Rectangle()
                            .fill(index <= currentPage ? Color(hex: "D4A54A") : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                // Content
                TabView(selection: $currentPage) {
                    OnboardingWelcomeView(nextAction: nextPage)
                        .tag(0)
                    
                    OnboardingExamsView(selectedExams: Binding(
                        get: { profileData.target_exams },
                        set: { profileData = .init(full_name: profileData.full_name, target_exams: $0, available_days: profileData.available_days, hours_per_day: profileData.hours_per_day, level_assessment: profileData.level_assessment) }
                    ), nextAction: nextPage)
                    .tag(1)
                    
                    OnboardingRoutineView(
                        selectedDays: Binding(
                            get: { profileData.available_days },
                            set: { profileData = .init(full_name: profileData.full_name, target_exams: profileData.target_exams, available_days: $0, hours_per_day: profileData.hours_per_day, level_assessment: profileData.level_assessment) }
                        ),
                        hoursPerDay: Binding(
                            get: { profileData.hours_per_day },
                            set: { profileData = .init(full_name: profileData.full_name, target_exams: profileData.target_exams, available_days: profileData.available_days, hours_per_day: $0, level_assessment: profileData.level_assessment) }
                        ),
                        nextAction: nextPage
                    )
                    .tag(2)
                    
                    OnboardingProcessingView(finishAction: finishOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }
    
    func nextPage() {
        withAnimation {
            currentPage += 1
        }
    }
    
    func finishOnboarding() {
        Task {
            await sessionManager.completeOnboarding(profileData: profileData)
        }
    }
}
