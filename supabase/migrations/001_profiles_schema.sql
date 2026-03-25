-- =============================================================================
-- Migration: 001_profiles_schema
-- App:       Resumed (medical residency exam prep)
-- Purpose:   Replace auth.users user_metadata storage with a proper relational
--            schema. All tables are tenant-isolated via RLS (each user sees only
--            their own rows).
-- Rollback:  See bottom of file (DROP statements, commented out).
-- =============================================================================


-- ---------------------------------------------------------------------------
-- SECTION 1: Extensions
-- ---------------------------------------------------------------------------

-- gen_random_uuid() is available in Postgres 13+ without this, but kept for
-- explicit intent and compatibility with older Supabase projects.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ---------------------------------------------------------------------------
-- SECTION 2: profiles
-- One row per auth.users entry. Created automatically via trigger.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.profiles (
    -- Primary key mirrors auth.users.id — no surrogate key needed.
    id                      uuid        NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,

    -- Identity
    full_name               text        NOT NULL,
    email                   text        NOT NULL,
    phone                   text,

    -- Location / academic context
    city                    text,
    state                   text,
    university              text,

    -- Exam preferences
    target_exam             text,               -- e.g. ENAMED, USP, UNICAMP
    exam_date               date,
    specialty               text,

    -- Study configuration
    study_hours_per_day     int         NOT NULL DEFAULT 4,
    subject_priority        text[]      NOT NULL DEFAULT '{}',

    -- Subscription
    is_pro                  boolean     NOT NULL DEFAULT false,
    pro_expires_at          timestamptz,

    -- Onboarding state
    onboarding_completed    boolean     NOT NULL DEFAULT false,

    -- Audit
    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT profiles_pkey PRIMARY KEY (id),
    CONSTRAINT profiles_study_hours_positive CHECK (study_hours_per_day >= 0),
    CONSTRAINT profiles_pro_expiry_requires_pro CHECK (
        pro_expires_at IS NULL OR is_pro = true
    )
);

COMMENT ON TABLE  public.profiles IS 'One profile per auth user. Replaces user_metadata on auth.users.';
COMMENT ON COLUMN public.profiles.target_exam IS 'Target residency exam, e.g. ENAMED, USP, UNICAMP.';
COMMENT ON COLUMN public.profiles.subject_priority IS 'Ordered list of medical subjects the user wants to prioritise.';
COMMENT ON COLUMN public.profiles.is_pro IS 'Whether the user has an active Pro subscription.';
COMMENT ON COLUMN public.profiles.pro_expires_at IS 'UTC timestamp when the Pro subscription expires; NULL if never purchased.';


-- ---------------------------------------------------------------------------
-- SECTION 3: study_progress
-- One row per user per calendar day. Aggregated daily metrics.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.study_progress (
    id                      uuid        NOT NULL DEFAULT gen_random_uuid(),
    user_id                 uuid        NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    date                    date        NOT NULL,

    -- Daily counters (all non-negative)
    xp_earned               int         NOT NULL DEFAULT 0,
    questions_answered      int         NOT NULL DEFAULT 0,
    questions_correct       int         NOT NULL DEFAULT 0,
    study_time_minutes      int         NOT NULL DEFAULT 0,
    flashcards_reviewed     int         NOT NULL DEFAULT 0,
    streak_count            int         NOT NULL DEFAULT 0,

    -- Audit
    created_at              timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT study_progress_pkey            PRIMARY KEY (id),
    CONSTRAINT study_progress_user_date_uq    UNIQUE (user_id, date),
    CONSTRAINT study_progress_xp_nn           CHECK (xp_earned >= 0),
    CONSTRAINT study_progress_q_answered_nn   CHECK (questions_answered >= 0),
    CONSTRAINT study_progress_q_correct_nn    CHECK (questions_correct >= 0),
    CONSTRAINT study_progress_correct_lte     CHECK (questions_correct <= questions_answered),
    CONSTRAINT study_progress_time_nn         CHECK (study_time_minutes >= 0),
    CONSTRAINT study_progress_flashcards_nn   CHECK (flashcards_reviewed >= 0),
    CONSTRAINT study_progress_streak_nn       CHECK (streak_count >= 0)
);

COMMENT ON TABLE  public.study_progress IS 'Daily aggregated study metrics per user. One row per (user, date).';
COMMENT ON COLUMN public.study_progress.streak_count IS 'Consecutive study days as of this date; denormalised for fast display.';


-- ---------------------------------------------------------------------------
-- SECTION 4: question_answers
-- Append-only log of every individual question attempt.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.question_answers (
    id                      uuid        NOT NULL DEFAULT gen_random_uuid(),
    user_id                 uuid        NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,

    -- Question reference (external ID from question bank)
    question_id             text        NOT NULL,
    selected_answer         text        NOT NULL,
    is_correct              boolean     NOT NULL,

    -- Classification
    subject                 text        NOT NULL,
    time_spent_seconds      int,                -- NULL if not tracked by client

    -- Audit
    answered_at             timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT question_answers_pkey               PRIMARY KEY (id),
    CONSTRAINT question_answers_time_positive      CHECK (time_spent_seconds IS NULL OR time_spent_seconds >= 0)
);

COMMENT ON TABLE  public.question_answers IS 'Append-only log of every question attempt. Never UPDATE rows; insert new attempts instead.';
COMMENT ON COLUMN public.question_answers.question_id IS 'Stable external ID from the question bank (not a FK — bank is external).';
COMMENT ON COLUMN public.question_answers.subject IS 'Medical subject tag, e.g. Cardiology, Surgery. Denormalised for fast per-subject analytics.';


-- ---------------------------------------------------------------------------
-- SECTION 5: flashcard_reviews
-- SRS (SM-2) review history. Append-only.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.flashcard_reviews (
    id                      uuid        NOT NULL DEFAULT gen_random_uuid(),
    user_id                 uuid        NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,

    -- Card reference (external ID from card bank)
    card_id                 text        NOT NULL,

    -- SM-2 parameters at the moment of review
    quality                 int         NOT NULL,   -- 0-5
    interval_days           int         NOT NULL,   -- days until next review
    ease_factor             real        NOT NULL,   -- SM-2 EF, typically 1.3-2.5
    next_review             date        NOT NULL,

    -- Audit
    reviewed_at             timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT flashcard_reviews_pkey          PRIMARY KEY (id),
    CONSTRAINT flashcard_reviews_quality_range CHECK (quality BETWEEN 0 AND 5),
    CONSTRAINT flashcard_reviews_interval_pos  CHECK (interval_days >= 0),
    CONSTRAINT flashcard_reviews_ef_range      CHECK (ease_factor >= 1.0)
);

COMMENT ON TABLE  public.flashcard_reviews IS 'SM-2 spaced-repetition review log. Append-only; latest row per card_id is the current SRS state.';
COMMENT ON COLUMN public.flashcard_reviews.quality IS 'SM-2 quality rating 0-5 (0=blackout, 5=perfect).';
COMMENT ON COLUMN public.flashcard_reviews.ease_factor IS 'SM-2 ease factor (EF). Starts at 2.5, floor 1.3.';


-- ---------------------------------------------------------------------------
-- SECTION 6: grey_conversations
-- Append-only chat history with the Grey AI assistant.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.grey_conversations (
    id                      uuid        NOT NULL DEFAULT gen_random_uuid(),
    user_id                 uuid        NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,

    role                    text        NOT NULL,   -- 'user' | 'assistant'
    content                 text        NOT NULL,

    -- Audit
    created_at              timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT grey_conversations_pkey      PRIMARY KEY (id),
    CONSTRAINT grey_conversations_role_chk  CHECK (role IN ('user', 'assistant'))
);

COMMENT ON TABLE  public.grey_conversations IS 'Append-only chat history with the Grey AI assistant (MedGemma via Ollama).';
COMMENT ON COLUMN public.grey_conversations.role IS 'Message author: "user" or "assistant".';


-- ---------------------------------------------------------------------------
-- SECTION 7: Indexes
-- Justified per expected query patterns.
-- ---------------------------------------------------------------------------

-- profiles: lookup by email (login recovery, admin search)
CREATE INDEX IF NOT EXISTS idx_profiles_email
    ON public.profiles (email);

-- study_progress: most common query is "last N days for user"
CREATE INDEX IF NOT EXISTS idx_study_progress_user_date
    ON public.study_progress (user_id, date DESC);

-- question_answers: per-user history (feed, review), per-subject analytics
CREATE INDEX IF NOT EXISTS idx_question_answers_user_answered
    ON public.question_answers (user_id, answered_at DESC);

CREATE INDEX IF NOT EXISTS idx_question_answers_user_subject
    ON public.question_answers (user_id, subject, answered_at DESC);

-- flashcard_reviews: "cards due today" query per user
CREATE INDEX IF NOT EXISTS idx_flashcard_reviews_user_next
    ON public.flashcard_reviews (user_id, next_review);

-- flashcard_reviews: latest SRS state per card (used with DISTINCT ON card_id)
CREATE INDEX IF NOT EXISTS idx_flashcard_reviews_user_card_reviewed
    ON public.flashcard_reviews (user_id, card_id, reviewed_at DESC);

-- grey_conversations: chronological chat fetch per user
CREATE INDEX IF NOT EXISTS idx_grey_conversations_user_created
    ON public.grey_conversations (user_id, created_at ASC);


-- ---------------------------------------------------------------------------
-- SECTION 8: Trigger — auto-update profiles.updated_at
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ---------------------------------------------------------------------------
-- SECTION 9: Trigger — auto-create profile on new auth.users row
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
-- Runs as the function owner (postgres), not the calling role, so it can
-- write to public.profiles even before RLS policies allow direct user writes.
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        full_name,
        email,
        phone,
        city,
        state,
        university,
        target_exam,
        exam_date,
        specialty,
        study_hours_per_day,
        subject_priority,
        is_pro,
        onboarding_completed
    ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.email, NEW.raw_user_meta_data->>'email', ''),
        NEW.raw_user_meta_data->>'phone',
        NEW.raw_user_meta_data->>'city',
        NEW.raw_user_meta_data->>'state',
        NEW.raw_user_meta_data->>'university',
        NEW.raw_user_meta_data->>'target_exam',
        (NEW.raw_user_meta_data->>'exam_date')::date,
        NEW.raw_user_meta_data->>'specialty',
        COALESCE((NEW.raw_user_meta_data->>'study_hours_per_day')::int, 4),
        '{}',
        false,
        false
    )
    ON CONFLICT (id) DO NOTHING;  -- idempotent: safe if trigger fires twice

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ---------------------------------------------------------------------------
-- SECTION 10: Row Level Security (RLS)
-- All tables: users can only read/write their own rows.
-- Service role (used by backend/edge functions) bypasses RLS by default.
-- ---------------------------------------------------------------------------

-- profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles: owner select"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "profiles: owner insert"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles: owner update"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Hard deletes on profiles are handled via auth.users CASCADE.
-- We intentionally do NOT grant a DELETE policy to users — account deletion
-- must go through auth.admin.deleteUser() to maintain referential integrity.


-- study_progress
ALTER TABLE public.study_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "study_progress: owner all"
    ON public.study_progress FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- question_answers
ALTER TABLE public.question_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "question_answers: owner all"
    ON public.question_answers FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- flashcard_reviews
ALTER TABLE public.flashcard_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flashcard_reviews: owner all"
    ON public.flashcard_reviews FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- grey_conversations
ALTER TABLE public.grey_conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "grey_conversations: owner all"
    ON public.grey_conversations FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ---------------------------------------------------------------------------
-- SECTION 11: Grant usage to authenticated role
-- anon role gets nothing. service_role bypasses RLS and needs no explicit grant.
-- ---------------------------------------------------------------------------

GRANT USAGE ON SCHEMA public TO authenticated;

GRANT SELECT, INSERT, UPDATE        ON public.profiles             TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.study_progress      TO authenticated;
GRANT SELECT, INSERT                 ON public.question_answers     TO authenticated;
GRANT SELECT, INSERT                 ON public.flashcard_reviews    TO authenticated;
GRANT SELECT, INSERT                 ON public.grey_conversations   TO authenticated;

-- question_answers and flashcard_reviews are append-only by design;
-- UPDATE/DELETE not granted to authenticated role.


-- =============================================================================
-- ROLLBACK (run manually if needed — do NOT automate):
-- =============================================================================
--
-- DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
-- DROP TRIGGER IF EXISTS trg_profiles_updated_at  ON public.profiles;
-- DROP FUNCTION IF EXISTS public.handle_new_user();
-- DROP FUNCTION IF EXISTS public.set_updated_at();
-- DROP TABLE IF EXISTS public.grey_conversations;
-- DROP TABLE IF EXISTS public.flashcard_reviews;
-- DROP TABLE IF EXISTS public.question_answers;
-- DROP TABLE IF EXISTS public.study_progress;
-- DROP TABLE IF EXISTS public.profiles;
--
-- =============================================================================
