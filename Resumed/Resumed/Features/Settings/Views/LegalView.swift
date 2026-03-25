//
//  LegalView.swift
//  Resumed
//
//  Termos de Uso e Política de Privacidade
//

import SwiftUI

// MARK: - Legal Document Type

enum LegalDocumentType {
    case termsOfUse
    case privacyPolicy

    var title: String {
        switch self {
        case .termsOfUse: return "Termos de Uso"
        case .privacyPolicy: return "Política de Privacidade"
        }
    }

    var icon: String {
        switch self {
        case .termsOfUse: return "doc.text.fill"
        case .privacyPolicy: return "hand.raised.fill"
        }
    }

    var lastUpdated: String {
        "19 de março de 2026"
    }
}

// MARK: - Legal View

struct LegalView: View {
    let type: LegalDocumentType
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color.resumed.gold.opacity(0.1))
                                .frame(width: 64, height: 64)
                            Image(systemName: type.icon)
                                .font(.system(size: 26))
                                .foregroundColor(.resumed.gold)
                        }

                        Text(type.title)
                            .font(.resumed.h3)
                            .foregroundColor(.resumed.white)

                        Text("Última atualização: \(type.lastUpdated)")
                            .font(.resumed.caption)
                            .foregroundColor(.resumed.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.md)

                    // Content
                    switch type {
                    case .termsOfUse:
                        termsOfUseContent
                    case .privacyPolicy:
                        privacyPolicyContent
                    }

                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.resumed.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(.resumed.gray)
                }
            }
        }
    }

    // MARK: - Termos de Uso

    private var termsOfUseContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            LegalSection(number: "1", title: "Aceitação dos Termos") {
                """
                Ao criar uma conta ou utilizar o aplicativo Resumed ("App"), você declara ter lido, compreendido e concordado \
                integralmente com estes Termos de Uso ("Termos"). Se você não concordar com qualquer disposição, não utilize o App.

                O App é operado pela DME Technology ("Empresa", "nós"). Estes Termos constituem um contrato vinculante entre \
                você ("Usuário") e a Empresa.
                """
            }

            LegalSection(number: "2", title: "Descrição do Serviço") {
                """
                O Resumed é uma plataforma educacional de apoio à preparação para provas de residência médica. O App oferece:

                • Plano de estudo personalizado com inteligência artificial
                • Banco de questões comentadas de provas anteriores
                • Flashcards com repetição espaçada (ResuCards)
                • Assistente de estudo com IA (Grey)
                • Acompanhamento de desempenho e gamificação

                O App é uma ferramenta complementar de estudo. Não substitui cursos preparatórios, orientação médica \
                ou qualquer forma de ensino formal.
                """
            }

            LegalSection(number: "3", title: "Cadastro e Conta") {
                """
                Para utilizar o App, você deve criar uma conta fornecendo informações verdadeiras e atualizadas. \
                Você é o único responsável por manter a confidencialidade de suas credenciais de acesso.

                Você se compromete a:
                • Fornecer dados verdadeiros no cadastro
                • Não compartilhar sua conta com terceiros
                • Notificar imediatamente qualquer uso não autorizado
                • Manter seus dados cadastrais atualizados

                A Empresa se reserva o direito de suspender ou encerrar contas que violem estes Termos, \
                sem aviso prévio.
                """
            }

            LegalSection(number: "4", title: "Assinatura e Pagamentos") {
                """
                O App oferece funcionalidades gratuitas e um plano premium ("Resumed PRO") mediante assinatura paga.

                • Os pagamentos são processados exclusivamente pela Apple através da App Store
                • A renovação é automática, salvo cancelamento pelo Usuário com no mínimo 24 horas de antecedência \
                do término do período vigente
                • O cancelamento não gera reembolso do período já pago
                • Os preços podem ser alterados com aviso prévio de 30 dias
                • Reembolsos são regidos pela política da Apple App Store

                A Empresa não armazena dados de cartão de crédito ou informações financeiras do Usuário.
                """
            }

            LegalSection(number: "5", title: "Propriedade Intelectual") {
                """
                Todo o conteúdo do App — incluindo, mas não se limitando a, textos, questões, explicações, algoritmos, \
                design, marcas, logotipos, código-fonte e interfaces — é de propriedade exclusiva da DME Technology \
                ou de seus licenciadores, protegido pelas leis brasileiras de propriedade intelectual.

                É expressamente proibido:
                • Reproduzir, distribuir ou comercializar conteúdo do App
                • Fazer engenharia reversa, descompilar ou desmontar o App
                • Utilizar bots, scrapers ou qualquer meio automatizado de extração de dados
                • Remover avisos de direitos autorais ou marcas registradas

                Questões de provas anteriores são utilizadas com finalidade exclusivamente educacional, \
                conforme permitido pela legislação vigente.
                """
            }

            LegalSection(number: "6", title: "Uso da Inteligência Artificial") {
                """
                O App utiliza modelos de inteligência artificial para gerar explicações, planos de estudo \
                e respostas do assistente Grey.

                Importante:
                • O conteúdo gerado por IA é informativo e educacional, não constitui aconselhamento médico
                • A IA pode gerar informações imprecisas ou desatualizadas — o Usuário deve sempre conferir com fontes oficiais
                • Os dados de interação com a IA são processados para melhorar a experiência, conforme a Política de Privacidade
                • A Empresa não se responsabiliza por decisões tomadas com base exclusiva em conteúdo gerado por IA
                """
            }

            LegalSection(number: "7", title: "Limitação de Responsabilidade") {
                """
                O App é fornecido "como está" ("as is"). A Empresa não garante:
                • Aprovação em qualquer prova ou concurso
                • Disponibilidade ininterrupta do serviço
                • Ausência total de erros no conteúdo
                • Compatibilidade com todos os dispositivos

                Em nenhuma hipótese a Empresa será responsável por danos indiretos, incidentais, especiais ou \
                consequenciais decorrentes do uso ou impossibilidade de uso do App.

                A responsabilidade total da Empresa, em qualquer circunstância, está limitada ao valor pago \
                pelo Usuário nos últimos 12 meses.
                """
            }

            LegalSection(number: "8", title: "Conduta do Usuário") {
                """
                O Usuário se compromete a não:
                • Utilizar o App para fins ilegais ou não autorizados
                • Interferir na segurança ou funcionamento do App
                • Tentar acessar dados de outros usuários
                • Publicar conteúdo ofensivo, difamatório ou ilegal
                • Compartilhar conteúdo premium com não-assinantes
                • Utilizar o App de forma que prejudique outros usuários

                A violação destas regras pode resultar em suspensão ou banimento permanente, \
                sem direito a reembolso.
                """
            }

            LegalSection(number: "9", title: "Modificações dos Termos") {
                """
                A Empresa pode modificar estes Termos a qualquer momento. Alterações substanciais serão \
                comunicadas por notificação no App com no mínimo 15 dias de antecedência.

                O uso continuado do App após a entrada em vigor das alterações constitui aceitação dos novos Termos. \
                Caso discorde, você deve cessar o uso do App e solicitar a exclusão de sua conta.
                """
            }

            LegalSection(number: "10", title: "Legislação e Foro") {
                """
                Estes Termos são regidos pelas leis da República Federativa do Brasil, \
                em especial o Código de Defesa do Consumidor (Lei nº 8.078/90), o Marco Civil \
                da Internet (Lei nº 12.965/14) e a Lei Geral de Proteção de Dados (Lei nº 13.709/18).

                Fica eleito o foro da Comarca do domicílio do Usuário para dirimir quaisquer controvérsias, \
                conforme o art. 101, I, do Código de Defesa do Consumidor.
                """
            }

            LegalSection(number: "11", title: "Contato") {
                """
                Para dúvidas, sugestões ou solicitações relacionadas a estes Termos:

                • E-mail: contato@dmetechnology.com.br
                • Assunto: [Resumed] Termos de Uso
                """
            }
        }
    }

    // MARK: - Política de Privacidade

    private var privacyPolicyContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            LegalSection(number: "1", title: "Introdução") {
                """
                A DME Technology ("Empresa", "nós") leva a proteção dos seus dados pessoais a sério. \
                Esta Política de Privacidade ("Política") descreve como coletamos, usamos, armazenamos \
                e protegemos suas informações ao utilizar o aplicativo Resumed ("App").

                Esta Política está em conformidade com a Lei Geral de Proteção de Dados Pessoais \
                (LGPD — Lei nº 13.709/18) e demais normas aplicáveis.
                """
            }

            LegalSection(number: "2", title: "Dados Coletados") {
                """
                Coletamos as seguintes categorias de dados:

                Dados fornecidos por você:
                • Nome e e-mail (cadastro)
                • Prova alvo e data do exame (preferências de estudo)
                • Prioridade de matérias e meta diária

                Dados gerados pelo uso:
                • Respostas a questões e taxa de acerto por matéria
                • Progresso em flashcards e intervalos de revisão
                • Tempo de estudo e sessões de foco
                • Interações com o assistente Grey (perguntas e respostas)
                • Streak, XP e dados de gamificação

                Dados técnicos:
                • Modelo do dispositivo e versão do sistema operacional
                • Logs de erro e dados de performance do App
                • Identificadores anônimos para analytics

                Não coletamos: dados de localização, contatos, fotos, dados biométricos, \
                dados financeiros ou de saúde.
                """
            }

            LegalSection(number: "3", title: "Finalidade do Tratamento") {
                """
                Utilizamos seus dados exclusivamente para:

                • Fornecer e personalizar a experiência de estudo
                • Gerar planos de estudo com IA baseados no seu progresso
                • Calcular estatísticas de desempenho e sugerir revisões
                • Alimentar o algoritmo de repetição espaçada (SRS)
                • Enviar notificações de estudo (com seu consentimento)
                • Manter e melhorar a qualidade do App
                • Cumprir obrigações legais e regulatórias

                Base legal: execução de contrato (art. 7º, V, LGPD) e consentimento (art. 7º, I, LGPD).
                """
            }

            LegalSection(number: "4", title: "Compartilhamento de Dados") {
                """
                Seus dados podem ser compartilhados com:

                • Supabase (infraestrutura de autenticação e banco de dados) — dados de conta
                • Serviços de IA para processamento de perguntas ao Grey — dados anonimizados
                • Apple (processamento de pagamentos da assinatura) — dados de transação

                Não vendemos, alugamos ou comercializamos seus dados pessoais a terceiros. \
                Não compartilhamos dados com anunciantes.

                Todos os prestadores de serviço estão vinculados por contratos que garantem \
                a proteção dos dados conforme a LGPD.
                """
            }

            LegalSection(number: "5", title: "Armazenamento e Segurança") {
                """
                Adotamos medidas técnicas e organizacionais para proteger seus dados:

                • Criptografia em trânsito (TLS/HTTPS) em todas as comunicações
                • Autenticação segura com hash de senhas (bcrypt)
                • Dados sensíveis armazenados no servidor com criptografia em repouso
                • Dados locais no dispositivo protegidos pelo sistema de segurança do iOS
                • Acesso restrito aos dados por equipe autorizada
                • Backups criptografados com retenção limitada

                Os dados são armazenados em servidores seguros. Dados locais \
                (Core Data) permanecem no seu dispositivo e podem ser apagados a qualquer momento.
                """
            }

            LegalSection(number: "6", title: "Retenção de Dados") {
                """
                • Dados da conta: mantidos enquanto a conta estiver ativa
                • Dados de estudo: mantidos enquanto a conta existir, para preservar seu progresso
                • Dados de interação com IA: retidos por até 12 meses para melhoria do serviço
                • Dados de pagamento: conforme exigências fiscais (até 5 anos)

                Após exclusão da conta, os dados pessoais são removidos em até 30 dias, \
                exceto quando a retenção for exigida por lei.
                """
            }

            LegalSection(number: "7", title: "Seus Direitos (LGPD)") {
                """
                Conforme a LGPD, você tem direito a:

                • Confirmação da existência de tratamento de dados
                • Acesso aos seus dados pessoais
                • Correção de dados incompletos ou desatualizados
                • Anonimização, bloqueio ou eliminação de dados desnecessários
                • Portabilidade dos dados a outro fornecedor
                • Eliminação dos dados tratados com consentimento
                • Informação sobre compartilhamento com terceiros
                • Revogação do consentimento a qualquer momento

                Para exercer seus direitos, envie e-mail para privacidade@dmetechnology.com.br. \
                Responderemos em até 15 dias úteis.
                """
            }

            LegalSection(number: "8", title: "Dados de Menores") {
                """
                O App é destinado a maiores de 18 anos ou estudantes de medicina devidamente matriculados. \
                Não coletamos intencionalmente dados de menores de 18 anos.

                Caso identifiquemos que um menor forneceu dados pessoais sem o consentimento dos responsáveis, \
                os dados serão prontamente eliminados.
                """
            }

            LegalSection(number: "9", title: "Cookies e Tecnologias de Rastreamento") {
                """
                O App não utiliza cookies. Podemos utilizar identificadores anônimos para:

                • Análise de uso e métricas de performance
                • Detecção e prevenção de fraudes
                • Melhoria da experiência do usuário

                Não utilizamos rastreamento para fins publicitários. O App respeita a configuração \
                de App Tracking Transparency (ATT) do iOS.
                """
            }

            LegalSection(number: "10", title: "Alterações nesta Política") {
                """
                Esta Política pode ser atualizada periodicamente. Alterações substanciais serão \
                comunicadas por notificação no App com no mínimo 15 dias de antecedência.

                A data da última atualização está indicada no topo deste documento. \
                Recomendamos a revisão periódica desta Política.
                """
            }

            LegalSection(number: "11", title: "Encarregado de Dados (DPO)") {
                """
                Para questões relacionadas à proteção de dados pessoais:

                • E-mail: privacidade@dmetechnology.com.br
                • Assunto: [Resumed] Proteção de Dados

                Caso entenda que o tratamento dos seus dados viola a LGPD, você pode apresentar \
                reclamação à Autoridade Nacional de Proteção de Dados (ANPD).
                """
            }
        }
    }
}

// MARK: - Legal Section Component

private struct LegalSection: View {
    let number: String
    let title: String
    let content: String

    init(number: String, title: String, @LegalContentBuilder content: () -> String) {
        self.number = number
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("\(number). \(title)")
                .font(.resumed.h4)
                .foregroundColor(.resumed.gold)

            Text(content)
                .font(.resumed.bodySmall)
                .foregroundColor(.resumed.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(Spacing.md)
        .background(Color.resumed.blackSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.resumed.border, lineWidth: 1)
        )
    }
}

@resultBuilder
struct LegalContentBuilder {
    static func buildBlock(_ content: String) -> String { content }
}
