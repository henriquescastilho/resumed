import SwiftUI

// Step 1: Welcome
struct OnboardingWelcomeView: View {
    var nextAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Estudar com método\nmuda tudo.")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Text("Vamos personalizar seu plano de estudos para garantir sua aprovação.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 30)
            Spacer()
            
            Button(action: nextAction) {
                Text("Começar")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "D4A54A"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}

// Step 2: Exams
struct OnboardingExamsView: View {
    @Binding var selectedExams: [String]
    var nextAction: () -> Void
    
    let options = ["ENAMED", "Revalida", "USP-SP", "SUS-SP", "PSU-MG"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Qual seu foco?")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { exam in
                        Button(action: {
                            if selectedExams.contains(exam) {
                                selectedExams.removeAll(where: { $0 == exam })
                            } else {
                                selectedExams.append(exam)
                            }
                        }) {
                            HStack {
                                Text(exam)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                Spacer()
                                if selectedExams.contains(exam) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "D4A54A"))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(hex: "141414"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedExams.contains(exam) ? Color(hex: "D4A54A") : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            Button(action: nextAction) {
                Text("Continuar")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedExams.isEmpty ? Color.gray : Color(hex: "D4A54A"))
                    .cornerRadius(12)
            }
            .disabled(selectedExams.isEmpty)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }
}

// Step 3: Available Days & Hours
struct OnboardingRoutineView: View {
    @Binding var selectedDays: [Int]
    @Binding var hoursPerDay: Int
    var nextAction: () -> Void
    
    let days = ["D", "S", "T", "Q", "Q", "S", "S"]
    // Backend expects 1=Mon, 7=Sun.
    // UI: Index 0=Sun, 1=Mon... -> Map needed.
    // Let's assume UI index 0 is Sunday (7), 1 is Monday (1)
    
    func mapIndexToBackend(_ index: Int) -> Int {
        return index == 0 ? 7 : index
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Sua Rotina")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Dias disponíveis")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack {
                    ForEach(0..<7) { index in
                        let dayVal = mapIndexToBackend(index)
                        Button(action: {
                            if selectedDays.contains(dayVal) {
                                selectedDays.removeAll(where: { $0 == dayVal })
                            } else {
                                selectedDays.append(dayVal)
                            }
                        }) {
                            Circle()
                                .fill(selectedDays.contains(dayVal) ? Color(hex: "D4A54A") : Color(hex: "141414"))
                                .overlay(
                                    Text(days[index])
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(selectedDays.contains(dayVal) ? .black : .white)
                                )
                                .frame(height: 40)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Horas por dia")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(hoursPerDay)h")
                        .font(.title2)
                        .bold()
                        .foregroundColor(Color(hex: "D4A54A"))
                }
                
                Slider(value: Binding(
                    get: { Double(hoursPerDay) },
                    set: { hoursPerDay = Int($0) }
                ), in: 1...12, step: 1)
                .accentColor(Color(hex: "D4A54A"))
            }
            
            Spacer()
            
            Button(action: nextAction) {
                Text("Gerar Plano")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedDays.isEmpty ? Color.gray : Color(hex: "D4A54A"))
                    .cornerRadius(12)
            }
            .disabled(selectedDays.isEmpty)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }
}

// Step 4: Processing
struct OnboardingProcessingView: View {
    var finishAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color(hex: "D4A54A"))
                .scaleEffect(1.5)
            
            Text("Criando seu cronograma...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .onAppear {
            // Simulate processing time then finish
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                finishAction()
            }
        }
    }
}
