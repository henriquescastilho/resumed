-- Migration 002: Seed base Topics (disciplines)
-- Safe to run multiple times — uses INSERT ... ON CONFLICT DO NOTHING.
-- These six disciplines map to the subjects found in data/questions_bank.json.

-- The topics.id column is UUID; gen_random_uuid() requires pgcrypto or pg 13+.
-- If your Postgres version is < 13, install pgcrypto: CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ensure the extension is available (no-op on pg 13+)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO topics (id, discipline, theme, subtheme)
VALUES
    (gen_random_uuid(), 'Clínica Médica',           'Clínica Médica',           NULL),
    (gen_random_uuid(), 'Cirurgia Geral',            'Cirurgia Geral',            NULL),
    (gen_random_uuid(), 'Pediatria',                 'Pediatria',                 NULL),
    (gen_random_uuid(), 'Ginecologia e Obstetrícia', 'Ginecologia e Obstetrícia', NULL),
    (gen_random_uuid(), 'Medicina Preventiva',       'Medicina Preventiva',       NULL),
    (gen_random_uuid(), 'Outras',                    'Outras',                    NULL)
ON CONFLICT DO NOTHING;

-- Verify
SELECT discipline, theme FROM topics ORDER BY discipline;
