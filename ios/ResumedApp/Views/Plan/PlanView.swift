import SwiftUI

struct PlanView: View {
    @StateObject private var viewModel = PlanViewModel()
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A0A").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header / Calendar Strip
                VStack(spacing: 15) {
                    Text("Meu Plano")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.weekDates, id: \.self) { date in
                                DayCapsule(
                                    date: date,
                                    isSelected: viewModel.isSelected(date),
                                    action: { viewModel.selectDate(date) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 10)
                }
                .background(Color(hex: "141414"))
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(Color(hex: "D4A54A"))
                    Spacer()
                } else {
                    List {
                        // Filter tasks for selected day
                        // Mock data for now as ViewModel fetch isn't fully wired to APIClient yet
                        TaskRow(title: "Estudar Cardiologia", time: "60 min", status: .pending)
                        TaskRow(title: "Revisão Flashcards", time: "30 min", status: .done)
                    }
                    .listStyle(.plain)
                    .background(Color(hex: "0A0A0A"))
                }
            }
        }
    }
}

struct DayCapsule: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f
    }()
    
    private let numFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(dayFormatter.string(from: date).uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                Text(numFormatter.string(from: date))
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(isSelected ? .black : .gray)
            .frame(width: 45, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 22.5)
                    .fill(isSelected ? Color(hex: "D4A54A") : Color(hex: "1C1C1E"))
            )
        }
    }
}

struct TaskRow: View {
    let title: String
    let time: String
    let status: TaskStatus
    
    var body: some View {
        HStack {
            Image(systemName: status == .done ? "checkmark.circle.fill" : "circle")
                .foregroundColor(status == .done ? .green : .gray)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(status == .done ? .gray : .white)
                    .strikethrough(status == .done)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color(hex: "141414"))
        .cornerRadius(12)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .padding(.vertical, 4)
    }
}
