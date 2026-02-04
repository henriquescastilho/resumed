<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
</div>

# RESUMED

**Plataforma Inteligente de Preparação para Residência Médica**

RESUMED é uma aplicação educacional que utiliza IA (Google Gemini), gamificação e metodologias comprovadas de estudo (Spaced Repetition System) para otimizar a preparação de médicos para provas de residência médica no Brasil.

---

## 🚀 Quick Start

**Pré-requisitos:** Node.js 18+, Python 3.10+

### Frontend

```bash
# Instalar dependências
npm install

# Configurar API Key
# Edite .env.local e adicione: GEMINI_API_KEY=sua_chave_aqui

# Rodar em desenvolvimento
npm run dev

# Build para produção
npm run build
```

### Backend (Opcional)

```bash
cd backend
pip install -r requirements.txt
python main.py
```

---

## 📁 Estrutura do Projeto

```
resumed_git/
├── src/                          # 💻 Código Frontend
│   ├── components/              # Componentes reutilizáveis (Layout, Common, Logo)
│   ├── views/                   # Telas principais (Home, GPS, Practice, etc.)
│   ├── services/                # Lógica de negócio (geminiService, studySystem)
│   ├── assets/                  # Recursos estáticos (imagens, logos)
│   ├── App.tsx                  # Componente raiz
│   ├── index.tsx                # Entry point
│   ├── constants.ts             # Constantes globais (cores, dados mock)
│   └── types.ts                 # Definições TypeScript
│
├── backend/                      # 🔧 API Python (FastAPI)
│   ├── app/
│   │   ├── api/routes/          # Endpoints REST
│   │   ├── models/              # Modelos de dados
│   │   ├── services/            # Serviços de negócio
│   │   └── core/                # Configurações
│   ├── main.py                  # Entry point FastAPI
│   └── requirements.txt
│
├── docs/                         # 📚 Documentação
│   ├── PRD_RESUMED_v1.0.docx    # Product Requirements Document
│   ├── end2end_1.md             # Documentação técnica end-to-end
│   ├── estrutura.txt            # Estrutura de arquivos
│   └── Checklist_Sumario_Resumed_Cirurgia_Geral.md
│
├── livros_ref/                   # 📖 Conteúdo Médico de Referência
│   ├── cirurgia_geral/          # Sabiston, Schwartz, etc.
│   ├── clinica_medica/          # Harrison, Cecil, etc.
│   ├── pediatria/               # Nelson, Rudolph, etc.
│   ├── ginecologia_obs/         # Williams, Te Linde's, etc.
│   ├── medicina_preventiva/     # Gordis, Guias SUS, etc.
│   └── five_espc/               # 5 especialidades (recorrências)
│
├── FINAIS/                       # ✅ Guias Resumed™ Finalizados
│   ├── Resumed™ Cirurgia Geral.md
│   ├── Resumed™ Clínica Médica.md
│   ├── Resumed™ Pediatria.md
│   ├── Resumed™ Ginecologia e Obstetrícia.md
│   ├── Resumed™ Medicina Preventiva.md
│   └── Resumed™ Five Espc.md
│
├── ios/                          # 📱 Mobile App (iOS)
│   └── ResumedApp/
│
├── .env.local                    # Variáveis de ambiente (GEMINI_API_KEY)
├── .gitignore
├── index.html                    # HTML principal
├── package.json                  # Dependências frontend
├── tsconfig.json                 # Configuração TypeScript
├── vite.config.ts                # Configuração Vite
└── README.md                     # Este arquivo
```

---

## 🎨 Design System

### Paleta de Cores

| Cor | HEX | Uso |
|-----|-----|-----|
| **Gold** | `#D4A54A` | Cor primária, branding, CTAs premium |
| **Black** | `#000000` | Background principal (tema escuro) |
| **Black Sec** | `#050505` | Background secundário, cards |
| **Border** | `#1F1F1F` | Bordas sutis, divisores |
| **Gray** | `#777777` | Texto secundário, ícones inativos |
| **White** | `#FFFFFF` | Texto principal, ícones ativos |

### Tipografia
- **Fonte:** Inter (via Google Fonts)
- **Tamanho base:** 16px
- **Hierarquia:** Headings bold, body regular

---

## 🧠 Funcionalidades Principais

### 1. **GPS - Guia Priorizado de Estudos**
Sistema inteligente que ranqueia tópicos por frequência em provas (escala 0-10)

### 2. **ResuCards - Flashcards SRS**
Spaced Repetition System com intervalos: 1, 3, 7, 15, 30 dias

### 3. **Grey - IA Tutora Médica**
Chatbot conversacional powered by Google Gemini 2.5/3

### 4. **Performance Analytics**
Dashboard com radar chart de competências e métricas de progresso

### 5. **Gamificação**
Sistema de XP, níveis, streak de dias e badges de conquistas

---

## 🛠️ Stack Tecnológico

**Frontend:**
- React 19
- TypeScript
- Vite
- TailwindCSS
- Lucide React (ícones)
- Recharts (gráficos)

**Backend:**
- FastAPI (Python)
- PostgreSQL
- Google Cloud Identity Platform
- Google Gemini 2.5/3

**Mobile:**
- React Native / Capacitor (iOS)

---

## 📄 Documentação

- **PRD Completo:** [`docs/PRD_RESUMED_v1.0.docx`](docs/PRD_RESUMED_v1.0.docx)
- **Documentação Técnica:** [`docs/end2end_1.md`](docs/end2end_1.md)
- **Estrutura de Arquivos:** [`docs/estrutura.txt`](docs/estrutura.txt)

---

## 🎯 Roadmap

- **MVP (Q1 2026):** Onboarding, GPS, ResuCards, Grey, Analytics
- **V1.1 (Q2 2026):** Banco de questões, simulados, redação IA
- **V2.0 (Q3 2026):** Comunidade, videoaulas, plano PRO
- **V2.1 (Q4 2026):** RAG com livros, modo offline, integração calendário

---

## 📜 Licença

© 2026 RESUMED. Todos os direitos reservados.

---

## 👥 Contato

Para mais informações, acesse: https://ai.studio/apps/drive/1zGAD9hcCDcA1XIv8aDc2FIZ6IH9j_8FK
