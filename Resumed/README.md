# RESUMED

<p align="center">
  <img src="docs/resumed-logo.png" alt="Resumed logo" width="220" />
</p>

**Resumed** é um app iOS para preparação de residência médica com foco em ENAMED. O objetivo é ser o braço direito do estudante: planejamento personalizado, foco diário, ResuCards e acompanhamento de progresso.

## Visão rápida
- **Meu Plano (GPS):** cronograma personalizado com mínimo semanal por área.
- **Foco (Pomodoro):** sessões com XP, streak e rede de neurônios.
- **ResuCards:** flashcards criados pelo estudante, com categorias e revisão.
- **Provas anteriores:** simulado por **timer** (sem questões), com resultado manual.
- **Grey:** tira‑dúvidas médico (limite diário saudável).

## Rodar local
```bash
xcodebuild -project Resumed/Resumed.xcodeproj -scheme Resumed -configuration Debug build
```

## Estrutura
- `Resumed/Resumed/Features` — telas e fluxos
- `Resumed/Resumed/Core` — serviços, modelos e managers
- `Resumed/Resumed/DesignSystem` — componentes visuais

## Branding
Logo oficial em `docs/resumed-logo.png` e `Assets.xcassets/ResumedLogo.imageset`.
