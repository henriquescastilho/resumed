# RESUMED — Relatório de Features & Roadmap

**Data:** 2026-03-18
**Gerado por:** Análise de codebase + pesquisa competitiva (Medcel, Sanar, Estratégia MED, Amboss, UWorld, Duolingo)

---

## PARTE 1: ESTADO ATUAL DO APP

### O que FUNCIONA

| Feature | Status | Detalhes |
|---------|--------|----------|
| Auth Supabase | ✅ | Email/senha, sign up com nome/telefone, auto-confirm |
| Onboarding (11 steps) | ✅ | Nome, nascimento, estado, faculdade, prova, data, horas, matérias, especialidade |
| Placement Test | ✅ | 3 fases adaptativas, resultado Forte/Médio/Fraco por matéria |
| Home Dashboard | ✅ | Saudação, stats, módulos, atividade do dia |
| Foco (Pomodoro) | ✅ | Timer ring, presets (25/45/60/90 min), contador de sessões |
| Questões (Practice) | ✅ | 1.034 questões reais (Revalida + ENAMED 2021-2025) |
| Provas Anteriores | ✅ | Browser por prova/ano, progresso, filtros |
| ResuCards (SRS) | ✅ | SM-2, flip 3D, criar/editar, filtro por matéria |
| Performance | ✅ | Level, XP, streak, acurácia por matéria, 27 badges |
| Gamificação | ✅ | XP, 5 níveis, streaks, 27 badges, level-up animation |
| Grey (UI) | ✅ | Chat completo, markdown, sugestões, limite 5/dia |
| Design System | ✅ | Gold/black theme, componentes reutilizáveis, haptics |
| Tab Bar Premium | ✅ | Blur material, Grey centralizada, pill indicator |
| Leaderboard (UI) | ✅ | Pódio, rankings, filtros período/categoria |
| Daily Challenges (UI) | ✅ | 5 desafios + featured, dificuldade, multiplicador |
| Subscription (UI) | ✅ | Paywall, 3 planos, StoreKit 2 |
| Settings | ✅ | Preferências, notificações, dados, sobre |
| Backend API | ✅ | Auth, questões, Grey, perfil, ResuCards |

### BUGS CRÍTICOS (corrigir ANTES de lançar)

| # | Bug | Impacto | Onde |
|---|-----|---------|------|
| 1 | **Logout não limpa Supabase** | Sessão persiste após logout | `SettingsView.swift` — chama só `AuthManager.signOut()` |
| 2 | **Daily Challenges quebrado** | Progresso sempre 0% | `QuestionSessionManager` não escreve nas keys do UserDefaults |
| 3 | **Limites free não aplicados** | Sem monetização | `ProFeatures` definido mas nunca verificado nas views |
| 4 | **Notificações inativas** | Toggles são cosméticos | Settings salva mas não chama `scheduleDailyReminder()` |
| 5 | **Placement Test ignorado** | Diagnóstico não afeta plano | Resultado salvo mas `StudyPlanStore` não usa |
| 6 | **Foco não salva sessões** | Tempo de estudo incorreto | `FocusSessionManager` não escreve em `CDStudySession` |
| 7 | **Links About vazios** | Risco na App Store Review | Terms, Privacy, Support com closures vazias |
| 8 | **Home stats mockados** | "1.247 questões, 78%" hardcoded | `HomeViewModel` não lê CoreData real |
| 9 | **Widget nunca atualiza** | `WidgetCenter.reloadAllTimelines()` comentado | |
| 10 | **Grey localhost only** | Não funciona em device real | Ollama em `localhost:11434` |

### LACUNAS DE CONTEÚDO

| Lacuna | Impacto | Solução |
|--------|---------|---------|
| **0 explicações nas questões** | UX muito inferior ao UWorld/Estratégia | Gerar com MedGemma + livros_ref |
| **0 flashcards pré-prontos** | Usuário começa do zero | Gerar decks por matéria com MedGemma |
| **livros_ref não integrado** | 222MB de conteúdo inacessível no app | Surfaçar no StudyDetailSheet e Grey |
| **Leaderboard 100% mock** | Feature decorativa | Backend endpoint + real rankings |

---

## PARTE 2: FEATURES RECOMENDADAS

### 🔴 URGENTE (Pré-lançamento)

| # | Feature | Por quê | Esforço |
|---|---------|---------|---------|
| 1 | **Corrigir os 10 bugs críticos** | App quebra sem isso | 1-2 dias |
| 2 | **Explicações nas questões** | Sem explicação = sem aprendizado. UWorld prova que explicação > quantidade | 3-5 dias (MedGemma batch) |
| 3 | **Enforce limites free** | Sem isso, subscription não tem valor | 1 dia |
| 4 | **Deploy Grey (backend)** | Grey é o maior diferencial, não pode ser "em desenvolvimento" | 2-3 dias |
| 5 | **Simulado cronometrado** | Table stakes — todo concorrente tem | 1-2 dias |

### 🟡 MUST-HAVE (Primeiros 30 dias)

| # | Feature | Diferencial vs Concorrência |
|---|---------|---------------------------|
| 6 | **Auto-gerar ResuCards de erros** | Errou questão → card criado automaticamente. Lecturio faz, ninguém no Brasil |
| 7 | **"Perguntar à Grey" em cada questão** | Botão na explicação que abre Grey com contexto da questão. Nenhum concorrente tem |
| 8 | **Per-specialty accuracy drill-down** | Gráficos detalhados por matéria/tema (Rafa feedback #9) |
| 9 | **GPS adaptativo real** | Plano que ajusta baseado em performance + dias até prova. Estratégia é rígido |
| 10 | **Exam countdown na Home** | "Faltam 127 dias para o ENAMED" com urgência visual |
| 11 | **Offline completo** | Questões + ResuCards funcionando sem internet |
| 12 | **Decks de ResuCards pré-prontos** | 500+ cards por matéria gerados do livros_ref |

### 🟢 DIFERENCIADORES (60-90 dias)

| # | Feature | Por quê é único |
|---|---------|----------------|
| 13 | **Grey Case Simulator** | Paciente virtual step-by-step (queixa → exame → diagnóstico → conduta). Nenhum concorrente no Brasil |
| 14 | **Gerador de mnemônicos AI** | Grey cria mnemônicos personalizados em português para conceitos difíceis |
| 15 | **Detecção de pontos fracos + micro-aulas** | MedGemma analisa erros e gera resumos de 2-3 parágrafos dos temas fracos usando livros_ref |
| 16 | **Leaderboard real** | Rankings semanais estilo Duolingo (XP da semana). Backend + social pressure |
| 17 | **Friend challenges** | "Quem acerta mais cirurgia essa semana?" — desafio entre amigos |
| 18 | **Streak freeze** | Comprar proteção de streak com XP acumulado (monetização + retenção) |
| 19 | **Study session analytics** | Pomodoro tageia sessão por matéria → analytics mostram distribuição de tempo vs performance |
| 20 | **iOS Widgets** | Streak, XP, próximo card de revisão, countdown da prova na home screen |

### 🔵 INOVADOR (Roadmap futuro)

| # | Feature | Visão |
|---|---------|-------|
| 21 | **Geração de questões AI** | MedGemma gera questões novas nos temas fracos. Complementa as 1.034 reais |
| 22 | **Treino de diagnóstico diferencial** | Dado um caso, listar diagnósticos possíveis. Grey avalia |
| 23 | **Coach de estratégia de prova** | Grey dá dicas de time management e eliminação de alternativas baseado nos simulados |
| 24 | **Voice study mode** | Grey pergunta via TTS, usuário responde por voz. Estudo hands-free |
| 25 | **Mapa de conceitos visual** | Knowledge graph mostrando conexões entre conceitos médicos |
| 26 | **Performance prediction** | "Com seu ritmo atual, sua nota estimada no ENAMED é X" (como UWorld) |
| 27 | **Study groups** | Pequenos grupos (5-10) preparando pra mesma prova, progresso compartilhado |
| 28 | **Apple Watch** | Streak counter + lembretes de revisão no pulso |

---

## PARTE 3: POSICIONAMENTO COMPETITIVO

### Mercado brasileiro (R$ 3.000-8.000/ano)

| Concorrente | Força | Fraqueza | Resumed vs |
|-------------|-------|----------|-----------|
| **Estratégia MED** | 70k questões, cronograma rígido | Caro, sem IA, sem SRS | Resumed: IA + SRS + preço acessível |
| **Sanar** | Volume de conteúdo (Netflix) | Paradoxo da escolha, IA superficial | Resumed: foco, plano inteligente |
| **Medcel** | Prestígio (professores FMUSP) | UX datada, sem gamificação | Resumed: UX premium, gamificação |
| **Medway** | Comunidade YouTube, mentoria | Banco menor, menos tech | Resumed: tecnologia + IA |

### Benchmarks globais

| App | O que copiar | O que fazer melhor |
|-----|-------------|-------------------|
| **UWorld** | Qualidade das explicações (cada questão = aula) | UX mobile superior, preço BR |
| **Amboss** | Knowledge base linkada (conceito → artigo) | Usar livros_ref como base |
| **Duolingo** | Gamificação (streaks, leagues, hearts) | Aplicar ao contexto médico |
| **Anki** | SRS algorithm (gold standard) | UX premium que Anki não tem |

### Os 3 pilares que NENHUM concorrente combina:

```
1. IA tutora médica local (Grey/MedGemma) — único no Brasil
2. SRS inteligente (ResuCards) — só Anki faz, mas com UX horrível
3. Plano adaptativo (GPS) — ninguém auto-ajusta baseado em performance
```

### Posicionamento ideal:
> **"Study copilot que complementa cursos caros"**
> Estudante compra Estratégia/Medcel pra videoaulas, usa Resumed diariamente para prática, revisão, planejamento e tutoria IA.
> Preço: R$ 50-100/mês (vs R$ 3.000-8.000/ano dos cursos)

---

## PARTE 4: PRIORIDADES IMEDIATAS

### Sprint 1 (esta semana): Corrigir bugs + Explicações
1. Fix 10 bugs críticos
2. Gerar explicações para 1.034 questões com MedGemma + livros_ref
3. Enforce limites free (paywall gates)

### Sprint 2 (próxima semana): Grey + Simulados
4. Deploy Grey (endpoint cloud para MedGemma)
5. Simulado cronometrado
6. Auto-gerar ResuCards de erros
7. "Perguntar à Grey" botão nas questões

### Sprint 3 (semana 3): Social + Polish
8. Leaderboard backend real
9. Exam countdown na Home
10. Notificações funcionando
11. iOS Widgets

### Sprint 4 (semana 4): Diferenciadores AI
12. Grey Case Simulator
13. Micro-aulas de pontos fracos
14. Gerador de mnemônicos
15. GPS adaptativo com dados reais
