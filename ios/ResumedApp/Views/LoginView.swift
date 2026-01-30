import SwiftUI

struct LoginView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A0A").ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo Placeholder
                Circle()
                    .strokeBorder(Color(hex: "D4A54A"), lineWidth: 2)
                    .background(Circle().fill(Color.black))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text("R")
                            .font(.system(size: 60, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "D4A54A"))
                    )
                
                VStack(spacing: 16) {
                    Text("RESUMED")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(4)
                    
                    Text("Sua residência começa aqui.")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await sessionManager.login()
                    }
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill") // Placeholder for G logo
                        Text("Continuar com Google")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}
