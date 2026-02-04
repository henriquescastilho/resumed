# 📱 RESUMED iOS - Overview

**App Nativo para iPhone e iPad**
**Target:** iOS 16+ | Swift 5 | SwiftUI 4

---

## 🎯 Visão Geral

RESUMED é um **copiloto IA para aprovação em residência médica**, disponível nativamente para iPhone e iPad.

### **Plataformas Suportadas:**
- ✅ **iPhone** (iOS 16+) - Foco primário
- ✅ **iPad** (iPadOS 16+) - Layout adaptativo
- ❌ Apple Watch (futuro)
- ❌ macOS (futuro via Catalyst)

---

## 🏗️ Arquitetura do App

### **Padrão Arquitetural: MVVM**

```
┌─────────────────────────────────────────────┐
│              RESUMED iOS APP                 │
├─────────────────────────────────────────────┤
│                                              │
│  ┌──────────────────────────────────────┐  │
│  │         Views (SwiftUI)               │  │
│  │  • HomeView                           │  │
│  │  • PlanView                           │  │
│  │  • GreyChatView                       │  │
│  │  • ResuCardsView                      │  │
│  │  • PerformanceView                    │  │
│  │  • PracticeView                       │  │
│  └──────────────┬───────────────────────┘  │
│                 │ Binding                   │
│  ┌──────────────▼───────────────────────┐  │
│  │    ViewModels (ObservableObject)     │  │
│  │  • PlanViewModel                      │  │
│  │  • GreyChatViewModel                  │  │
│  │  • UserViewModel                      │  │
│  └──────────────┬───────────────────────┘  │
│                 │ Async/Await               │
│  ┌──────────────▼───────────────────────┐  │
│  │         Services                      │  │
│  │  • AuthService                        │  │
│  │  • APIClient                          │  │
│  │  • LocalStorageService                │  │
│  └──────────────┬───────────────────────┘  │
│                 │                           │
│  ┌──────────────▼───────────────────────┐  │
│  │         Core                          │  │
│  │  • SessionManager                     │  │
│  │  • KeychainHelper                     │  │
│  └──────────────────────────────────────┘  │
│                                              │
└─────────────────────────────────────────────┘
         │                     │
         ▼                     ▼
  ┌────────────┐      ┌──────────────┐
  │  Backend   │      │ Core Data    │
  │  (FastAPI) │      │ (Local DB)   │
  └────────────┘      └──────────────┘
```

---

## 📂 Estrutura de Pastas (Atual)

```swift
ResumedApp/
├── App/
│   └── ResumedApp.swift          // Entry point (@main)
│
├── Core/
│   ├── APIClient.swift           // Networking layer
│   ├── SessionManager.swift      // Auth & session
│   └── KeychainHelper.swift      // Secure storage
│
├── Models/
│   └── Models.swift              // Data models
│
├── Views/
│   ├── ContentView.swift         // Tab container
│   ├── LoginView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Plan/
│   │   └── PlanView.swift
│   ├── Grey/
│   │   └── GreyChatView.swift
│   ├── ResuCards/
│   │   └── ResuCardsView.swift
│   ├── Practice/
│   │   └── PracticeView.swift
│   └── Onboarding/
│       ├── OnboardingContainerView.swift
│       └── OnboardingStepViews.swift
│
├── ViewModels/
│   ├── PlanViewModel.swift
│   └── GreyChatViewModel.swift
│
└── Services/
    └── AuthService.swift
```

---

## 🎨 Design System (iOS Native)

### **Paleta de Cores (adaptada para iOS)**

```swift
extension Color {
    static let resumed = ResumedColors()
}

struct ResumedColors {
    let gold = Color(hex: "D4A54A")      // Primary
    let black = Color(hex: "000000")     // Background
    let blackSec = Color(hex: "050505")  // Cards
    let border = Color(hex: "1F1F1F")    // Dividers
    let gray = Color(hex: "777777")      // Secondary text
    let white = Color(hex: "FFFFFF")     // Primary text
}
```

### **Tipografia (SF Pro)**

```swift
// Usa sistema SF Pro (nativo iOS)
.font(.system(size: 16, weight: .regular))  // Body
.font(.system(size: 20, weight: .bold))     // H3
.font(.system(size: 24, weight: .bold))     // H2
.font(.system(size: 32, weight: .black))    // H1
```

### **Componentes Reutilizáveis**

- `ResumedCard` - Cards com border dourado
- `GoldButton` - Botão primário (fundo dourado)
- `OutlineButton` - Botão secundário (border)
- `StatCard` - Card de estatística
- `ProgressRing` - Anel de progresso circular

---

## 🔐 Autenticação e Sessão

### **Fluxo de Auth:**

```
App Launch
    ↓
SessionManager.checkSession()
    ↓
┌─────────────────┐
│ Token válido?   │
└─────────────────┘
    ↓          ↓
  SIM         NÃO
    ↓          ↓
  Home    LoginView
            ↓
    Google Sign-In (Firebase Auth)
            ↓
    Recebe ID Token
            ↓
    POST /api/v1/auth/google
            ↓
    Recebe JWT + Refresh Token
            ↓
    Salva no Keychain
            ↓
    Navigate to Home
```

### **Persistência:**
- **Keychain:** Tokens (JWT, Refresh)
- **UserDefaults:** Preferências (theme, etc)
- **Core Data:** Offline data (ResuCards, planos)

---

## 📡 Networking

### **API Client (async/await)**

```swift
class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://api.resumed.app"

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws -> T {
        // Implementation...
    }
}
```

### **Endpoints Principais:**

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/api/v1/auth/google` | POST | Login com Google |
| `/api/v1/plan/generate` | POST | Gera plano personalizado |
| `/api/v1/plan/update` | PUT | Atualiza plano |
| `/api/v1/grey/chat` | POST | Chat com IA Grey |
| `/api/v1/questions` | GET | Lista questões |
| `/api/v1/resucards` | GET/POST | Flashcards |
| `/api/v1/performance` | GET | Analytics |

---

## 🎮 Navegação

### **Tab Bar (6 Tabs)**

```swift
TabView {
    HomeView()
        .tabItem { Label("Home", systemImage: "house.fill") }

    PlanView()
        .tabItem { Label("Meu Plano", systemImage: "calendar") }

    GreyChatView()
        .tabItem { Label("Grey", systemImage: "message.fill") }

    PerformanceView()
        .tabItem { Label("Desempenho", systemImage: "chart.bar.fill") }

    ResuCardsView()
        .tabItem { Label("ResuCards", systemImage: "brain.head.profile") }

    PracticeView()
        .tabItem { Label("Provas", systemImage: "doc.text.fill") }
}
.accentColor(.resumed.gold)
```

---

## 💾 Offline Support

### **Core Data Stack:**

```swift
Entities:
├── UserProfile
├── StudyPlan
├── ResuCard
├── Question
└── PerformanceRecord
```

### **Sync Strategy:**
1. **Download on login:** Plano + questões recentes
2. **Background sync:** A cada 1 hora (se tiver rede)
3. **Manual sync:** Pull-to-refresh
4. **Conflict resolution:** Server wins (last-write)

---

## 🔔 Notificações

### **Tipos:**

1. **Lembrete Diário** (8h AM)
   - "Bom dia! Você tem 15 ResuCards para revisar hoje 🧠"

2. **Streak em Risco** (8h PM)
   - "Seu streak de 12 dias está em risco! Estude por 10 min 🔥"

3. **Revisão Espaçada** (custom)
   - "Hora de revisar: Insuficiência Cardíaca 📚"

4. **Conquista Desbloqueada**
   - "🏆 Você desbloqueou o badge Maratonista!"

---

## 📊 Analytics (Local)

### **Tracking:**
- ✅ Tempo de uso por tela
- ✅ Questões respondidas/dia
- ✅ Accuracy por área
- ✅ Streak de dias
- ✅ XP ganho

### **Framework:** Apple Analytics (nativo, sem 3rd party)

---

## 🚀 Features Exclusivas iOS

### **1. Widgets (iOS 16+)**
- Widget pequeno: Streak + XP
- Widget médio: Próximas revisões
- Widget grande: Performance semanal

### **2. Live Activities (iOS 16+)**
- Timer de estudo (Pomodoro)
- Progresso de simulado

### **3. Siri Shortcuts**
- "Hey Siri, revisar ResuCards"
- "Hey Siri, meu progresso no RESUMED"

### **4. Handoff (iPhone ↔ iPad)**
- Continua estudo entre dispositivos

### **5. Adaptive Layout**
- iPhone: Vertical scroll
- iPad: Split view (lista + detalhes)

---

## 🔒 Privacidade e Segurança

### **Compliance:**
- ✅ LGPD (dados no Brasil)
- ✅ Apple App Store Guidelines
- ✅ Sem tracking sem consentimento

### **Dados Sensíveis:**
- ❌ Não coletamos: CPF, RG, dados bancários
- ✅ Coletamos: Email, nome, performance de estudo
- 🔐 Criptografia: AES-256 (dados locais) + TLS 1.3 (rede)

---

## 📝 Próximos Passos

- [ ] Implementar onboarding completo
- [ ] Integrar API backend (FastAPI)
- [ ] Desenvolver "Meu Plano" (core feature)
- [ ] Adicionar suporte offline robusto
- [ ] Testes em iPhone 12, 14, 15 Pro
- [ ] Testes em iPad Air, iPad Pro
- [ ] Submissão para TestFlight
- [ ] Review da App Store

---

**Versão:** 1.0.0
**Target:** iOS 16+
**Linguagem:** Swift 5
**Framework:** SwiftUI 4
