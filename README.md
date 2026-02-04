# RESUMED — ENAMED MVP

**Copiloto de estudos para residência médica**, focado no ENAMED no MVP.

RESUMED é um app de **planejamento + desempenho + revisão inteligente**. Não é cursinho, não tem aulas nem simulados no MVP. É o “braço direito” do aluno para organizar, revisar e medir evolução — com IA (Grey) limitada a dúvidas médicas.

## Visão do MVP (ENAMED)
- **Foco:** ENAMED (sem pesos por área)
- **Posicionamento:** complementar aos cursinhos (não concorrente)
- **Sem aulas/simulados** no MVP

## Funcionalidades principais (produto)
- **Onboarding inteligente:** horas/dia, data e tipo de prova, especialidade(s), prioridades por área
- **Meu Plano (calendário):** tarefas diárias por área/tema/assunto, com replanejamento
- **ResuCards:** flashcards 100% do aluno, revisão espaçada (SM-2)
- **Grey (IA):** dúvidas médicas com limite diário e foco disciplinado
- **Desempenho:** análise por área, tempo de estudo e tópicos fracos
- **Provas anteriores:** ENAMED, Revalida e principais do INEP
- **Gamificação saudável:** XP, streak e foco (Pomodoro)

## Navegação do app
- **Home**
- **Meu Plano (GPS)**
- **Pergunte a Grey**
- **Meu Desempenho**
- **ResuCards**
- **Provas anteriores**

## Stack (iOS)
- **SwiftUI**
- **Firebase** (Auth/Analytics/Crashlytics)
- **Core Data** (persistência local)

## Estrutura do projeto (principal)
```
Resumed/
├── Resumed.xcodeproj
├── Resumed/
│   ├── Core/
│   ├── DesignSystem/
│   ├── Features/
│   └── Navigation/
├── ResumedTests/
└── ResumedUITests/
```

## Setup (iOS)
1. Abrir `Resumed/Resumed.xcodeproj`
2. Verificar `GoogleService-Info.plist` no target do app
3. Build: `Product > Build`

## Documentação
- **Master Plan (produto):** `docs/product/MASTER_PLAN_RESUMED.md`
- **Addendum:** `docs/product/PRD_Addendum_2026-02-04.md`
- **Stack/UX/Fluxos:** `docs/ios/`

## Status
MVP em construção. Objetivo: **ENAMED** com onboarding completo, plano personalizado, revisão de erros e desempenho por áreas.

---

© 2026 RESUMED. Todos os direitos reservados.
