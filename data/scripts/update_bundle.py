#!/usr/bin/env python3
"""
update_bundle.py
Copies explanations from the enriched question bank into the iOS app bundle resource.

Usage:
    python update_bundle.py
"""

import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DATA_DIR = SCRIPT_DIR.parent
PROJECT_ROOT = DATA_DIR.parent

SOURCE_FILE = DATA_DIR / "questions_bank_with_explanations.json"
BUNDLE_FILE = PROJECT_ROOT / "Resumed" / "Resumed" / "Resources" / "questions_bank.json"


def main():
    # --- Validate paths ---
    if not SOURCE_FILE.exists():
        print(f"ERROR: Source file not found: {SOURCE_FILE}")
        print("  Run generate_explanations.py first.")
        sys.exit(1)

    if not BUNDLE_FILE.exists():
        print(f"ERROR: Bundle file not found: {BUNDLE_FILE}")
        sys.exit(1)

    # --- Load source (with explanations) ---
    print(f"Loading source: {SOURCE_FILE}")
    with open(SOURCE_FILE, "r", encoding="utf-8") as f:
        source = json.load(f)

    source_questions = source.get("questions", [])
    source_map = {q["id"]: q for q in source_questions}
    explanations_available = sum(1 for q in source_questions if q.get("explanation"))

    print(f"  Source questions: {len(source_questions)}")
    print(f"  With explanations: {explanations_available}")

    # --- Load bundle ---
    print(f"\nLoading bundle: {BUNDLE_FILE}")
    with open(BUNDLE_FILE, "r", encoding="utf-8") as f:
        bundle = json.load(f)

    bundle_questions = bundle.get("questions", [])
    print(f"  Bundle questions: {len(bundle_questions)}")

    # --- Merge explanations ---
    updated = 0
    already_had = 0
    not_found = 0

    for q in bundle_questions:
        qid = q["id"]
        if qid in source_map and source_map[qid].get("explanation"):
            if q.get("explanation"):
                already_had += 1
            q["explanation"] = source_map[qid]["explanation"]
            updated += 1
        elif q.get("explanation"):
            already_had += 1

    # --- Save updated bundle ---
    with open(BUNDLE_FILE, "w", encoding="utf-8") as f:
        json.dump(bundle, f, ensure_ascii=False, indent=2)

    # --- Stats ---
    total = len(bundle_questions)
    with_explanation = sum(1 for q in bundle_questions if q.get("explanation"))
    without = total - with_explanation
    valid_count = sum(1 for q in bundle_questions if not q.get("is_annulled", False))
    valid_with = sum(1 for q in bundle_questions if not q.get("is_annulled", False) and q.get("explanation"))

    print(f"\n{'='*50}")
    print(f"  BUNDLE UPDATED")
    print(f"{'='*50}")
    print(f"  Total questions:        {total}")
    print(f"  Explanations added:     {updated}")
    print(f"  Already had:            {already_had}")
    print(f"  With explanation now:    {with_explanation}/{total} ({with_explanation/total*100:.1f}%)")
    print(f"  Valid with explanation:  {valid_with}/{valid_count} ({valid_with/valid_count*100:.1f}%)")
    print(f"  Still missing:          {without}")
    print(f"{'='*50}")
    print(f"  Output: {BUNDLE_FILE}")


if __name__ == "__main__":
    main()
