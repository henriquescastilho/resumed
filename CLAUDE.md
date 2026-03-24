# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Execution Policy (MANDATORY)

**Every non-trivial request MUST follow this workflow:**

1. **Plan Mode First**: Before writing ANY code, enter Plan Mode. Analyze the request, identify affected files, dependencies, risks, and acceptance criteria. Present the plan for approval.
2. **Subagent Delegation (MANDATORY)**: Once the plan is approved, delegate each workstream to the best-fit subagent. NEVER execute all work in the main thread when subagents can parallelize it.
   - Use `Explore` agents for codebase research and file discovery
   - Use `security-lead` for any security-related changes
   - Use `code-reviewer` for reviewing changes before commit
   - Use `cct-test-runner` for running tests after implementation
   - Use `frontend-ux-engineer` for UI/UX work
   - Use `backend-architect` for API and data model design
   - Use `qa-test-engineer` for test strategy and validation
3. **Verify Before Commit**: Run tests and review changes via subagent before presenting as done.

**Exceptions** (no plan needed): Single-line fixes, typo corrections, direct file reads, status checks.

## Security Policy (MANDATORY)

- **NEVER trust the frontend.** All data validation, authorization, and business logic MUST happen server-side or via Supabase RLS.
- **Supabase anon key** is public by design but REQUIRES proper RLS on every table. No table may exist without RLS enabled and policies defined.
- **service_role key** MUST NEVER appear in client code (iOS, web, or any frontend). Only in backend server-side code with proper env var injection.
- **Secrets** (.env, xcconfig with real keys, service accounts) MUST be in .gitignore and never committed.
- Before any Supabase schema change, verify RLS policies cover: SELECT, INSERT, UPDATE, DELETE for the affected table.

## Project Overview

**Resumed** is a medical residency exam preparation app (MVP targeting ENAMED). It's a study copilot — not a course — focused on planning, performance tracking, and intelligent review with an AI assistant (Grey). The product language is Brazilian Portuguese.

## Repository Structure — Three Platforms

### 1. iOS App (Primary — `Resumed/`)
The production iOS app built with **SwiftUI + Supabase + Core Data**. Open `Resumed/Resumed.xcodeproj` in Xcode.

- `Resumed/Resumed/` — Main app target
  - `Core/Models/` — Domain models: `User`, `Question`, `FlashCard`, `StudyPlan`
  - `Core/Services/` — Business logic: `AuthManager`, `APIClient`, `MockAPIClient`, `CoreDataManager`, `CoreDataStack`, `StoreKitManager`, `FocusSessionManager`, `ProgressTracker`, `ErrorReviewScheduler`, `SocialStatsManager`, `StudyPlanStore`, `SupabaseManager`, `NetworkMonitor`, `NotificationManager`
  - `Core/Gamification/` — `GamificationManager` (XP, streaks)
  - `DesignSystem/` — Reusable UI: `ResumedColors`, `ResumedTypography`, `Spacing`, `ResumedCard`, `ResumedButton`, `ResumedTextField`, `ProgressBar`, `EmptyState`
  - `Features/` — Feature modules: `Authentication`, `Home`, `Focus`, `StudyPlan`, `Questions`, `ResuCards`, `Grey`, `Performance`, `PastExams`, `DailyChallenges`, `Leaderboard`, `Settings`, `Subscription`
  - `Navigation/` — `AppState` (global state as `@ObservableObject`), `RootView` (auth/onboarding router), `TabBarView` (5 tabs: Home, Foco, Grey, ResuCard, Progresso)
- `ResumedTests/` — Unit/integration/E2E tests
- `ResumedWidget/` — iOS widget extension

**Build:** `Product > Build` in Xcode (or `xcodebuild -project Resumed/Resumed.xcodeproj -scheme Resumed build`)
**Test:** `Product > Test` in Xcode (or `xcodebuild test -project Resumed/Resumed.xcodeproj -scheme Resumed -destination 'platform=iOS Simulator,name=iPhone 16'`)

### 2. Backend API (`backend/`)
**FastAPI** app with PostgreSQL. API prefix: `/api/v1`.

- `app/core/config.py` — Settings via `pydantic-settings` (env vars: `DATABASE_URL`, `GEMINI_API_KEY`, `GOOGLE_PROJECT_ID`)
- `app/models/` — SQLAlchemy models: `user`, `content`, `rag`, `study_plan`
- `app/services/` — `auth_service`, `grey_service` (Gemini AI), `plan_service`, `srs_service` (spaced repetition)
- `app/api/routes/` — Route modules: `auth`, `grey`, `plan`, `practice`, `profile`, `resucards`

**Run:** `cd backend && uvicorn main:app --reload`
**Dependencies:** `pip install -r backend/requirements.txt`

### 3. Web Prototype (`src/`)
React + Vite + TypeScript prototype (not production). Uses Gemini API via `@google/genai`.

- `src/App.tsx` — State-based routing (no react-router)
- `src/views/` — Page components mirroring the iOS app
- `src/services/` — `geminiService.ts`, `studySystem.ts` (SM-2 algorithm)

**Run:** `npm install && npm run dev` (serves on port 3000)
**Build:** `npm run build`
**Env:** Set `GEMINI_API_KEY` in `.env.local`

### 4. Content (`livros_ref/`, `FINAIS/`)
Medical reference content in Markdown, organized by specialty (cirurgia_geral, clinica_medica, pediatria, ginecologia_obs, medicina_preventiva, five_espc). `FINAIS/` contains final published versions.

## Key Architecture Patterns (iOS)

- **Navigation:** `RootView` decides flow: unauthenticated → `LoginView`, needs onboarding → `OnboardingView`, otherwise → `TabBarView`. `AppState` is an `@EnvironmentObject` shared across the app.
- **Auth flow:** Supabase Auth (email/password). `SupabaseManager.shared` handles session, sign-in, sign-up, and token management.
- **Design system:** All colors via `Color.resumed.*` (gold/black theme). Typography via `Font.resumed.*`. Spacing via `Spacing.*` constants. Dark mode only.
- **Data persistence:** Core Data for local storage (questions, flashcards, study progress). `CoreDataStack` + `CoreDataManager` + entity extensions. Supabase for remote sync (profiles, study_progress).
- **Spaced repetition:** SM-2 algorithm for ResuCards (flashcard review scheduling).
- **Haptics:** `HapticManager.shared` used throughout for tactile feedback.

## Documentation

- `docs/product/` — Product strategy, competitive analysis, brand guidelines
- `docs/ios/` — Technical docs: overview, tech stack, UI/UX guidelines, data flow, API integration
- `SUPERPROMPT_BUILD_IOS.md` — Detailed iOS build specification
