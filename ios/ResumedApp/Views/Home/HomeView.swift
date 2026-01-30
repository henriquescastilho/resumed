import SwiftUI

struct HomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        VStack {
            Text("Bem-vindo ao Resumed!")
                .font(.title)
                .padding()
            
            if let user = sessionManager.currentUser {
                Text("Olá, \(user.full_name ?? "Doutor(a)")")
                Text("Plano de estudos configurado.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button("Sair") {
                sessionManager.logout()
            }
            .padding()
        }
    }
}
