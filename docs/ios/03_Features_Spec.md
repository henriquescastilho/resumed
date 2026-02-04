# 🎯 RESUMED iOS - Features Specification

**Especificação Detalhada de Funcionalidades**

---

## ✅ PRINCÍPIOS DO PRODUTO (NORTE)

- **Não ensinamos conteúdo.** O app **organiza** o estudo do aluno.
- **Flashcards são 100% do aluno.** Não fornecemos decks prontos.
- **Plano de estudo é 100% pessoal** e gerado pelo sistema.
- **Prioridade por matéria é configurável** pelo aluno.
- **ENAMED sem pesos:** todas as matérias contam igualmente.

---

## 📱 TELA 1: HOME

### **Objetivo:**
Dashboard central com visão do dia e acesso rápido às funcionalidades.

### **Layout (iPhone):**

```
┌─────────────────────────────────────┐
│  [Logo] RESUMED          [Avatar]   │  ← Header
├─────────────────────────────────────┤
│                                      │
│  Olá, Rafael                         │  ← Saudação
│  ENAMED • 🔥 12 dias                │  ← Prova + Streak
│                                      │
│  ┌──────────┐  ┌──────────┐        │
│  │   GPS    │  │ Exercícios│        │  ← Grid 2x3
│  │  Plano   │  │ Praticar  │        │
│  └──────────┘  └──────────┘        │
│  ┌──────────┐  ┌──────────┐        │
│  │ ResuCards│  │   Grey    │        │
│  │ Revisar  │  │  Dúvidas  │        │
│  └──────────┘  └──────────┘        │
│  ┌──────────┐  ┌──────────┐        │
│  │Desempenho│  │ Histórico │        │
│  │ Analytics│  │ Atividades│        │
│  └──────────┘  └──────────┘        │
│                                      │
│  ATIVIDADE PARA HOJE                │  ← Card destaque
│  ┌────────────────────────────────┐│
│  │ 🧠 Revisão Diária              ││
│  │ 15 ResuCards pendentes    →   ││
│  └────────────────────────────────┘│
│                                      │
└─────────────────────────────────────┘
   [Home] [Plano] [Grey] [Stats] [Cards]  ← TabBar
```

### **Componentes:**

#### **1. Header**
- Logo RESUMED (esquerda)
- Avatar do usuário (direita, clicável → Perfil)

#### **2. Saudação Personalizada**
```swift
Text("Olá, \(userName)")
    .font(.system(size: 24, weight: .black))

HStack {
    Text(targetExam)
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(.resumed.gold)

    Circle().fill(Color.resumed.border).frame(width: 4, height: 4)

    HStack(spacing: 4) {
        Image(systemName: "flame.fill")
            .foregroundColor(.resumed.gold)
        Text("\(streak) dias")
            .font(.system(size: 12, weight: .bold))
    }
}
```

#### **3. Grid de Módulos**
- 2 colunas x 3 linhas
- Cards com:
  - Ícone SF Symbol
  - Título
  - Subtítulo (descrição)
- Hover effect (scale 1.05)
- Navegação para tela correspondente

#### **4. Card "Hoje"**
- Background gradient (black → blackSec)
- Destaque visual (border dourado)
- CTA arrow (→)
- Ação: Navega para ResuCards

### **Interações:**

| Elemento | Ação | Destino |
|----------|------|---------|
| Avatar | Tap | PerfilView (modal) |
| GPS Card | Tap | PlanView (tab 2) |
| Exercícios | Tap | PracticeView (tab 6) |
| ResuCards Card | Tap | ResuCardsView (tab 5) |
| Grey Card | Tap | GreyChatView (tab 3) |
| Desempenho | Tap | PerformanceView (tab 4) |
| Histórico | Tap | HistoryView (push) |
| Card Hoje | Tap | ResuCardsView (tab 5) |

### **API Calls:**

```swift
// On appear
GET /api/v1/user/profile
GET /api/v1/user/stats  // streak, XP, level
GET /api/v1/resucards/due  // Count de cards pendentes
```

---

## 📅 TELA 2: MEU PLANO

### **Objetivo:**
Calendário semanal inteligente com tarefas personalizadas.

### **Layout (iPhone):**

```
┌─────────────────────────────────────┐
│  Meu Plano          [Editar] [Filtro]│
├─────────────────────────────────────┤
│  Semana: 12-18 Jan 2026      < >    │  ← Navegação semanal
├─────────────────────────────────────┤
│                                      │
│  SEG 12                              │
│  ┌────────────────────────────────┐│
│  │ Clínica Médica         60 min  ││  ← Área
│  │ > Cardiologia                  ││  ← Tema (expandível)
│  │   • Insuficiência Cardíaca  ✓ ││  ← Assunto
│  └────────────────────────────────┘│
│  ┌────────────────────────────────┐│
│  │ Cirurgia Geral         45 min  ││
│  │ > Trauma                       ││
│  │   • ATLS                    ○  ││  ← Não feito
│  └────────────────────────────────┘│
│                                      │
│  TER 13                              │
│  ┌────────────────────────────────┐│
│  │ Pediatria              90 min  ││
│  │ > Neonatologia                 ││
│  └────────────────────────────────┘│
│                                      │
│  [+ Adicionar Tarefa]               │
│                                      │
└─────────────────────────────────────┘
```

### **Hierarquia de Conteúdo:**

```
📅 Dia da Semana (SEG, TER, ...)
   └─ Área de Estudo (Clínica Médica, Cirurgia, etc.)
       ├─ Duração estimada (60 min)
       └─ Tema (Cardiologia, Trauma, ...)
           └─ Assunto (Insuficiência Cardíaca, ATLS, ...)
               └─ [Praticar] → Questões específicas
```

### **Prioridade por Matéria (personalizável)**
- O aluno define a **ordem de prioridade** das áreas (ex.: Clínica Médica > Pediatria > ...).
- A priorização **não altera peso de prova** quando a prova for ENAMED.
- Para ENAMED, todas as áreas contam igualmente; a ordem reflete **preferência pessoal**.

### **Componentes:**

#### **1. Navegação Semanal**
```swift
HStack {
    Button { weekOffset -= 1 } label: {
        Image(systemName: "chevron.left")
    }

    Text("Semana: \(weekDateRange)")
        .font(.system(size: 16, weight: .bold))

    Button { weekOffset += 1 } label: {
        Image(systemName: "chevron.right")
    }
}
```

#### **2. Card de Tarefa**
```swift
VStack(alignment: .leading, spacing: 8) {
    HStack {
        Text(task.area)
            .font(.system(size: 16, weight: .bold))
        Spacer()
        Text("\(task.duration) min")
            .font(.system(size: 12))
            .foregroundColor(.resumed.gray)
    }

    if task.isExpanded {
        HStack {
            Image(systemName: "chevron.right")
            Text(task.theme)
                .font(.system(size: 14))
        }

        ForEach(task.subjects) { subject in
            HStack {
                Image(systemName: subject.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subject.isDone ? .resumed.gold : .resumed.gray)
                Text(subject.name)
                Spacer()
                Button("Praticar") {
                    // Navigate to PracticeView with filter
                }
            }
        }
    }
}
.padding()
.background(Color.resumed.blackSec)
.cornerRadius(12)
.onTapGesture {
    task.isExpanded.toggle()
}
```

### **Regras de Edição:**

| Ação | Permitido? | Comportamento |
|------|-----------|---------------|
| Marcar como concluído | ✅ | Check verde, +XP |
| Arrastar para outro dia | ✅ | Alerta: "Você terá que compensar" |
| Deletar tarefa | ❌ | Apenas pode adiar |
| Trocar assunto | ✅ | Mantém área/tema |
| Cancelar semana inteira | ❌ | Tópicos vão pra Revisão |

### **API Calls:**

```swift
// On appear
GET /api/v1/plan/week?offset={weekOffset}

// Mark as done
POST /api/v1/plan/task/{id}/complete

// Drag to another day
PUT /api/v1/plan/task/{id}/reschedule
{
  "newDate": "2026-01-15"
}

// Recalculate plan
POST /api/v1/plan/regenerate
```

### **Modo de Edição:**

```
[Editar] (botão no header)
    ↓
Modo Drag & Drop ativado
    ↓
Long press em tarefa → Levanta card
    ↓
Drag para outro dia
    ↓
Drop → Modal de confirmação:
"Ao adiar, você terá que estudar mais em outro dia. Continuar?"
[Cancelar] [Confirmar]
```

---

## 💬 TELA 3: GREY (Chat IA)

### **Objetivo:**
Assistente para **tirar dúvidas** e apoiar organização do estudo, com limite diário de interações.

### **Layout (iPhone):**

```
┌─────────────────────────────────────┐
│  < Grey                    [Clear]   │
├─────────────────────────────────────┤
│                                      │
│  ┌────────────────────────┐         │
│  │ Oi! Sou a Grey 👋      │         │  ← Bot
│  │ Em que posso ajudar?   │         │
│  └────────────────────────┘         │
│                                      │
│         ┌──────────────────────────┐│
│         │ Me ajuda a organizar a   ││  ← User
│         │ semana de estudos        ││
│         └──────────────────────────┘│
│                                      │
│  ┌────────────────────────┐         │
│  │ Posso organizar sua   │         │  ← Bot
│  │ semana com base nas   │         │
│  │ suas prioridades e    │         │
│  │ tempo disponível.     │         │
│  └────────────────────────┘         │
│                                      │
│  [Sugestões rápidas]                │
│  [Organizar semana] [Rever plano]   │
│                                      │
├─────────────────────────────────────┤
│  [+] Organize meu estudo...    [→]  │  ← Input
└─────────────────────────────────────┘
```

### **Componentes:**

#### **1. Message Bubble**
```swift
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading) {
                if !message.isUser {
                    Text("Grey")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.resumed.gray)
                }

                // Markdown content
                Markdown(message.text)
                    .markdownTheme(.gitHub)
                    .padding()
                    .background(
                        message.isUser ? Color.resumed.gold : Color.resumed.blackSec
                    )
                    .foregroundColor(message.isUser ? .black : .white)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.resumed.gray)
            }

            if !message.isUser { Spacer() }
        }
    }
}
```

#### **2. Input Bar**
```swift
HStack {
    Button {
        // Attach image (future)
    } label: {
        Image(systemName: "plus.circle.fill")
    }

    TextField("Escreva sua dúvida...", text: $inputText)
        .textFieldStyle(.plain)
        .padding(12)
        .background(Color.resumed.blackSec)
        .cornerRadius(20)

    Button {
        sendMessage()
    } label: {
        Image(systemName: "arrow.up.circle.fill")
            .foregroundColor(.resumed.gold)
    }
    .disabled(inputText.isEmpty)
}
```

#### **3. Sugestões Rápidas** (Chips)
```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack {
        ForEach(suggestions) { suggestion in
            Button(suggestion.text) {
                inputText = suggestion.text
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.resumed.border)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
    }
}
```

### **Persona Grey:**

**Tom:** Acolhedor, objetivo, não robótico

**Limites:**
- ✅ Tirar dúvidas
- ✅ Organização do estudo
- ✅ Priorização de matérias
- ❌ Diagnósticos pessoais

**Auto-corte:**
```
User: "Explica insuficiência cardíaca."
Grey: "Posso te ajudar com dúvidas e a organizar seu estudo. Qual ponto você quer revisar? 📚"

### **Limite Diário de Interações**
- Limite por usuário/dia (ex.: **5 interações**).
- Ao atingir o limite:
  - Bloqueia novas mensagens até o dia seguinte
  - Sugere “Salvar dúvidas para amanhã”
- **Sem paywall no MVP** (100% gratuito).
```

### **API Calls:**

```swift
// Send message
POST /api/v1/grey/chat
{
  "message": "Explica IC descompensada",
  "conversationId": "uuid-123"
}

Response:
{
  "reply": "Insuficiência Cardíaca Descompensada é...",
  "suggestions": [
    "IC vs IC Agudizada",
    "Tratamento da IC"
  ]
}

// Clear conversation
DELETE /api/v1/grey/conversation/{id}
```

### **Features Avançadas:**

#### **1. Typing Indicator**
```swift
if viewModel.isTyping {
    HStack {
        Text("Grey está digitando")
            .foregroundColor(.resumed.gray)
        ProgressView()
            .tint(.resumed.gold)
    }
}
```

#### **2. Markdown Support**
- **Negrito:** `**texto**`
- **Itálico:** `*texto*`
- **Listas:** `- item`
- **Code:** `` `código` ``

#### **3. Context Awareness**
```swift
// Grey sabe contexto do usuário
"Considerando que você está fraco em Cardiologia..."
"Baseado nas suas últimas questões erradas..."
```

---

## 🧠 TELA 4: RESUCARDS

### **Objetivo:**
Flashcards pessoais do aluno com SRS (Spaced Repetition System).

**Regra de produto:**
- Os flashcards são **100% criados pelo aluno**.
- **Não** existem decks prontos fornecidos pelo app.

### **Layout - Vista de Cards:**

```
┌─────────────────────────────────────┐
│  ResuCards              [+ Novo]     │
├─────────────────────────────────────┤
│  📚 15 cards para revisar hoje       │
│                                      │
│  ┌────────────────────────────────┐│
│  │                                ││
│  │                                ││
│  │    Tríade de Beck?             ││  ← Frente
│  │                                ││
│  │                                ││
│  │         [Mostrar Resposta]     ││
│  └────────────────────────────────┘│
│                                      │
│  Card 1 de 15                        │
│  Próxima revisão: Hoje               │
│                                      │
└─────────────────────────────────────┘
```

### **Layout - Após Mostrar Resposta:**

```
┌─────────────────────────────────────┐
│  ┌────────────────────────────────┐│
│  │ Tríade de Beck?                ││  ← Frente
│  │                                ││
│  │ • Hipotensão                   ││  ← Verso
│  │ • Hipofonese de bulhas         ││
│  │ • Turgência jugular            ││
│  └────────────────────────────────┘│
│                                      │
│  Como você foi?                      │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐│
│  │ Errei│ │Difícil│ │ Bom │ │Fácil ││
│  │  ❌  │ │  😐  │ │  ✓  │ │ 🔥  ││
│  └──────┘ └──────┘ └──────┘ └──────┘│
│                                      │
└─────────────────────────────────────┘
```

### **Sistema SRS:**

| Avaliação | Próxima Revisão | XP Ganho |
|-----------|----------------|----------|
| **Errei** | 1 dia | +5 XP |
| **Difícil** | 3 dias | +10 XP |
| **Bom** | 7 dias | +15 XP |
| **Fácil** | 15 dias | +20 XP |

**Após atingir 30 dias:** Card vai para "Dominado" 🏆

### **Componentes:**

#### **1. Card Flip Animation**
```swift
struct FlipCardView: View {
    @State private var isFlipped = false

    var body: some View {
        ZStack {
            CardFrontView(text: card.front)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

            CardBackView(text: card.back)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6)) {
                isFlipped.toggle()
            }
        }
    }
}
```

#### **2. Rating Buttons**
```swift
HStack(spacing: 12) {
    ForEach(ratings) { rating in
        VStack {
            Text(rating.emoji)
                .font(.system(size: 32))
            Text(rating.label)
                .font(.system(size: 12))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            rating == .easy ? Color.resumed.gold : Color.resumed.blackSec
        )
        .cornerRadius(12)
        .onTapGesture {
            rateCard(rating)
        }
    }
}
```

### **API Calls:**

```swift
// Get due cards
GET /api/v1/resucards/due

// Rate card
POST /api/v1/resucards/{id}/review
{
  "rating": "good",  // fail, hard, good, easy
  "timeSpent": 12    // seconds
}

// Create new card (sempre criado pelo aluno)
POST /api/v1/resucards
{
  "front": "Tríade de Beck?",
  "back": "• Hipotensão\n• Hipofonese\n• Turgência jugular"
}
```

### **Tela de Conclusão:**

```
┌─────────────────────────────────────┐
│                                      │
│         🎉 Parabéns!                │
│                                      │
│  Você revisou 15 cards hoje!         │
│                                      │
│  +225 XP ganhos                     │
│  🔥 Streak: 13 dias                 │
│                                      │
│  [Ver Desempenho] [Voltar]          │
│                                      │
└─────────────────────────────────────┘
```

---

## 📊 TELA 5: DESEMPENHO

### **Objetivo:**
Analytics visual de performance.

### **Layout (iPhone):**

```
┌─────────────────────────────────────┐
│  Desempenho                          │
├─────────────────────────────────────┤
│  [Por Matéria] [Por Tempo]          │  ← Tabs
├─────────────────────────────────────┤
│                                      │
│  Nível 2  ⭐⭐                       │
│  1.240 / 2.000 XP                   │
│  ▓▓▓▓▓▓▓▓░░░░ 62%                  │
│                                      │
│  COMPETÊNCIA TÉCNICA                 │
│  ┌────────────────────────────────┐│
│  │      Radar Chart               ││  ← Recharts
│  │    Clínica (80%)               ││
│  │   /          \                 ││
│  │ Cirurgia    Pediatria          ││
│  │   \          /                 ││
│  │    Preventiva                  ││
│  └────────────────────────────────┘│
│                                      │
│  CONQUISTAS 🏆                      │
│  [✓] [✓] [🔒] [🔒]                 │
│                                      │
└─────────────────────────────────────┘
```

### **Gráficos:**

#### **1. Radar Chart (Competências)**
```swift
Chart(performanceData) {
    LineMark(
        x: .value("Área", $0.area),
        y: .value("Score", $0.score)
    )
    .foregroundStyle(.resumed.gold)

    AreaMark(
        x: .value("Área", $0.area),
        y: .value("Score", $0.score)
    )
    .foregroundStyle(.resumed.gold.opacity(0.3))
}
.chartYScale(domain: 0...100)
```

#### **2. Bar Chart (Horas/Semana)**
```swift
Chart(weeklyHours) {
    BarMark(
        x: .value("Dia", $0.day),
        y: .value("Horas", $0.hours)
    )
    .foregroundStyle(.resumed.gold)
    .cornerRadius(4)
}
```

### **Cards de Estatística:**

```swift
HStack {
    StatCard(
        title: "Eficiência",
        value: "82%",
        trend: "+12%",
        icon: "chart.line.uptrend.xyaxis"
    )

    StatCard(
        title: "Ponto Fraco",
        value: "Neonatologia",
        trend: "Atenção",
        icon: "exclamationmark.triangle"
    )
}
```

### **API Calls:**

```swift
GET /api/v1/performance/overview
{
  "xp": 1240,
  "level": 2,
  "streak": 12,
  "areaScores": {
    "clinica": 80,
    "cirurgia": 65,
    "pediatria": 58,
    // ...
  },
  "weeklyHours": [4, 3, 5, 2, 6, 4, 1],
  "badges": ["b1", "b2"]
}
```

---

## 📝 TELA 6: PROVAS ANTERIORES

### **Objetivo:**
Banco de questões de provas passadas.

### **Layout (iPhone):**

```
┌─────────────────────────────────────┐
│  Provas Anteriores       [Filtro]    │
├─────────────────────────────────────┤
│  [ENAMED] [Revalida] [SUS-SP] [USP] │  ← Chips
├─────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐│
│  │ ENAMED 2025                    ││
│  │ 100 questões • 4h             ││
│  │ Média: 72%                    ││
│  │                  [Iniciar] ── ││
│  └────────────────────────────────┘│
│                                      │
│  ┌────────────────────────────────┐│
│  │ Revalida 2024                  ││
│  │ 120 questões • 5h             ││
│  │ Média: 68%                    ││
│  │                  [Iniciar] ── ││
│  └────────────────────────────────┘│
│                                      │
└─────────────────────────────────────┘
```

### **Modo Prova:**

```
┌─────────────────────────────────────┐
│  ENAMED 2025 - Questão 1/100  ⏱ 3:45│
├─────────────────────────────────────┤
│                                      │
│  Paciente de 65 anos, hipertenso,   │
│  chega ao PS com dor torácica...    │  ← Enunciado
│                                      │
│  A) Infarto agudo do miocárdio ○    │
│  B) Angina instável            ○    │  ← Alternativas
│  C) Pericardite aguda          ○    │
│  D) Dissecção de aorta         ○    │
│  E) Embolia pulmonar           ○    │
│                                      │
│  [Marcar p/ Revisão] [Responder] ── │
│                                      │
└─────────────────────────────────────┘
```

### **Após Responder:**

```
┌─────────────────────────────────────┐
│  ✓ Correto! +10 XP                  │
│                                      │
│  Resposta: A) Infarto agudo         │
│                                      │
│  EXPLICAÇÃO:                         │
│  O quadro clínico sugere IAM...     │  ← Gemini
│                                      │
│  BIBLIOGRAFIA:                       │
│  • Diretriz SBC 2024               │
│                                      │
│  [Próxima Questão] ────────────────│
│                                      │
└─────────────────────────────────────┘
```

### **API Calls:**

```swift
// List exams
GET /api/v1/exams

// Start exam
POST /api/v1/exams/{id}/start

// Submit answer
POST /api/v1/exams/{id}/questions/{questionId}/answer
{
  "selectedOption": "A",
  "timeSpent": 45  // seconds
}

// Get explanation (Gemini)
GET /api/v1/questions/{id}/explanation
```

---

## 🎮 GAMIFICAÇÃO

### **Sistema de XP:**

| Ação | XP Ganho |
|------|----------|
| Questão correta | +10 XP |
| ResuCard fácil | +20 XP |
| ResuCard bom | +15 XP |
| Completar dia | +50 XP |
| Streak 7 dias | +100 XP |
| Prova completa | +200 XP |

### **Níveis:**
- **Residente Jr** (0-1.000 XP)
- **Residente Sênior** (1.000-5.000 XP)
- **Residente Master** (5.000-10.000 XP)
- **R2** (10.000+)

### **Badges:**

```swift
enum Badge: String, CaseIterable {
    case primeirosPasses = "Primeiros Passos"    // Completar onboarding
    case maratonista = "Maratonista"             // Streak 30 dias
    case sabio = "Sábio"                         // 1.000 questões
    case mestreSaude = "Mestre da Saúde"         // 90% em todas as áreas
}
```

---

## 🔔 ONBOARDING (8 Passos)

### **Fluxo:**

```
1. Welcome
   "Bem-vindo ao RESUMED! 👋"
   [Começar]

2. Nome
   "Como você se chama?"
   [TextField]

3. Prova
   "Qual prova você vai fazer?"
   [ENAMED] [Revalida] [SUS-SP] [USP]

4. Data
   "Quando é a prova?"
   [DatePicker]

5. Horas/Dia
   "Quantas horas você pode estudar por dia?"
   [Slider: 1h - 8h]

6. Prioridade de Matérias
   "Qual a ordem de prioridade?"
   [Lista reordenável: Clínica Médica, Pediatria, Cirurgia, ...]
   * Para ENAMED: sem pesos por área (ordem é preferência pessoal)

7. Especialidade Atual
   "Qual sua especialidade/fase?"
   [Interno] [Residente R1] [Generalista]

8. Processing
   "Gerando seu plano personalizado..."
   [Loading IA]
   ↓
   Navigate to Home
```

### **Persistência:**
```swift
struct OnboardingData: Codable {
    let name: String
    let targetExam: String
    let examDate: Date
    let hoursPerDay: Int
    let subjectPriority: [String]
    let specialty: String
    let completedAt: Date
}

// Save to UserDefaults
UserDefaults.standard.set(encoded: data, forKey: "onboarding")
```

---

**Total de Telas:** 6 principais + Onboarding + Perfil
**Última atualização:** 04/02/2026
