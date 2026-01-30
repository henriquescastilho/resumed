import SwiftUI

struct PracticeView: View {
    @State private var questions: [Question] = []
    @State private var currentQuestionIndex = 0
    @State private var isAnswered = false
    @State private var feedback: AnswerFeedback?
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A0A").ignoresSafeArea()
            
            if questions.isEmpty {
                VStack {
                    Text("Carregando questes...")
                        .foregroundColor(.gray)
                    ProgressView().tint(Color(hex: "D4A54A"))
                }
                .onAppear {
                    loadQuestions()
                }
            } else {
                VStack {
                    // Header
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("Questão \(currentQuestionIndex + 1)/\(questions.count)")
                            .foregroundColor(.gray)
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                    
                    // Question
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(questions[currentQuestionIndex].text)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(questions[currentQuestionIndex].options, id: \.id) { option in
                                    OptionButton(
                                        option: option,
                                        state: getOptionState(option),
                                        action: { submitAnswer(option) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            if isAnswered, let fb = feedback {
                                VStack(alignment: .leading) {
                                    Text(fb.isCorrect ? "Correto!" : "Incorreto")
                                        .font(.headline)
                                        .foregroundColor(fb.isCorrect ? .green : .red)
                                    
                                    Text(fb.explanation)
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .padding(.top, 4)
                                    
                                    Button(action: nextQuestion) {
                                        Text("Próxima")
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color(hex: "D4A54A"))
                                            .cornerRadius(12)
                                    }
                                    .padding(.top, 10)
                                }
                                .padding()
                                .background(Color(hex: "1C1C1E"))
                                .cornerRadius(16)
                                .padding()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadQuestions() {
        // Mock load
        questions = [
            Question(id: "1", text: "Qual o tratamento de escolha para Sífilis Primária?", options: [
                QuestionOption(id: "A", text: "Ciprofloxacino"),
                QuestionOption(id: "B", text: "Penicilina G Benzatina"),
                QuestionOption(id: "C", text: "Azitromicina"),
                QuestionOption(id: "D", text: "Doxiciclina")
            ])
        ]
    }
    
    func submitAnswer(_ option: QuestionOption) {
        guard !isAnswered else { return }
        isAnswered = true
        // Mock check
        let isCorrect = (option.id == "B")
        feedback = AnswerFeedback(isCorrect: isCorrect, correctOptionId: "B", explanation: "Penicilina é a escolha.")
    }
    
    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            isAnswered = false
            feedback = nil
        } else {
            // Finish
        }
    }
    
    func getOptionState(_ option: QuestionOption) -> OptionState {
        if !isAnswered { return .neutral }
        if option.id == feedback?.correctOptionId { return .correct }
        if isAnswered && option.id != feedback?.correctOptionId && option.id == selectedOptionId { return .wrong } // Need to track selected
        return .disabled
    }
    
    @State private var selectedOptionId: String?
}

// Models
struct Question: Identifiable {
    let id: String
    let text: String
    let options: [QuestionOption]
}
struct QuestionOption: Identifiable {
    let id: String
    let text: String
}
struct AnswerFeedback {
    let isCorrect: Bool
    let correctOptionId: String
    let explanation: String
}
enum OptionState {
    case neutral, correct, wrong, disabled
}

struct OptionButton: View {
    let option: QuestionOption
    let state: OptionState
    let action: () -> Void
    
    var color: Color {
        switch state {
        case .neutral: return Color(hex: "141414")
        case .correct: return .green.opacity(0.2)
        case .wrong: return .red.opacity(0.2)
        case .disabled: return Color(hex: "141414").opacity(0.5)
        }
    }
    
    var borderColor: Color {
        switch state {
        case .correct: return .green
        case .wrong: return .red
        default: return .clear
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.id)
                    .fontWeight(.bold)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                Text(option.text)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding()
            .background(color)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 2))
        }
        .foregroundColor(.white)
        .disabled(state != .neutral)
    }
}
