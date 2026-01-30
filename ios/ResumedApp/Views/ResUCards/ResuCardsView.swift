import SwiftUI

struct ResuCardsView: View {
    @State private var offset = CGSize.zero
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A0A").ignoresSafeArea()
            
            VStack {
                // Header
                Text("Revisão Diária")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top)
                
                Spacer()
                
                // Card Area
                ZStack {
                    if isFlipped {
                        CardBack(text: "Insuficiência Cardíaca Direta com Ingurgitamento Jugular.")
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    } else {
                        CardFront(text: "O que é o sinal de Kussmaul?")
                    }
                }
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .animation(.spring(), value: isFlipped)
                .onTapGesture {
                    isFlipped.toggle()
                }
                .padding()
                
                Spacer()
                
                // Controls
                if isFlipped {
                    HStack(spacing: 20) {
                        ReviewButton(label: "Errei", color: .red)
                        ReviewButton(label: "Difícil", color: .orange)
                        ReviewButton(label: "Bom", color: .blue)
                        ReviewButton(label: "Fácil", color: .green)
                    }
                    .padding(.bottom, 30)
                    .transition(.opacity)
                } else {
                    Text("Toque para virar")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 50)
                }
            }
        }
    }
}

struct CardFront: View {
    let text: String
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(hex: "141414"))
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            .overlay(
                Text(text)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            )
            .frame(height: 400)
    }
}

struct CardBack: View {
    let text: String
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(hex: "1C1C1E"))
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            .overlay(
                Text(text)
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            )
            .frame(height: 400)
    }
}

struct ReviewButton: View {
    let label: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            Text(label)
                .fontWeight(.bold)
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(color.opacity(0.2))
                .clipShape(Circle())
                .overlay(Circle().stroke(color, lineWidth: 2))
        }
    }
}
