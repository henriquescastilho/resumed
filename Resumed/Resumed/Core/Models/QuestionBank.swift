//
//  QuestionBank.swift
//  Resumed
//
//  Banco de questões inicial — 30 questões médicas reais
//  distribuídas pelas 5 áreas do ENAMED
//

import Foundation

struct QuestionBank {

    // MARK: - All Questions

    static let all: [Question] = clinicaMedica + cirurgiaGeral + pediatria + ginecologiaObstetricia + medicinaPreventiva

    static func questions(for subject: String, count: Int = 10) -> [Question] {
        let filtered = all.filter { $0.subject == subject }
        return Array(filtered.shuffled().prefix(count))
    }

    static func randomQuestions(count: Int = 10) -> [Question] {
        Array(all.shuffled().prefix(count))
    }

    // MARK: - Clínica Médica (6 questões)

    static let clinicaMedica: [Question] = [
        Question(
            id: "cm_001",
            statement: "Paciente de 62 anos, hipertenso, diabético, chega à emergência com dor precordial em aperto há 2 horas, irradiando para MSE, sudorese e náuseas. ECG mostra supradesnivelamento de ST em DII, DIII e aVF. Qual a conduta imediata mais importante?",
            options: [
                QuestionOption(id: "A", text: "Solicitar troponina e aguardar resultado"),
                QuestionOption(id: "B", text: "AAS + Clopidogrel + Heparina + encaminhar para cateterismo de urgência"),
                QuestionOption(id: "C", text: "Prescrever nitrato sublingual e observar por 6 horas"),
                QuestionOption(id: "D", text: "Solicitar ecocardiograma de urgência antes de qualquer conduta"),
                QuestionOption(id: "E", text: "Iniciar betabloqueador IV e solicitar angiotomografia")
            ],
            correctOptionId: "B",
            explanation: "IAM com supra de ST (IAMCSST) inferior exige reperfusão imediata. A conduta é dupla antiagregação (AAS + inibidor P2Y12), anticoagulação com heparina e angioplastia primária (cateterismo) em até 90 minutos. Não se deve aguardar troponina para decidir reperfusão quando há supra de ST evidente.",
            subject: "Clínica Médica",
            topic: "Cardiologia",
            difficulty: .medium,
            source: "ENAMED 2024"
        ),
        Question(
            id: "cm_002",
            statement: "Mulher de 55 anos com dispneia progressiva há 3 meses, ortopneia e edema de MMII. Ao exame: estase jugular, crepitações bibasais, hepatomegalia. BNP elevado. Ecocardiograma: FE 30%. Quais medicamentos reduzem mortalidade na IC com FE reduzida?",
            options: [
                QuestionOption(id: "A", text: "Digoxina + Furosemida + Hidralazina"),
                QuestionOption(id: "B", text: "IECA/BRA + Betabloqueador + Espironolactona + iSGLT2"),
                QuestionOption(id: "C", text: "Amiodarona + Anlodipino + AAS"),
                QuestionOption(id: "D", text: "Furosemida + Hidroclorotiazida + Verapamil"),
                QuestionOption(id: "E", text: "Dobutamina + Milrinona + Nitroprussiato")
            ],
            correctOptionId: "B",
            explanation: "O pilar do tratamento da ICFEr que reduz mortalidade inclui: IECA (ou Sacubitril/Valsartana), Betabloqueador (Carvedilol, Bisoprolol, Metoprolol), Espironolactona e iSGLT2 (Dapagliflozina, Empagliflozina). Furosemida controla sintomas mas não reduz mortalidade. Digoxina reduz internações mas não mortalidade.",
            subject: "Clínica Médica",
            topic: "Cardiologia",
            difficulty: .medium,
            source: "ENAMED 2023"
        ),
        Question(
            id: "cm_003",
            statement: "Paciente HIV+ com CD4 de 80 células/mm³ apresenta febre, tosse seca progressiva e dispneia aos esforços há 2 semanas. Radiografia de tórax mostra infiltrado intersticial bilateral. SpO₂ 88%. Qual o diagnóstico mais provável e o tratamento de escolha?",
            options: [
                QuestionOption(id: "A", text: "Tuberculose pulmonar — RIPE por 6 meses"),
                QuestionOption(id: "B", text: "Pneumocistose (PCP) — Sulfametoxazol-Trimetoprim + Corticoide"),
                QuestionOption(id: "C", text: "Pneumonia bacteriana — Ceftriaxona + Azitromicina"),
                QuestionOption(id: "D", text: "Histoplasmose — Anfotericina B"),
                QuestionOption(id: "E", text: "Sarcoma de Kaposi pulmonar — Quimioterapia")
            ],
            correctOptionId: "B",
            explanation: "PCP (Pneumocystis jirovecii) é a infecção oportunista mais comum em HIV+ com CD4 < 200. Quadro clássico: dispneia progressiva, tosse seca, hipoxemia, infiltrado intersticial bilateral difuso. Tratamento: SMX-TMP em dose alta por 21 dias. Corticoide (prednisona) se PaO₂ < 70 ou gradiente A-a > 35.",
            subject: "Clínica Médica",
            topic: "Infectologia",
            difficulty: .medium,
            source: "ENAMED 2023"
        ),
        Question(
            id: "cm_004",
            statement: "Homem de 58 anos, diabético tipo 2, com creatinina 4.2 mg/dL e TFG estimada de 15 mL/min. Apresenta hipercalemia (K+ 6.8), acidose metabólica e oligúria. Qual a conduta prioritária?",
            options: [
                QuestionOption(id: "A", text: "Iniciar bicarbonato de sódio oral e furosemida"),
                QuestionOption(id: "B", text: "Gluconato de cálcio IV + insulina regular + glicose + preparar hemodiálise"),
                QuestionOption(id: "C", text: "Resina de troca iônica (Sorcal) e aguardar resposta"),
                QuestionOption(id: "D", text: "Salbutamol inalatório e reavaliar em 4 horas"),
                QuestionOption(id: "E", text: "Restrição hídrica severa e dieta hipocalêmica")
            ],
            correctOptionId: "B",
            explanation: "Hipercalemia grave (K+ > 6.5) com IRA/DRC avançada é emergência. Conduta: 1) Gluconato de cálcio IV (cardioproteção imediata), 2) Insulina + glicose (shift K+ para intracelular), 3) Preparar diálise de urgência. Sorcal e salbutamol são adjuvantes, não tratamento definitivo.",
            subject: "Clínica Médica",
            topic: "Nefrologia",
            difficulty: .hard,
            source: "USP 2023"
        ),
        Question(
            id: "cm_005",
            statement: "Paciente de 45 anos com TSH 0.01 mUI/L, T4 livre 5.8 ng/dL, bócio difuso, exoftalmia bilateral e tremor fino de extremidades. Qual o diagnóstico e o tratamento inicial?",
            options: [
                QuestionOption(id: "A", text: "Bócio multinodular tóxico — Iodo radioativo"),
                QuestionOption(id: "B", text: "Doença de Graves — Metimazol + Betabloqueador"),
                QuestionOption(id: "C", text: "Tireoidite subaguda — AINEs"),
                QuestionOption(id: "D", text: "Adenoma tóxico — Cirurgia"),
                QuestionOption(id: "E", text: "Hashimoto em fase tireotóxica — Levotiroxina")
            ],
            correctOptionId: "B",
            explanation: "Tireotoxicose + bócio difuso + oftalmopatia = Doença de Graves (autoimune, TRAb+). Tratamento: droga antitireoidiana (Metimazol — 1ª escolha; PTU se 1º trimestre gestação) + betabloqueador (propranolol) para controle de sintomas adrenérgicos.",
            subject: "Clínica Médica",
            topic: "Endocrinologia",
            difficulty: .easy,
            source: "ENAMED 2022"
        ),
        Question(
            id: "cm_006",
            statement: "Paciente de 30 anos, sem comorbidades, apresenta Na⁺ sérico de 118 mEq/L, osmolalidade sérica de 250 mOsm/kg, osmolalidade urinária de 450 mOsm/kg, Na⁺ urinário de 55 mEq/L. Paciente euvolêmico. Qual o diagnóstico mais provável?",
            options: [
                QuestionOption(id: "A", text: "Polidipsia primária"),
                QuestionOption(id: "B", text: "Insuficiência adrenal"),
                QuestionOption(id: "C", text: "SIADH"),
                QuestionOption(id: "D", text: "Insuficiência cardíaca"),
                QuestionOption(id: "E", text: "Síndrome nefrótica")
            ],
            correctOptionId: "C",
            explanation: "SIADH: hiponatremia hipotônica + euvolemia + Osm urinária > 100 (inapropriadamente concentrada) + Na⁺ urinário > 40. Polidipsia primária teria Osm urinária < 100 (diluída). IC e nefrose cursam com hipervolemia. Insuficiência adrenal é diagnóstico de exclusão com cortisol baixo.",
            subject: "Clínica Médica",
            topic: "Nefrologia",
            difficulty: .hard,
            source: "UNICAMP 2023"
        ),
    ]

    // MARK: - Cirurgia Geral (6 questões)

    static let cirurgiaGeral: [Question] = [
        Question(
            id: "cg_001",
            statement: "Paciente de 25 anos, vítima de acidente automobilístico, chega à emergência torporoso, PA 80x50, FC 130, FR 28. Ao exame: abdome distendido e doloroso difusamente. FAST positivo. Qual a conduta?",
            options: [
                QuestionOption(id: "A", text: "Solicitar TC de abdome para estadiamento da lesão"),
                QuestionOption(id: "B", text: "Laparotomia exploradora de urgência"),
                QuestionOption(id: "C", text: "Lavagem peritoneal diagnóstica"),
                QuestionOption(id: "D", text: "Arteriografia para embolização"),
                QuestionOption(id: "E", text: "Observação com reposição volêmica por 6 horas")
            ],
            correctOptionId: "B",
            explanation: "Paciente politraumatizado com instabilidade hemodinâmica (choque classe III/IV) + FAST positivo = indicação absoluta de laparotomia exploradora de urgência. TC só é indicada em pacientes ESTÁVEIS. Não se perde tempo com exames complementares em paciente instável com FAST+.",
            subject: "Cirurgia Geral",
            topic: "Trauma",
            difficulty: .medium,
            source: "ENAMED 2024"
        ),
        Question(
            id: "cg_002",
            statement: "Homem de 35 anos com dor abdominal periumbilical há 12 horas que migrou para fossa ilíaca direita, febre 38.2°C, sinal de Blumberg positivo. Leucócitos 15.000. Qual o diagnóstico e conduta?",
            options: [
                QuestionOption(id: "A", text: "Apendicite aguda — Apendicectomia"),
                QuestionOption(id: "B", text: "Diverticulite de Meckel — TC e observação"),
                QuestionOption(id: "C", text: "Adenite mesentérica — Antibiótico e alta"),
                QuestionOption(id: "D", text: "Pielonefrite direita — Ciprofloxacino"),
                QuestionOption(id: "E", text: "Doença de Crohn — Corticoide")
            ],
            correctOptionId: "A",
            explanation: "Quadro clássico de apendicite aguda: dor periumbilical que migra para FID (cronologia de Murphy), febre, defesa e descompressão brusca positiva (Blumberg), leucocitose. Conduta: apendicectomia (videolaparoscópica ou aberta) + antibioticoprofilaxia.",
            subject: "Cirurgia Geral",
            topic: "Abdome Agudo",
            difficulty: .easy,
            source: "ENAMED 2023"
        ),
        Question(
            id: "cg_003",
            statement: "Mulher de 45 anos com dor em hipocôndrio direito após refeição gordurosa, febre 38.5°C, sinal de Murphy positivo. USG: vesícula distendida, parede espessada (6mm), cálculo impactado no infundíbulo. Qual a conduta?",
            options: [
                QuestionOption(id: "A", text: "Colecistectomia videolaparoscópica precoce (até 72h) + ATB"),
                QuestionOption(id: "B", text: "Tratamento clínico com ATB por 14 dias e cirurgia eletiva em 6 semanas"),
                QuestionOption(id: "C", text: "CPRE de urgência"),
                QuestionOption(id: "D", text: "Litotripsia extracorpórea"),
                QuestionOption(id: "E", text: "Colecistostomia percutânea")
            ],
            correctOptionId: "A",
            explanation: "Colecistite aguda litiásica = colecistectomia precoce (até 72h da admissão), preferencialmente videolaparoscópica, associada a antibioticoterapia. A cirurgia precoce tem menor morbimortalidade que a tardia. Colecistostomia é reservada para pacientes com risco cirúrgico proibitivo.",
            subject: "Cirurgia Geral",
            topic: "Vias Biliares",
            difficulty: .medium,
            source: "USP 2022"
        ),
        Question(
            id: "cg_004",
            statement: "Paciente de 70 anos com hérnia inguinal direita irredutível há 8 horas, dor intensa, hiperemia local e vômitos. Qual a classificação e conduta?",
            options: [
                QuestionOption(id: "A", text: "Hérnia encarcerada — Tentativa de redução manual e cirurgia eletiva"),
                QuestionOption(id: "B", text: "Hérnia estrangulada — Cirurgia de urgência"),
                QuestionOption(id: "C", text: "Hérnia redutível — Uso de cinta e acompanhamento"),
                QuestionOption(id: "D", text: "Hérnia de Richter — Observação clínica"),
                QuestionOption(id: "E", text: "Hérnia femoral — Redução sob sedação")
            ],
            correctOptionId: "B",
            explanation: "Hérnia irredutível + dor intensa + sinais inflamatórios locais + vômitos = estrangulamento (comprometimento vascular do conteúdo herniário). É uma emergência cirúrgica. NÃO se tenta redução manual em hérnia estrangulada pelo risco de redução em massa de alça isquêmica.",
            subject: "Cirurgia Geral",
            topic: "Hérnias",
            difficulty: .medium,
            source: "ENARE 2023"
        ),
        Question(
            id: "cg_005",
            statement: "Qual a classificação ASA de um paciente de 50 anos com DM tipo 2 controlado e HAS em uso de 2 anti-hipertensivos, sem limitação funcional?",
            options: [
                QuestionOption(id: "A", text: "ASA I"),
                QuestionOption(id: "B", text: "ASA II"),
                QuestionOption(id: "C", text: "ASA III"),
                QuestionOption(id: "D", text: "ASA IV"),
                QuestionOption(id: "E", text: "ASA V")
            ],
            correctOptionId: "B",
            explanation: "ASA II: doença sistêmica leve, sem limitação funcional. DM controlado e HAS compensada se enquadram aqui. ASA III seria doença sistêmica grave com limitação funcional (ex: DM com nefropatia, HAS refratária). ASA I é paciente saudável sem comorbidades.",
            subject: "Cirurgia Geral",
            topic: "Pré/Pós-Operatório",
            difficulty: .easy,
            source: "ENAMED 2022"
        ),
        Question(
            id: "cg_006",
            statement: "Paciente de 65 anos com abdome agudo obstrutivo. RX mostra distensão de delgado com níveis hidroaéreos em escada e ausência de gás no cólon. Qual a causa mais comum de obstrução intestinal em pacientes com cirurgia abdominal prévia?",
            options: [
                QuestionOption(id: "A", text: "Hérnia encarcerada"),
                QuestionOption(id: "B", text: "Neoplasia de cólon"),
                QuestionOption(id: "C", text: "Bridas/Aderências"),
                QuestionOption(id: "D", text: "Volvo de sigmoide"),
                QuestionOption(id: "E", text: "Intussuscepção")
            ],
            correctOptionId: "C",
            explanation: "Bridas (aderências) são a causa mais comum de obstrução de intestino delgado, especialmente em pacientes com cirurgia abdominal prévia. Em cólon, a causa mais comum é neoplasia. Volvo é mais comum em idosos e causa obstrução colônica.",
            subject: "Cirurgia Geral",
            topic: "Abdome Agudo",
            difficulty: .easy,
            source: "UNIFESP 2023"
        ),
    ]

    // MARK: - Pediatria (6 questões)

    static let pediatria: [Question] = [
        Question(
            id: "ped_001",
            statement: "RN de 38 semanas, peso 3.200g, nascido de parto cesáreo, apresenta desconforto respiratório leve nas primeiras horas de vida com taquipneia (FR 72), sem cianose. RX de tórax: hiperinsuflação, líquido cisural, linhas B de Kerley. Qual o diagnóstico?",
            options: [
                QuestionOption(id: "A", text: "Doença da Membrana Hialina"),
                QuestionOption(id: "B", text: "Taquipneia Transitória do RN"),
                QuestionOption(id: "C", text: "Síndrome de Aspiração Meconial"),
                QuestionOption(id: "D", text: "Pneumonia neonatal"),
                QuestionOption(id: "E", text: "Pneumotórax espontâneo")
            ],
            correctOptionId: "B",
            explanation: "TTRN: RN a termo, parto cesáreo (fator de risco clássico — sem compressão torácica do canal de parto), desconforto leve, RX com hiperinsuflação e líquido cisural. Autolimitada em 24-72h. DMH é de prematuros. SAM apresenta mecônio no líquido amniótico.",
            subject: "Pediatria",
            topic: "Neonatologia",
            difficulty: .medium,
            source: "ENAMED 2024"
        ),
        Question(
            id: "ped_002",
            statement: "Lactente de 2 meses deve receber quais vacinas no calendário básico do PNI?",
            options: [
                QuestionOption(id: "A", text: "BCG + Hepatite B"),
                QuestionOption(id: "B", text: "Pentavalente + VIP + Pneumo 10 + Rotavírus"),
                QuestionOption(id: "C", text: "Tríplice viral + Varicela + Hepatite A"),
                QuestionOption(id: "D", text: "Meningo C + Febre Amarela"),
                QuestionOption(id: "E", text: "DTP + VOP + Meningo ACWY")
            ],
            correctOptionId: "B",
            explanation: "Aos 2 meses: Pentavalente (DTP+HB+Hib), VIP (pólio inativada), Pneumocócica 10-valente e Rotavírus humano. BCG e Hepatite B são ao nascer. Tríplice viral é aos 12 meses. VOP (oral) é nos reforços aos 15m e 4 anos.",
            subject: "Pediatria",
            topic: "Imunizações",
            difficulty: .medium,
            source: "ENAMED 2023"
        ),
        Question(
            id: "ped_003",
            statement: "Criança de 3 anos com febre alta há 4 dias, exantema maculopapular craniocaudal, conjuntivite, coriza e tosse. Ao exame da orofaringe: manchas esbranquiçadas na mucosa jugal (manchas de Koplik). Qual o diagnóstico?",
            options: [
                QuestionOption(id: "A", text: "Rubéola"),
                QuestionOption(id: "B", text: "Sarampo"),
                QuestionOption(id: "C", text: "Escarlatina"),
                QuestionOption(id: "D", text: "Eritema infeccioso"),
                QuestionOption(id: "E", text: "Roséola")
            ],
            correctOptionId: "B",
            explanation: "Sarampo: pródromos catarrais (tosse, coriza, conjuntivite = os 3 C's), manchas de Koplik (patognomônicas — enantema na mucosa jugal) e exantema maculopapular morbiliforme craniocaudal. Rubéola tem exantema semelhante mas sem Koplik e com linfadenopatia retroauricular.",
            subject: "Pediatria",
            topic: "Infectologia Pediátrica",
            difficulty: .easy,
            source: "ENAMED 2022"
        ),
        Question(
            id: "ped_004",
            statement: "RN de 36 horas de vida apresenta icterícia até zona 3 de Kramer. Mãe O+, RN A+. Coombs direto positivo. Bilirrubina total 18 mg/dL. Qual a principal hipótese e conduta?",
            options: [
                QuestionOption(id: "A", text: "Icterícia fisiológica — Observação"),
                QuestionOption(id: "B", text: "Icterícia do leite materno — Suspender amamentação"),
                QuestionOption(id: "C", text: "Doença hemolítica por incompatibilidade ABO — Fototerapia"),
                QuestionOption(id: "D", text: "Atresia de vias biliares — Cirurgia"),
                QuestionOption(id: "E", text: "Deficiência de G6PD — Transfusão")
            ],
            correctOptionId: "C",
            explanation: "Icterícia nas primeiras 24-48h + incompatibilidade ABO (mãe O, RN A) + Coombs direto positivo = doença hemolítica. BT 18 em RN a termo indica fototerapia intensiva. Icterícia fisiológica aparece após 48-72h e tem Coombs negativo. Exsanguineotransfusão se BT ≥ 25 ou sem resposta à fototerapia.",
            subject: "Pediatria",
            topic: "Neonatologia",
            difficulty: .hard,
            source: "UNICAMP 2023"
        ),
        Question(
            id: "ped_005",
            statement: "Criança de 1 ano e 6 meses, previamente hígida, apresenta diarreia aquosa há 3 dias, vômitos e febre. Ao exame: olhos fundos, sinal da prega positivo, irritável. Peso atual 10kg. Qual o grau de desidratação e conduta?",
            options: [
                QuestionOption(id: "A", text: "Sem desidratação — Plano A (domiciliar)"),
                QuestionOption(id: "B", text: "Desidratação leve — SRO em casa"),
                QuestionOption(id: "C", text: "Desidratação moderada — Plano B (TRO supervisionada na UBS)"),
                QuestionOption(id: "D", text: "Desidratação grave — Plano C (hidratação venosa)"),
                QuestionOption(id: "E", text: "Choque hipovolêmico — SF 0,9% em bolus")
            ],
            correctOptionId: "C",
            explanation: "Dois sinais de desidratação (olhos fundos + sinal da prega + irritabilidade) sem sinais de gravidade (letargia, pulso fraco) = desidratação moderada → Plano B: TRO supervisionada na unidade de saúde por 4 horas (75 mL/kg de SRO). Plano C se houver sinais de gravidade.",
            subject: "Pediatria",
            topic: "Diarreia e Desidratação",
            difficulty: .medium,
            source: "SUS-SP 2023"
        ),
        Question(
            id: "ped_006",
            statement: "Qual o marco do DNPM esperado para uma criança de 9 meses?",
            options: [
                QuestionOption(id: "A", text: "Anda sem apoio"),
                QuestionOption(id: "B", text: "Fala frases com 2 palavras"),
                QuestionOption(id: "C", text: "Senta sem apoio e faz pinça inferior"),
                QuestionOption(id: "D", text: "Rola no leito"),
                QuestionOption(id: "E", text: "Sustenta a cabeça")
            ],
            correctOptionId: "C",
            explanation: "9 meses: senta sem apoio (desde ~6m), pinça inferior/radial, estranha desconhecidos, bissilábico (mama, papa). Rolar: 4-5m. Sustento cefálico: 3-4m. Andar sem apoio: 12-18m. Frases: ~24m.",
            subject: "Pediatria",
            topic: "Puericultura",
            difficulty: .easy,
            source: "ENAMED 2023"
        ),
    ]

    // MARK: - Ginecologia e Obstetrícia (6 questões)

    static let ginecologiaObstetricia: [Question] = [
        Question(
            id: "go_001",
            statement: "Gestante de 32 semanas com PA 160x110 mmHg, proteinúria 3+, cefaleia intensa e epigastralgia. Plaquetas 85.000, TGO 250, DHL 800, esquizócitos no esfregaço. Qual o diagnóstico e conduta?",
            options: [
                QuestionOption(id: "A", text: "Pré-eclâmpsia leve — Anti-hipertensivo oral e acompanhamento"),
                QuestionOption(id: "B", text: "Síndrome HELLP — Estabilizar e interromper a gestação"),
                QuestionOption(id: "C", text: "Hipertensão gestacional — Metildopa e pré-natal semanal"),
                QuestionOption(id: "D", text: "Eclâmpsia — Sulfato de magnésio e observação"),
                QuestionOption(id: "E", text: "PTI gestacional — Corticoide e transfusão de plaquetas")
            ],
            correctOptionId: "B",
            explanation: "HELLP: Hemólise (DHL elevado, esquizócitos), Elevated Liver enzymes (TGO elevado), Low Platelets (< 100.000). É forma grave de pré-eclâmpsia. Conduta: estabilizar com MgSO₄ (prevenção de eclâmpsia), anti-hipertensivo IV e interrupção da gestação independente da IG.",
            subject: "Ginecologia e Obstetrícia",
            topic: "Síndromes Hipertensivas",
            difficulty: .hard,
            source: "ENAMED 2024"
        ),
        Question(
            id: "go_002",
            statement: "Gestante de 28 semanas apresenta sangramento vaginal vermelho vivo, indolor, de início súbito. Útero relaxado, BCF presente. Qual o diagnóstico mais provável?",
            options: [
                QuestionOption(id: "A", text: "Descolamento prematuro de placenta"),
                QuestionOption(id: "B", text: "Placenta prévia"),
                QuestionOption(id: "C", text: "Rotura uterina"),
                QuestionOption(id: "D", text: "Vasa prévia"),
                QuestionOption(id: "E", text: "Cervicite")
            ],
            correctOptionId: "B",
            explanation: "Sangramento vermelho vivo + indolor + útero relaxado = placenta prévia (implantação sobre ou próximo ao OI). DPP: sangramento escuro + dor + hipertonia uterina. O diagnóstico é confirmado por USG. Conduta: internação, corticoide para maturação pulmonar se < 34s, interrupção se sangramento incontrolável.",
            subject: "Ginecologia e Obstetrícia",
            topic: "Sangramento na Gestação",
            difficulty: .medium,
            source: "ENAMED 2023"
        ),
        Question(
            id: "go_003",
            statement: "Mulher de 25 anos, nuligesta, procura planejamento familiar. Tem enxaqueca com aura. Qual método contraceptivo é CONTRAINDICADO?",
            options: [
                QuestionOption(id: "A", text: "DIU de cobre"),
                QuestionOption(id: "B", text: "Contraceptivo oral combinado (estrogênio + progesterona)"),
                QuestionOption(id: "C", text: "Implante subdérmico de etonogestrel"),
                QuestionOption(id: "D", text: "DIU hormonal (Mirena)"),
                QuestionOption(id: "E", text: "Minipílula (progesterona isolada)")
            ],
            correctOptionId: "B",
            explanation: "Enxaqueca com aura é contraindicação absoluta (categoria 4 OMS) para contraceptivos combinados com estrogênio, pelo risco de AVC isquêmico. Métodos apenas com progesterona (implante, Mirena, minipílula) e DIU de cobre são seguros.",
            subject: "Ginecologia e Obstetrícia",
            topic: "Contracepção",
            difficulty: .medium,
            source: "ENAMED 2022"
        ),
        Question(
            id: "go_004",
            statement: "Qual o intervalo recomendado para rastreamento de câncer de colo uterino com citologia (Papanicolau) em mulheres de 25-64 anos, após dois exames anuais normais?",
            options: [
                QuestionOption(id: "A", text: "Anual"),
                QuestionOption(id: "B", text: "A cada 3 anos"),
                QuestionOption(id: "C", text: "A cada 5 anos"),
                QuestionOption(id: "D", text: "Semestral"),
                QuestionOption(id: "E", text: "A cada 2 anos")
            ],
            correctOptionId: "B",
            explanation: "MS/INCA: rastreamento com citologia dos 25 aos 64 anos. Após dois exames anuais consecutivos normais, o intervalo passa a ser trienal (a cada 3 anos). Não há indicação de rastreamento antes dos 25 anos nem semestral.",
            subject: "Ginecologia e Obstetrícia",
            topic: "Rastreamento",
            difficulty: .easy,
            source: "ENAMED 2023"
        ),
        Question(
            id: "go_005",
            statement: "Gestante em TP com dilatação 6cm, dinâmica uterina de 3 contrações/10min e parada de progressão há 2 horas. Partograma mostra linha de ação ultrapassada. Feto cefálico, plano De Lee -1. Qual a conduta?",
            options: [
                QuestionOption(id: "A", text: "Cesárea imediata"),
                QuestionOption(id: "B", text: "Amniotomia + ocitocina"),
                QuestionOption(id: "C", text: "Fórceps de alívio"),
                QuestionOption(id: "D", text: "Aguardar mais 4 horas"),
                QuestionOption(id: "E", text: "Analgesia peridural isolada")
            ],
            correctOptionId: "B",
            explanation: "Parada de progressão na fase ativa (dilatação 6cm) com linha de ação ultrapassada = distócia. Com apresentação em plano alto (De Lee -1), a conduta é corrigir a distócia: amniotomia + ocitocina. Cesárea só se não houver resposta. Fórceps só em plano ≥ +2.",
            subject: "Ginecologia e Obstetrícia",
            topic: "Parto",
            difficulty: .hard,
            source: "UNIFESP 2023"
        ),
        Question(
            id: "go_006",
            statement: "Mulher de 52 anos, menopausada há 2 anos, procura atendimento para rastreamento de câncer de mama. Sem história familiar. Qual exame de rastreamento e periodicidade recomendados pelo MS?",
            options: [
                QuestionOption(id: "A", text: "Mamografia anual a partir dos 40 anos"),
                QuestionOption(id: "B", text: "Mamografia bienal dos 50 aos 69 anos"),
                QuestionOption(id: "C", text: "USG mamária anual"),
                QuestionOption(id: "D", text: "Ressonância magnética a cada 2 anos"),
                QuestionOption(id: "E", text: "Autoexame mensal é suficiente")
            ],
            correctOptionId: "B",
            explanation: "MS/INCA: rastreamento com mamografia bienal (a cada 2 anos) para mulheres de 50 a 69 anos, sem alto risco. SBM recomenda anual a partir dos 40, mas a recomendação oficial do MS para provas é bienal 50-69. Alto risco (mutação BRCA, história familiar) antecipa e intensifica o rastreamento.",
            subject: "Ginecologia e Obstetrícia",
            topic: "Rastreamento",
            difficulty: .medium,
            source: "SUS-SP 2023"
        ),
    ]

    // MARK: - Medicina Preventiva (6 questões)

    static let medicinaPreventiva: [Question] = [
        Question(
            id: "mp_001",
            statement: "Um teste diagnóstico tem sensibilidade de 95% e especificidade de 80%. Em uma população com prevalência de 10% para a doença, qual o valor preditivo positivo aproximado?",
            options: [
                QuestionOption(id: "A", text: "95%"),
                QuestionOption(id: "B", text: "80%"),
                QuestionOption(id: "C", text: "35%"),
                QuestionOption(id: "D", text: "50%"),
                QuestionOption(id: "E", text: "68%")
            ],
            correctOptionId: "C",
            explanation: "VPP = (S × P) / [(S × P) + ((1-E) × (1-P))]. Com S=0.95, E=0.80, P=0.10: VPP = (0.95×0.10) / [(0.95×0.10) + (0.20×0.90)] = 0.095 / (0.095+0.180) = 0.095/0.275 ≈ 34.5%. Prevalência baixa reduz drasticamente o VPP mesmo com boa sensibilidade.",
            subject: "Medicina Preventiva",
            topic: "Bioestatística",
            difficulty: .hard,
            source: "ENAMED 2024"
        ),
        Question(
            id: "mp_002",
            statement: "Um pesquisador quer estudar a associação entre tabagismo e câncer de pulmão. Seleciona 200 pacientes com câncer de pulmão e 200 sem, e investiga exposição prévia ao tabaco. Qual o tipo de estudo?",
            options: [
                QuestionOption(id: "A", text: "Coorte prospectivo"),
                QuestionOption(id: "B", text: "Caso-controle"),
                QuestionOption(id: "C", text: "Ensaio clínico randomizado"),
                QuestionOption(id: "D", text: "Ecológico"),
                QuestionOption(id: "E", text: "Transversal")
            ],
            correctOptionId: "B",
            explanation: "Caso-controle: parte do DESFECHO (doença) e investiga a EXPOSIÇÃO pregressa. Seleciona-se um grupo com a doença (casos) e outro sem (controles) e compara-se a frequência de exposição. Medida de associação: Odds Ratio. É retrospectivo, rápido e barato. Ideal para doenças raras.",
            subject: "Medicina Preventiva",
            topic: "Epidemiologia",
            difficulty: .easy,
            source: "ENAMED 2023"
        ),
        Question(
            id: "mp_003",
            statement: "Quais são os princípios doutrinários do SUS estabelecidos pela Constituição Federal de 1988?",
            options: [
                QuestionOption(id: "A", text: "Descentralização, Regionalização e Hierarquização"),
                QuestionOption(id: "B", text: "Universalidade, Integralidade e Equidade"),
                QuestionOption(id: "C", text: "Participação Social, Complementaridade e Resolutividade"),
                QuestionOption(id: "D", text: "Acessibilidade, Longitudinalidade e Coordenação do cuidado"),
                QuestionOption(id: "E", text: "Intersetorialidade, Eficiência e Eficácia")
            ],
            correctOptionId: "B",
            explanation: "Princípios DOUTRINÁRIOS do SUS: Universalidade (acesso para todos), Integralidade (atenção completa — promoção, prevenção, tratamento, reabilitação) e Equidade (tratar desigualmente os desiguais). Descentralização, regionalização e hierarquização são princípios ORGANIZATIVOS. Atributos da APS (Starfield) são universalidade, integralidade, longitudinalidade e coordenação.",
            subject: "Medicina Preventiva",
            topic: "SUS",
            difficulty: .easy,
            source: "ENAMED 2022"
        ),
        Question(
            id: "mp_004",
            statement: "A notificação compulsória de casos de dengue deve ser feita em qual prazo, segundo a Portaria de Consolidação nº 4/2017?",
            options: [
                QuestionOption(id: "A", text: "Imediata (até 24 horas)"),
                QuestionOption(id: "B", text: "Semanal"),
                QuestionOption(id: "C", text: "Mensal"),
                QuestionOption(id: "D", text: "Apenas em caso de óbito"),
                QuestionOption(id: "E", text: "Não é de notificação compulsória")
            ],
            correctOptionId: "B",
            explanation: "Dengue é de notificação compulsória SEMANAL. Notificação IMEDIATA (24h): dengue com óbito, surtos, formas graves. Outras doenças de notificação imediata: cólera, febre amarela, sarampo, raiva humana, meningite meningocócica, botulismo.",
            subject: "Medicina Preventiva",
            topic: "Vigilância",
            difficulty: .medium,
            source: "SUS-SP 2023"
        ),
        Question(
            id: "mp_005",
            statement: "Na Estratégia Saúde da Família, qual o número máximo de pessoas recomendado para uma equipe de Saúde da Família (eSF), segundo a PNAB 2017?",
            options: [
                QuestionOption(id: "A", text: "2.000 pessoas"),
                QuestionOption(id: "B", text: "2.000 a 3.500 pessoas"),
                QuestionOption(id: "C", text: "5.000 pessoas"),
                QuestionOption(id: "D", text: "1.000 famílias"),
                QuestionOption(id: "E", text: "Não há limite definido")
            ],
            correctOptionId: "B",
            explanation: "PNAB 2017: cada eSF é responsável por 2.000 a 3.500 pessoas (ideal 3.000), em território definido. Composição mínima: médico, enfermeiro, auxiliar/técnico de enfermagem e ACS. O número de ACS deve cobrir 100% da população da área.",
            subject: "Medicina Preventiva",
            topic: "APS/ESF",
            difficulty: .medium,
            source: "ENAMED 2023"
        ),
        Question(
            id: "mp_006",
            statement: "Em um estudo, o Risco Relativo de desenvolver câncer de pulmão em fumantes versus não-fumantes é 10. O que isso significa?",
            options: [
                QuestionOption(id: "A", text: "10% dos fumantes terão câncer de pulmão"),
                QuestionOption(id: "B", text: "Fumantes têm 10 vezes mais chance de desenvolver câncer de pulmão que não-fumantes"),
                QuestionOption(id: "C", text: "A prevalência de câncer de pulmão é 10% na população"),
                QuestionOption(id: "D", text: "O NNT para prevenir um caso é 10"),
                QuestionOption(id: "E", text: "A especificidade do tabagismo como fator de risco é 10%")
            ],
            correctOptionId: "B",
            explanation: "RR = 10 significa que a incidência da doença nos expostos é 10 vezes maior que nos não-expostos. RR > 1 = fator de risco. RR = 1 = sem associação. RR < 1 = fator de proteção. O RR é a medida de associação dos estudos de COORTE.",
            subject: "Medicina Preventiva",
            topic: "Epidemiologia",
            difficulty: .easy,
            source: "ENARE 2023"
        ),
    ]
}
