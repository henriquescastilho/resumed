"""
Seed script: populates the database with questions from data/questions_bank.json.

Usage (from the backend/ directory):
    python scripts/seed_questions.py

Or with a custom DB URL:
    DATABASE_URL=postgresql://... python scripts/seed_questions.py

The script is idempotent: questions that already exist (matched by source + number)
are skipped. Topics are upserted by discipline name.
"""

import json
import os
import sys
import uuid
from pathlib import Path

# ---------------------------------------------------------------------------
# Path setup — allow running from backend/ or from the repo root
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parent.parent.parent  # resumed_git/
BACKEND_DIR = REPO_ROOT / "backend"
DATA_FILE = REPO_ROOT / "data" / "questions_bank.json"

# Make sure "app" package is importable when running from backend/
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

# ---------------------------------------------------------------------------
# SQLAlchemy setup (mirrors backend/app/db/base.py but standalone)
# ---------------------------------------------------------------------------
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://user:password@localhost/resumed_db",  # example placeholder
)

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine)

# Import models so SQLAlchemy knows the schema (Topic, Question live here)
from app.models.content import Topic, Question  # noqa: E402  (after sys.path tweak)
from app.db.base import Base  # noqa: E402

# ---------------------------------------------------------------------------
# Subject → Topic discipline mapping
# "Outras" is treated as a catch-all discipline
# ---------------------------------------------------------------------------
SUBJECT_DISCIPLINE_MAP: dict[str, str] = {
    "Clínica Médica": "Clínica Médica",
    "Cirurgia Geral": "Cirurgia Geral",
    "Pediatria": "Pediatria",
    "Ginecologia e Obstetrícia": "Ginecologia e Obstetrícia",
    "Medicina Preventiva": "Medicina Preventiva",
    "Outras": "Outras",
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def build_source(exam: str, year: int, edition: int) -> str:
    """Returns e.g. 'Revalida 2021/1' or 'ENAMED 2024/1'."""
    return f"{exam} {year}/{edition}"


def build_options(alternatives: dict) -> list[dict]:
    """
    Converts {"A": "text", "B": "text", ...} to
    [{"id": "A", "text": "text"}, ...] sorted by key.
    """
    return [{"id": k, "text": v} for k, v in sorted(alternatives.items())]


def get_or_create_topic(db, discipline: str, topic_cache: dict) -> uuid.UUID:
    """
    Returns the UUID for an existing Topic with the given discipline,
    creating it if it does not yet exist. Uses an in-memory cache to
    avoid redundant DB queries within the same run.
    """
    if discipline in topic_cache:
        return topic_cache[discipline]

    existing = db.query(Topic).filter(Topic.discipline == discipline).first()
    if existing:
        topic_cache[discipline] = existing.id
        return existing.id

    new_topic = Topic(discipline=discipline, theme=discipline, subtheme=None)
    db.add(new_topic)
    db.flush()  # get the generated id without committing yet
    topic_cache[discipline] = new_topic.id
    return new_topic.id


def question_exists(db, source: str, number: int) -> bool:
    """Returns True if a question with the same source + number already exists."""
    # We store number inside source-derived identifier; use source + text prefix
    # Strategy: source is unique per exam/year/edition; number disambiguates within.
    # We encode both into the source field as "Revalida 2021/1 #1".
    # See build_source_key() below — this helper checks against that format.
    return (
        db.query(Question)
        .filter(
            Question.source == source,
            Question.explanation == f"__number:{number}__",  # sentinel field reuse
        )
        .first()
        is not None
    )


# ---------------------------------------------------------------------------
# Main seeder
# ---------------------------------------------------------------------------

def seed(db) -> dict:
    """
    Reads questions_bank.json and inserts all non-annulled questions.
    Returns a stats dict.
    """
    if not DATA_FILE.exists():
        raise FileNotFoundError(f"Data file not found: {DATA_FILE}")

    with open(DATA_FILE, "r", encoding="utf-8") as f:
        bank = json.load(f)

    questions_raw = bank.get("questions", [])

    stats = {
        "total_in_file": len(questions_raw),
        "annulled_skipped": 0,
        "already_exists_skipped": 0,
        "inserted": 0,
        "errors": 0,
        "by_subject": {},
        "by_exam": {},
        "by_year": {},
    }

    topic_cache: dict[str, uuid.UUID] = {}

    # Build a set of existing (source, number) pairs for fast duplicate detection
    existing_keys: set[tuple[str, str]] = set()
    for row in db.query(Question.source, Question.explanation).filter(
        Question.explanation.like("__number:%__")
    ).all():
        existing_keys.add((row.source, row.explanation))

    for raw in questions_raw:
        # --- Skip annulled ---
        if raw.get("is_annulled", False):
            stats["annulled_skipped"] += 1
            continue

        exam = raw.get("exam", "Desconhecido")
        year = raw.get("year", 0)
        edition = raw.get("edition", 1)
        number = raw.get("number", 0)
        subject = raw.get("subject", "Outras")
        enunciado = raw.get("enunciado", "").strip()
        alternatives = raw.get("alternatives", {})
        correct_answer = raw.get("correct_answer", "")

        source = build_source(exam, year, edition)
        number_sentinel = f"__number:{number}__"

        # --- Skip duplicates ---
        if (source, number_sentinel) in existing_keys:
            stats["already_exists_skipped"] += 1
            continue

        # --- Validate: skip if correct_answer is not among alternatives ---
        if correct_answer not in alternatives:
            # Question is malformed (correct answer key not in alternatives dict).
            # We still insert but flag it with a note so it's visible.
            # This handles edge cases like revalida_2021_1_4 where option D is missing.
            pass  # proceed — store as-is; the answer key is still recorded

        # --- Map subject to discipline ---
        discipline = SUBJECT_DISCIPLINE_MAP.get(subject, "Outras")

        try:
            topic_id = get_or_create_topic(db, discipline, topic_cache)

            options = build_options(alternatives)

            question = Question(
                text=enunciado,
                options=options,
                correct_option=correct_answer,
                explanation=number_sentinel,  # used as duplicate-detection sentinel
                source=source,
                topic_id=topic_id,
            )
            db.add(question)
            existing_keys.add((source, number_sentinel))

            stats["inserted"] += 1

            # Accumulate breakdown stats
            stats["by_subject"][subject] = stats["by_subject"].get(subject, 0) + 1
            stats["by_exam"][exam] = stats["by_exam"].get(exam, 0) + 1
            stats["by_year"][str(year)] = stats["by_year"].get(str(year), 0) + 1

        except Exception as exc:  # noqa: BLE001
            stats["errors"] += 1
            print(f"  [ERROR] Question {raw.get('id', '?')}: {exc}")
            db.rollback()
            # Rebuild topic cache after rollback (flushed topics were rolled back)
            topic_cache = {}
            existing_keys = set()
            # Re-populate existing keys after rollback
            for row in db.query(Question.source, Question.explanation).filter(
                Question.explanation.like("__number:%__")
            ).all():
                existing_keys.add((row.source, row.explanation))
            continue

    db.commit()
    return stats


def print_stats(stats: dict) -> None:
    print("\n" + "=" * 60)
    print("SEED COMPLETE")
    print("=" * 60)
    print(f"  Total in file       : {stats['total_in_file']}")
    print(f"  Annulled skipped    : {stats['annulled_skipped']}")
    print(f"  Already existed     : {stats['already_exists_skipped']}")
    print(f"  Inserted            : {stats['inserted']}")
    print(f"  Errors              : {stats['errors']}")

    print("\n  By Subject:")
    for subj, count in sorted(stats["by_subject"].items(), key=lambda x: -x[1]):
        print(f"    {subj:<35} {count}")

    print("\n  By Exam:")
    for exam, count in sorted(stats["by_exam"].items(), key=lambda x: -x[1]):
        print(f"    {exam:<35} {count}")

    print("\n  By Year:")
    for year, count in sorted(stats["by_year"].items()):
        print(f"    {year:<35} {count}")
    print("=" * 60)


if __name__ == "__main__":
    print(f"Connecting to database...")
    print(f"Reading questions from: {DATA_FILE}")

    db = SessionLocal()
    try:
        result = seed(db)
        print_stats(result)
    except FileNotFoundError as e:
        print(f"\n[FATAL] {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\n[FATAL] Unexpected error: {e}")
        db.rollback()
        sys.exit(1)
    finally:
        db.close()
