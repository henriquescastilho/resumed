# Documentação Técnica e Funcional do Projeto RESUMED

Este documento fornece um "raio-x" completo da aplicação Resumed, detalhando a estrutura de arquivos, componentes, funções principais e fluxos de usuário.

---

## 1. Visão Geral da Arquitetura

O projeto é uma aplicação **React (Vite)** escrita em **TypeScript**, focada na preparação para residência médica.

### Stack Tecnológico
- **Frontend**: React 19, TailwindCSS, Lucide React (ícones), Recharts (gráficos).
- **IA**: Integração com Google Gemini 2.5/3 via SDK.
- **Gerenciamento de Estado**: React `useState` e props drilling (centralizado no `App.tsx` para o MVP).
- **Roteamento**: Condicional simples baseado em string (`ViewState`).

---

## 2. Estrutura de Diretórios e Arquivos

### Raiz
- **`App.tsx`**: Componente raiz. Gerencia o estado global (`view`, `userStats`, `flashcards`) e renderiza a view ativa dentro do `Layout`.
- **`types.ts`**: Definições de tipos TypeScript (Interfaces para `UserProfile`, `Flashcard`, `UserStats`, `GPSItem`, etc.).
- **`constants.ts`**: Constantes globais, mocks de dados (`MOCK_FLASHCARDS`, `MOCK_GPS`, `BADGES`) e configurações de tema cores.
- **`vite.config.ts`**: Configuração do Vite, incluindo variáveis de ambiente para a API Key.

### `services/`
- **`geminiService.ts`**: Camada de comunicação com a IA.
    - `initChat()`: Inicializa a sessão com o modelo Gemini.
    - `sendMessageToGrey(message)`: Envia mensagem e retorna resposta da persona "Grey".
- **`studySystem.ts`**: Lógica de "Negócios".
    - `calculateNextReview(card, rating)`: Algoritmo SRS (Spaced Repetition System) que define a próxima data de revisão baseada na dificuldade.
    - `addXP(stats, amount)`: Gerencia gamificação, nível do usuário e XP.
    - `checkBadges(...)`: Lógica para desbloquear conquistas.

### `components/`
- **`Layout.tsx`**: Estrutura principal da UI.
    - **Sidebar (Desktop)**: Menu lateral persistente.
    - **Bottom Nav (Mobile)**: Menu inferior para telas pequenas.
    - **Theme Toggle**: Alternador claro/escuro.
- **`Common.tsx`**: Biblioteca de UI reutilizável.
    - `Button`: Botões com variantes (solid, outline, ghost).
    - `Card`: Container padrão com estilos e bordas.
    - `Input`: Campos de texto estilizados.
    - `ProgressBar`: Barra de progresso visual.
- **`Logo.tsx`**: Componente visual do logo (SVG ou Imagem).

---

## 3. Detalhamento das Views (Telas)

### 3.1 Fluxo Inicial e Autenticação
#### **`Splash` (no App.tsx)**
- **Função**: Tela de abertura animada.
- **Comportamento**: Exibe logo pulsante e redireciona automaticamente após 2.5s.

#### **`views/Onboarding.tsx`**
Wizard de configuração inicial do usuário. Divide-se em etapas:
1.  **Welcome**: Coleta o nome do usuário.
    - *Botão "Começar"*: Avança para exames.
2.  **Exams**: Seleção múltipla de provas alvo (ENAMED, Revalida, etc.).
3.  **Days**: Seleção dos dias da semana disponíveis para estudo.
4.  **Hours**: Definição da carga horária diária base.
5.  **Distribution**: Ajuste fino de horas por dia específico.
6.  **Assessment**: Autoavaliação (Pouco/Médio/Bastante conhecimento) em cada matéria base.
7.  **Processing**: Tela de "carregando" simulada ("Montando seu plano...") que salva o perfil e redireciona para a `HOME`.

#### **`views/Auth.tsx`**
Tela de Login/Cadastro alternativa.
- **Alternar Login/Cadastro**: *Botão "Não tem conta?"*.
- **Login Social**: *Botão "Entrar com Google"* (Mock visual).
- **Ação Principal**: *Botão "Entrar"* ou *"Criar Conta"*. Redireciona para `HOME` ou inicia o fluxo de `SETUP`.

#### **`views/Setup.tsx`**
Wizard alternativo focado em perfil profissional ("Calibragem").
- **Passos**: Identidade (Fase da carreira), Objetivo (Provas/Especialidade), Rotina.
- **Calibration Screen**: Animação de "IA analisando edital..." antes de liberar o acesso.

### 3.2 Funcionalidades Centrais

#### **`views/Home.tsx`** (Dashboard)
Central de navegação e resumo.
- **Header**: Exibe nome, prova alvo, e contador de *Streak* (dias seguidos).
- **Grid de Módulos**: Botões grandes para acesso rápido:
    - **GPS**: Plano inteligente.
    - **Exercícios**: Banco de questões.
    - **Redação**: Treino de escrita.
    - **ResuCards**: Flashcards.
    - **Cronograma**: Agenda.
    - **Desempenho**: Analytics.
    - **Histórico**: Log de atividades.
- **Area "Hoje"**: Card de destaque para a "Revisão Diária" pendente.

#### **`views/Grey.tsx`** (IA Chat)
Interface de chat com a IA "Grey".
- **Interface**: Lista de mensagens (User à direita, Bot à esquerda).
- **Input**: Campo de texto na parte inferior.
- **Lógica**: Ao enviar, chama `geminiService` para processar a resposta. Exibe indicador de "digitando" enquanto aguarda a API.

#### **`views/Plan.tsx`** (Meu Plano)
Visão estratégica do aluno.
- **Perfil Header**: Resumo com foto, nível (PRO), estágio e foco.
- **Estratégia Vigente**: Cards mostrando Pontos Fortes, Pontos de Atenção e Carga Horária.
- **Visão Macro**: Gráfico de barras horizontais mostrando a distribuição de horas/intensidade ao longo da semana.

#### **`views/Practice.tsx`** (Praticar)
Hub de exercícios. Possui 3 estados internos:
1.  **Menu**: Escolha entre "Banco de Questões", "Provas Anteriores" ou "ResuCards".
2.  **Config**: Configuração da sessão (Disciplinas, Quantidade de questões).
3.  **Session**: Interface de resolução de questão (Mock).
    - Exibe enunciado clínico longo.
    - Lista de alternativas (A, B, C, D).
    - *Botão "Responder"*.

#### **`views/ResuCards.tsx`** (Flashcards)
Sistema de Repetição Espaçada.
- **Lógica de Fila**: Filtra cards cuja `nextReview` é hoje ou anterior.
- **Interface do Card**:
    - **Frente**: Pergunta. Toque para virar.
    - **Verso**: Resposta.
- **Avaliação**: 4 botões de feedback (Errei, Difícil, Bom, Fácil).
    - Cada botão chama `calculateNextReview` para reagendar o card.
    - Adiciona XP ao usuário.
- **Conclusão**: Tela de parabéns com resumo de XP ganho ao terminar a fila.

### 3.3 Funcionalidades Analíticas e Sociais

#### **`views/Performance.tsx`** (Análise)
Dashboard de métricas.
- **Abas**: "Por Matéria" vs "Por Tempo".
- **Aba Matéria**:
    - **Nível XP**: Barra de progresso do nível atual.
    - **Radar Chart**: Gráfico comparativo de competência por disciplina (Clínica, Cirurgia, etc).
    - **Conquistas (Badges)**: Grid de medalhas desbloqueadas/bloqueadas.
- **Aba Tempo**:
    - **Bar Chart**: Horas estudadas por dia da semana.
    - **Eficiência**: Cards com métricas de % global e tópico mais fraco.

#### **`views/GPS.tsx`**
Navegador de tópicos prioritários.
- **Busca**: Campo de texto para filtrar temas.
- **Lista**: Cards de temas (ex: Cardiologia > Insuficiência Cardíaca).
    - Mostra frequência do tema nas provas.
    - Indicador de "Dominado" (Check verde).
    - *Botão "Testar"* para iniciar quiz rápido do tema.

#### **`views/Essay.tsx`** (Redação)
Treino de provas discursivas.
- **Lista**: Propostas de redação de anos anteriores (temas mockados).
- **Editor**: Ao selecionar um tema, abre editor de texto simples com contador de caracteres.
- **Ação**: *Botão "Enviar para Correção (IA)"* (Mock).

#### **`views/Connect.tsx`** (Comunidade)
Feed de perguntas e respostas entre usuários.
- **Filtros**: Busca por texto e botão de filtro.
- **Feed**: Lista de cards com dúvidas.
    - Exibe autor, especialidade e tempo.
    - Ações sociais: Responder, Curtir.

#### **`views/History.tsx`**
Log cronológico.
- **Filtros**: Chips (Tudo, Provas, Exercícios, Redações).
- **Lista**: Itens com ícone por tipo, data, título e resultado (nota/%).

---

## 4. Fluxos Principais

1.  **Onboarding**: `Splash` -> `Onboarding` (coleta dados) -> `Home`.
2.  **Estudo Diário**: `Home` -> Clique no Card "Hoje" -> `ResuCards`.
3.  **Tirar Dúvida**: `Home` -> `Grey` (Chatbot) -> Digita dúvida médica -> Recebe resposta.
4.  **Revisão**: `Home` -> `Performance` -> Analisa pontos fracos -> Vai para `GPS` focar no tema fraco.
