#!/usr/bin/env python3
"""
generate_explanations.py
Generates structured explanations for Resumed question bank using MedGemma (Ollama).

Usage:
    python generate_explanations.py                  # Process all questions
    python generate_explanations.py --dry-run        # Test with 5 questions
    python generate_explanations.py --resume         # Continue from last checkpoint
    python generate_explanations.py --dry-run --resume  # Resume dry-run
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path

try:
    import requests
except ImportError:
    print("ERROR: 'requests' package required. Install with: pip install requests")
    sys.exit(1)

# --- Configuration ---
SCRIPT_DIR = Path(__file__).resolve().parent
DATA_DIR = SCRIPT_DIR.parent
QUESTIONS_FILE = DATA_DIR / "questions_bank.json"
OUTPUT_FILE = DATA_DIR / "questions_bank_with_explanations.json"
CHECKPOINT_FILE = DATA_DIR / "questions_explanations_checkpoint.json"

OLLAMA_URL = "http://localhost:11434/api/chat"
OLLAMA_MODEL = "medgemma:4b-it"

SAVE_EVERY = 10  # Save checkpoint every N questions


def build_prompt(question: dict) -> str:
    """Build the MedGemma prompt for a single question."""
    alts = question["alternatives"]
    correct = question["correct_answer"]

    alt_lines = "\n".join(f"{k}) {v}" for k, v in sorted(alts.items()))

    return f"""Você é uma tutora médica especializada em provas de residência (ENAMED/Revalida).

QUESTÃO: {question['enunciado']}

ALTERNATIVAS:
{alt_lines}

RESPOSTA CORRETA: {correct}

Gere uma explicação concisa e didática em português:
1. Por que a alternativa {correct} está correta (2-3 frases)
2. Por que cada alternativa errada está incorreta (1 frase cada)
3. Uma pérola clínica para memorizar esse tema

Formato: texto corrido, use **negrito** para termos importantes."""


def call_medgemma(prompt: str, timeout: int = 120) -> str | None:
    """Send prompt to MedGemma via Ollama and return the response text."""
    payload = {
        "model": OLLAMA_MODEL,
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "stream": False,
        "options": {
            "temperature": 0.3,
            "num_predict": 1024,
        },
    }
    try:
        resp = requests.post(OLLAMA_URL, json=payload, timeout=timeout)
        resp.raise_for_status()
        data = resp.json()
        return data.get("message", {}).get("content", "").strip()
    except requests.exceptions.ConnectionError:
        return None
    except requests.exceptions.Timeout:
        return None
    except requests.exceptions.RequestException as e:
        print(f"\n  [WARN] Ollama request error: {e}")
        return None
    except (json.JSONDecodeError, KeyError) as e:
        print(f"\n  [WARN] Ollama response parse error: {e}")
        return None


def check_ollama() -> bool:
    """Verify Ollama is running and the model is available."""
    try:
        resp = requests.get("http://localhost:11434/api/tags", timeout=5)
        resp.raise_for_status()
        models = [m["name"] for m in resp.json().get("models", [])]
        if not any(OLLAMA_MODEL.split(":")[0] in m for m in models):
            print(f"ERROR: Model '{OLLAMA_MODEL}' not found in Ollama.")
            print(f"  Available models: {models}")
            print(f"  Run: ollama pull {OLLAMA_MODEL}")
            return False
        return True
    except requests.exceptions.ConnectionError:
        print("ERROR: Cannot connect to Ollama at http://localhost:11434")
        print("  Start Ollama first: ollama serve")
        return False
    except Exception as e:
        print(f"ERROR: Ollama check failed: {e}")
        return False


def format_progress(current: int, total: int, elapsed: float) -> str:
    """Return a progress bar string with ETA."""
    pct = current / total if total > 0 else 0
    bar_len = 40
    filled = int(bar_len * pct)
    bar = "█" * filled + "░" * (bar_len - filled)

    if current > 0 and elapsed > 0:
        avg_per_item = elapsed / current
        remaining = (total - current) * avg_per_item
        eta = str(timedelta(seconds=int(remaining)))
    else:
        eta = "calculating..."

    return f"  [{bar}] {current}/{total} ({pct:.1%}) | ETA: {eta}"


def save_checkpoint(questions: list, processed_ids: set, output_path: Path, checkpoint_path: Path):
    """Save progress to checkpoint and output files."""
    # Save full output
    bank = {"questions": questions}
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(bank, f, ensure_ascii=False, indent=2)

    # Save checkpoint (just the set of processed IDs)
    with open(checkpoint_path, "w", encoding="utf-8") as f:
        json.dump({"processed_ids": sorted(processed_ids), "timestamp": datetime.now().isoformat()}, f, indent=2)


def load_checkpoint(checkpoint_path: Path) -> set:
    """Load previously processed question IDs from checkpoint."""
    if not checkpoint_path.exists():
        return set()
    try:
        with open(checkpoint_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        ids = set(data.get("processed_ids", []))
        ts = data.get("timestamp", "unknown")
        print(f"  Loaded checkpoint from {ts} with {len(ids)} processed questions.")
        return ids
    except (json.JSONDecodeError, KeyError):
        print("  [WARN] Corrupt checkpoint file, starting fresh.")
        return set()


def main():
    parser = argparse.ArgumentParser(description="Generate explanations for Resumed question bank")
    parser.add_argument("--dry-run", action="store_true", help="Test with only 5 questions")
    parser.add_argument("--resume", action="store_true", help="Continue from last checkpoint")
    args = parser.parse_args()

    # --- Load questions ---
    print(f"Loading questions from {QUESTIONS_FILE}...")
    if not QUESTIONS_FILE.exists():
        print(f"ERROR: Questions file not found: {QUESTIONS_FILE}")
        sys.exit(1)

    with open(QUESTIONS_FILE, "r", encoding="utf-8") as f:
        bank = json.load(f)

    questions = bank.get("questions", [])
    metadata = bank.get("metadata", {})
    valid_questions = [q for q in questions if not q.get("is_annulled", False)]
    print(f"  Total questions: {len(questions)} | Valid (non-annulled): {len(valid_questions)}")

    # --- Check Ollama ---
    print(f"\nChecking Ollama ({OLLAMA_MODEL})...")
    if not check_ollama():
        sys.exit(1)
    print("  Ollama is ready.")

    # --- Resume logic ---
    processed_ids: set = set()
    if args.resume:
        print(f"\nLoading checkpoint...")
        processed_ids = load_checkpoint(CHECKPOINT_FILE)

        # If resuming, load existing output to preserve previous explanations
        if OUTPUT_FILE.exists():
            with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
                existing = json.load(f)
            existing_map = {q["id"]: q for q in existing.get("questions", [])}
            # Merge existing explanations into current questions
            for q in questions:
                if q["id"] in existing_map and "explanation" in existing_map[q["id"]]:
                    q["explanation"] = existing_map[q["id"]]["explanation"]

    # --- Filter questions needing explanations ---
    to_process = [
        q for q in valid_questions
        if q["id"] not in processed_ids and not q.get("explanation")
    ]

    if args.dry_run:
        to_process = to_process[:5]
        print(f"\n[DRY RUN] Processing only {len(to_process)} questions.")
    else:
        print(f"\nQuestions to process: {len(to_process)}")

    if not to_process:
        print("Nothing to process. All questions already have explanations.")
        sys.exit(0)

    # --- Process questions ---
    start_time = time.time()
    success_count = 0
    skip_count = 0
    consecutive_failures = 0
    MAX_CONSECUTIVE_FAILURES = 10

    print(f"\nStarting explanation generation...\n")

    for i, question in enumerate(to_process):
        qid = question["id"]
        subject = question.get("subject", "N/A")

        # Show progress
        elapsed = time.time() - start_time
        progress = format_progress(i, len(to_process), elapsed)
        sys.stdout.write(f"\r{progress}")
        sys.stdout.flush()

        # Build prompt and call MedGemma
        prompt = build_prompt(question)
        explanation = call_medgemma(prompt)

        if explanation:
            # Store explanation in the question (find it in the full list)
            for q in questions:
                if q["id"] == qid:
                    q["explanation"] = explanation
                    break
            processed_ids.add(qid)
            success_count += 1
            consecutive_failures = 0
        else:
            skip_count += 1
            consecutive_failures += 1
            print(f"\n  [SKIP] {qid} ({subject}) - Ollama unavailable or error")

            if consecutive_failures >= MAX_CONSECUTIVE_FAILURES:
                print(f"\n\nERROR: {MAX_CONSECUTIVE_FAILURES} consecutive failures. Ollama may be down.")
                print("  Saving progress and exiting. Use --resume to continue later.")
                save_checkpoint(questions, processed_ids, OUTPUT_FILE, CHECKPOINT_FILE)
                sys.exit(1)

        # Periodic checkpoint save
        if (i + 1) % SAVE_EVERY == 0:
            save_checkpoint(questions, processed_ids, OUTPUT_FILE, CHECKPOINT_FILE)

    # --- Final save ---
    elapsed_total = time.time() - start_time
    print(f"\r{format_progress(len(to_process), len(to_process), elapsed_total)}")

    # Build final output with metadata
    output = {
        "metadata": {
            **metadata,
            "explanations_generated": success_count,
            "explanations_skipped": skip_count,
            "generation_model": OLLAMA_MODEL,
            "generation_date": datetime.now().isoformat(),
        },
        "questions": questions,
    }

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    # Clean up checkpoint on complete run (no skips)
    if skip_count == 0 and not args.dry_run and CHECKPOINT_FILE.exists():
        os.remove(CHECKPOINT_FILE)

    # --- Summary ---
    avg_time = elapsed_total / max(success_count, 1)
    print(f"\n{'='*60}")
    print(f"  DONE")
    print(f"  Processed:  {success_count} questions")
    print(f"  Skipped:    {skip_count} questions")
    print(f"  Avg time:   {avg_time:.1f}s per question")
    print(f"  Total time: {timedelta(seconds=int(elapsed_total))}")
    print(f"  Output:     {OUTPUT_FILE}")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
