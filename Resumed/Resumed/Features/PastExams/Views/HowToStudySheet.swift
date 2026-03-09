//
//  HowToStudySheet.swift
//  Resumed
//
//  Study method guidance
//

import SwiftUI

struct HowToStudySheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Como estudar")
                        .font(.resumed.h2)
                        .foregroundColor(.resumed.white)

                    Text("Método Resumed (rápido e eficiente)")
                        .font(.resumed.h4)
                        .foregroundColor(.resumed.gold)

                    InfoBlock(title: "1. Entenda o objetivo", message: "Você precisa garantir o mínimo em todas as áreas (ENAMED sem peso). Foque em consistência diária, não em volume único.")

                    InfoBlock(title: "2. Estudo ativo", message: "Leia o tema do dia, resuma em 3 pontos e faça 5–10 questões para fixar. Se errar, marque para revisão.")

                    InfoBlock(title: "3. Revisões periódicas", message: "Erros voltam em 3, 7, 15 e 30 dias. Não pule revisões: elas são onde a nota cresce.")

                    InfoBlock(title: "4. Simulado com timer", message: "Inicie a prova anterior com tempo real. Ao final, registre acertos e erros para calibrar seu plano.")

                    InfoBlock(title: "5. Fechamento da semana", message: "Se faltar estudo em alguma área, ela sobe na prioridade da semana seguinte.")
                }
                .padding(Spacing.md)
            }
            .background(Color.resumed.black)
            .navigationTitle("Como estudar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
        }
    }
}

private struct InfoBlock: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.resumed.h4)
                .foregroundColor(.resumed.white)
            Text(message)
                .font(.resumed.bodySmall)
                .foregroundColor(.resumed.gray)
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
    }
}
