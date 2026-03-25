#!/usr/bin/env python3.10
"""
Extract questions from Revalida and ENAMED PDFs into structured JSON.
Output: data/questions_bank.json
"""

import fitz
import json
import re
import os
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
REVALIDA_DIR = BASE / "provas" / "revalida"
ENAMED_DIR = BASE / "provas" / "enamed"
OUTPUT = BASE / "questions_bank.json"

# Subject classification keywords
SUBJECT_KEYWORDS = {
    "Clínica Médica": [
        "hipertens", "diabetes", "insuficiência cardíaca", "infarto", "arritmia",
        "fibrilação", "pneumonia", "asma", "DPOC", "cirrose", "hepatite",
        "insuficiência renal", "lúpus", "artrite", "tireoide", "graves",
        "hipotireoidismo", "anemia", "leucemia", "linfoma", "HIV", "tuberculose",
        "meningite", "sepse", "choque", "AVC", "epilepsia", "cefaleia",
        "enxaqueca", "migrânea", "trombose", "embolia", "endocardite",
        "pericardite", "cardiologia", "nefrologia", "reumatologia", "neurologia",
        "hematologia", "pneumologia", "gastroenterologia", "endocrinologia",
        "infectologia", "clínica médica", "ambulatório", "atenção secundária",
        "atenção terciária", "internação", "UTI", "emergência",
    ],
    "Cirurgia Geral": [
        "cirurgia", "cirúrgic", "apendicite", "colecistite", "hérnia",
        "abdome agudo", "trauma", "atropelamento", "politraumatizado",
        "hemorragia", "hemostasia", "pós-operatório", "laparotomia",
        "colostomia", "anastomose", "ressecção", "amputação", "fratura",
        "luxação", "queimadura", "dreno", "ferida operatória", "FAST",
        "hemicolectomia", "sigmoidectomia", "orquiectomia", "testículo",
        "urologia", "uretrocistografia", "cistostomia",
    ],
    "Pediatria": [
        "lactente", "recém-nascido", "neonato", "criança", "adolescente",
        "puericultura", "amamentação", "aleitamento", "vacinação", "vacina",
        "crescimento", "desenvolvimento", "pediatr", "neonat", "berçário",
        "APGAR", "icterícia neonatal", "bronquiolite", "croup", "desidratação",
        "desnutrição", "raquitismo", "convulsão febril", "meningite bacteriana",
        "otite", "faringite", "olhinho", "orelhinha", "pezinho",
    ],
    "Ginecologia e Obstetrícia": [
        "gestante", "gravidez", "pré-natal", "parto", "cesárea", "cesariana",
        "puerpério", "aborto", "abortamento", "eclâmpsia", "pré-eclâmpsia",
        "placenta", "sangramento vaginal", "amenorreia", "menstruação",
        "anticoncepcional", "contraceptivo", "endometriose", "mioma",
        "colo do útero", "papanicolaou", "HPV", "mamografia", "BIRADS",
        "útero", "ovário", "vulva", "vaginal", "ginecolog", "obstet",
        "gestacional", "trimestre", "feto", "embrião", "cordão umbilical",
        "dispareunia", "dismenorreia",
    ],
    "Medicina Preventiva": [
        "saúde pública", "SUS", "atenção primária", "atenção básica",
        "ESF", "estratégia saúde da família", "UBS", "unidade básica",
        "vigilância", "epidemiologia", "incidência", "prevalência",
        "notificação", "SINAN", "rastreamento", "prevenção", "promoção",
        "equidade", "universalidade", "integralidade", "determinantes sociais",
        "política de saúde", "NASF", "CAPS", "saúde mental", "saúde coletiva",
        "medicina de família", "comunidade", "domiciliar", "visita domiciliar",
        "território", "agrotóxico", "saúde do trabalhador", "ocupacional",
        "acidente de trabalho",
    ],
}


def classify_subject(text: str) -> str:
    """Classify a question into a subject based on keyword matching."""
    text_lower = text.lower()
    scores = {}
    for subject, keywords in SUBJECT_KEYWORDS.items():
        score = sum(1 for kw in keywords if kw.lower() in text_lower)
        scores[subject] = score

    best = max(scores, key=scores.get)
    if scores[best] == 0:
        return "Outras"
    return best


def parse_gabarito_revalida(pdf_path: str) -> dict:
    """Parse Revalida gabarito PDF (grid or vertical format)."""
    doc = fitz.open(pdf_path)
    full_text = ""
    for page in doc:
        full_text += page.get_text()
    doc.close()

    answers = {}
    lines = [l.strip() for l in full_text.split("\n") if l.strip()]

    # Strategy 1: Grid format — extract number/letter sequences between Questão/Gabarito headers
    numbers = []
    letters = []
    in_questao_row = False
    in_gabarito_row = False

    for line in lines:
        if line in ("Questão", "QUESTÃO"):
            in_questao_row = True
            in_gabarito_row = False
            continue
        if line in ("Gabarito", "GABARITO", "GAB"):
            in_gabarito_row = True
            in_questao_row = False
            continue

        if in_questao_row:
            # Handle "14 15" on same line
            nums_in_line = re.findall(r'\d+', line)
            if nums_in_line:
                numbers.extend(int(n) for n in nums_in_line)
            elif line not in ("A", "B", "C", "D", "-", "X", "̶"):
                in_questao_row = False
        elif in_gabarito_row:
            if line in ("A", "B", "C", "D"):
                letters.append(line)
            elif line in ("-", "–", "̶", "X") or "̶" in line:
                letters.append("ANULADA")
            elif re.findall(r'\d+', line):
                # Hit next Questão row without header
                in_gabarito_row = False
            else:
                in_gabarito_row = False

    if numbers and letters:
        for n, l in zip(numbers, letters):
            answers[n] = l

    # Strategy 2: Vertical format (number\nletter pairs) - 2021/2022 style
    if len(answers) < 50:
        answers = {}
        i = 0
        while i < len(lines) - 1:
            line = lines[i]
            # Skip headers
            if line in ("QUESTÃO", "GAB", "Questão", "Gabarito", "GABARITO DEFINITIVO",
                         "GABARITO OFICIAL DEFINITIVO", "GABARITO"):
                i += 1
                continue
            # Check if current line is a number and next is a letter/X
            num_match = re.match(r'^(\d{1,3})$', line)
            if num_match:
                q_num = int(num_match.group(1))
                if 1 <= q_num <= 200:
                    next_line = lines[i + 1] if i + 1 < len(lines) else ""
                    if next_line in ("A", "B", "C", "D"):
                        answers[q_num] = next_line
                        i += 2
                        continue
                    elif next_line == "X" or "anulad" in next_line.lower():
                        answers[q_num] = "ANULADA"
                        i += 2
                        continue
            i += 1

    return answers


def parse_gabarito_enamed(pdf_path: str) -> dict:
    """Parse ENAMED gabarito PDF (3-column table format)."""
    doc = fitz.open(pdf_path)
    full_text = ""
    for page in doc:
        full_text += page.get_text()

    answers = {}
    lines = full_text.split("\n")

    i = 0
    while i < len(lines):
        line = lines[i].strip()
        # Look for question number
        if line.isdigit():
            q_num = int(line)
            # Next non-empty line should be the answer
            i += 1
            while i < len(lines) and not lines[i].strip():
                i += 1
            if i < len(lines):
                ans = lines[i].strip()
                if ans in ("A", "B", "C", "D"):
                    answers[q_num] = ans
                elif "anulad" in ans.lower() or "exclu" in ans.lower():
                    answers[q_num] = "ANULADA"
        i += 1

    doc.close()
    return answers


def extract_questions_from_pdf(pdf_path: str) -> list:
    """Extract questions from a prova PDF."""
    doc = fitz.open(pdf_path)
    full_text = ""
    for page in doc:
        full_text += page.get_text()
    doc.close()

    # Split by QUESTÃO pattern
    # Revalida: "QUESTÃO 1", ENAMED: "QUESTÃO 1" or "QUESTÃO  1"
    parts = re.split(r'QUESTÃO\s+(\d+)', full_text)

    questions = []
    # parts[0] is before first QUESTÃO, then alternating: number, content
    for i in range(1, len(parts) - 1, 2):
        q_num = int(parts[i])
        q_text = parts[i + 1].strip()

        # Remove header lines (Revalida2024, enamed, PRIMEIRA EDIÇÃO, etc.)
        q_text = re.sub(r'Revalida\s*\d{4}.*?\n', '', q_text)
        q_text = re.sub(r'enamed.*?\n', '', q_text, flags=re.IGNORECASE)
        q_text = re.sub(r'PRIMEIRA EDIÇÃO\s*\n?', '', q_text)
        q_text = re.sub(r'SEGUNDA EDIÇÃO\s*\n?', '', q_text)
        q_text = re.sub(r'Exame Nacional.*?\n', '', q_text)
        q_text = re.sub(r'da Formação Médica\s*\n?', '', q_text)
        q_text = re.sub(r'ÁREA LIVRE\s*', '', q_text)
        q_text = q_text.strip()

        # Extract alternatives
        # Revalida uses: A text\nB text\nC text\nD text
        # ENAMED uses: (A) text\n(B) text\n(C) text\n(D) text
        alternatives = {}
        enunciado = q_text

        # Try Revalida format first: lines starting with single letter
        alt_pattern_revalida = re.compile(
            r'^([ABCD])\s+(.+?)(?=\n[ABCD]\s|\Z)', re.MULTILINE | re.DOTALL
        )
        alt_pattern_enamed = re.compile(
            r'\(([ABCD])\)\s+(.+?)(?=\([ABCD]\)|\Z)', re.DOTALL
        )

        # Try ENAMED format
        matches_enamed = alt_pattern_enamed.findall(q_text)
        matches_revalida = alt_pattern_revalida.findall(q_text)

        if len(matches_enamed) >= 4:
            for letter, text in matches_enamed[:4]:
                alternatives[letter] = re.sub(r'\s+', ' ', text).strip()
            # Enunciado is everything before first (A)
            enunciado = q_text[:q_text.index("(A)")].strip()
        elif len(matches_revalida) >= 4:
            for letter, text in matches_revalida[:4]:
                alternatives[letter] = re.sub(r'\s+', ' ', text).strip()
            # Enunciado is everything before first alternative
            first_match = re.search(r'^[ABCD]\s+', q_text, re.MULTILINE)
            if first_match:
                enunciado = q_text[:first_match.start()].strip()
        else:
            # Fallback: try to find A/B/C/D at start of lines
            lines = q_text.split('\n')
            alt_lines = []
            enun_lines = []
            found_first_alt = False
            for line in lines:
                stripped = line.strip()
                if re.match(r'^[ABCD]\s', stripped) and not found_first_alt:
                    found_first_alt = True
                if found_first_alt and re.match(r'^[ABCD]\s', stripped):
                    letter = stripped[0]
                    text = stripped[2:].strip()
                    alternatives[letter] = text
                else:
                    if not found_first_alt:
                        enun_lines.append(line)
            enunciado = '\n'.join(enun_lines).strip()

        # Clean enunciado
        enunciado = re.sub(r'\s+', ' ', enunciado).strip()

        # Clean alternatives
        for k in alternatives:
            alternatives[k] = re.sub(r'\s+', ' ', alternatives[k]).strip()

        if alternatives:
            questions.append({
                "number": q_num,
                "enunciado": enunciado,
                "alternatives": alternatives,
            })

    return questions


def get_exam_info(filename: str, exam_type: str) -> dict:
    """Extract year and edition from filename."""
    # Revalida: 2024_1_PV_objetiva_regular.pdf
    # ENAMED: 2025_caderno_1_preliminar.pdf
    name = Path(filename).stem

    year_match = re.search(r'(\d{4})', name)
    year = int(year_match.group(1)) if year_match else 0

    edition = 1
    if "_2_" in name or "2024-2" in name or "_2_" in name:
        edition = 2
    elif "_1_" in name:
        edition = 1

    caderno = 1
    cad_match = re.search(r'caderno_(\d)', name)
    if cad_match:
        caderno = int(cad_match.group(1))

    return {
        "year": year,
        "edition": edition,
        "caderno": caderno,
        "exam_type": exam_type,
    }


def find_gabarito(prova_file: str, exam_dir: Path, exam_type: str) -> str | None:
    """Find matching gabarito PDF for a prova."""
    name = Path(prova_file).stem

    if exam_type == "revalida":
        # Match year and edition: PV -> GB
        year_match = re.search(r'(\d{4}(?:-\d)?_?\d?)', name)
        if year_match:
            prefix = year_match.group(1)
            for f in exam_dir.glob("*GB*"):
                if prefix.replace("_PV_", "").replace("PV", "") in f.stem.replace("_GB_", "").replace("GB", ""):
                    return str(f)
            # Try simpler match
            for f in exam_dir.glob("*GB*"):
                # Extract year from both
                fy = re.search(r'(\d{4})', f.stem)
                py = re.search(r'(\d{4})', name)
                if fy and py and fy.group(1) == py.group(1):
                    # Check edition match
                    f_ed2 = "_2_" in f.stem or "-2_" in f.stem or "2022-2" in f.stem
                    p_ed2 = "_2_" in name or "-2_" in name or "2022-2" in name
                    if f_ed2 == p_ed2:
                        return str(f)
    elif exam_type == "enamed":
        # Match caderno number
        cad_match = re.search(r'caderno_(\d)', name)
        if cad_match:
            cad_num = cad_match.group(1)
            for f in exam_dir.glob("*gabarito*"):
                if f"caderno_{cad_num}" in f.stem:
                    return str(f)

    return None


def main():
    all_questions = []
    stats = {"total": 0, "by_exam": {}, "by_subject": {}, "by_year": {}}

    # Process Revalida
    prova_files = sorted([
        f for f in REVALIDA_DIR.glob("*PV*")
        if "GB" not in f.stem and f.suffix == ".pdf"
    ])

    print(f"Found {len(prova_files)} Revalida provas")
    for pf in prova_files:
        info = get_exam_info(pf.name, "revalida")
        gab_file = find_gabarito(pf.name, REVALIDA_DIR, "revalida")

        print(f"  Processing: {pf.name} (year={info['year']}, ed={info['edition']})")

        gabarito = {}
        if gab_file:
            gabarito = parse_gabarito_revalida(gab_file)
            print(f"    Gabarito: {Path(gab_file).name} ({len(gabarito)} answers)")
        else:
            print(f"    WARNING: No gabarito found!")

        questions = extract_questions_from_pdf(str(pf))
        print(f"    Extracted: {len(questions)} questions")

        for q in questions:
            answer = gabarito.get(q["number"], "")
            subject = classify_subject(q["enunciado"])

            entry = {
                "id": f"revalida_{info['year']}_{info['edition']}_{q['number']}",
                "exam": "Revalida",
                "year": info["year"],
                "edition": info["edition"],
                "number": q["number"],
                "enunciado": q["enunciado"],
                "alternatives": q["alternatives"],
                "correct_answer": answer,
                "subject": subject,
                "is_annulled": answer == "ANULADA",
            }
            all_questions.append(entry)

    # Process ENAMED
    prova_files = sorted([
        f for f in ENAMED_DIR.glob("*caderno*")
        if "gabarito" not in f.stem and f.suffix == ".pdf"
    ])

    print(f"\nFound {len(prova_files)} ENAMED provas")
    for pf in prova_files:
        info = get_exam_info(pf.name, "enamed")
        gab_file = find_gabarito(pf.name, ENAMED_DIR, "enamed")

        print(f"  Processing: {pf.name} (year={info['year']}, caderno={info['caderno']})")

        gabarito = {}
        if gab_file:
            gabarito = parse_gabarito_enamed(gab_file)
            print(f"    Gabarito: {Path(gab_file).name} ({len(gabarito)} answers)")
        else:
            print(f"    WARNING: No gabarito found!")

        questions = extract_questions_from_pdf(str(pf))
        print(f"    Extracted: {len(questions)} questions")

        for q in questions:
            answer = gabarito.get(q["number"], "")
            subject = classify_subject(q["enunciado"])

            entry = {
                "id": f"enamed_{info['year']}_{info['caderno']}_{q['number']}",
                "exam": "ENAMED",
                "year": info["year"],
                "edition": info["caderno"],
                "number": q["number"],
                "enunciado": q["enunciado"],
                "alternatives": q["alternatives"],
                "correct_answer": answer,
                "subject": subject,
                "is_annulled": answer == "ANULADA",
            }
            all_questions.append(entry)

    # Stats
    stats["total"] = len(all_questions)
    for q in all_questions:
        exam = q["exam"]
        stats["by_exam"][exam] = stats["by_exam"].get(exam, 0) + 1
        subj = q["subject"]
        stats["by_subject"][subj] = stats["by_subject"].get(subj, 0) + 1
        yr = str(q["year"])
        stats["by_year"][yr] = stats["by_year"].get(yr, 0) + 1

    # Filter out annulled
    valid = [q for q in all_questions if not q["is_annulled"]]
    annulled = len(all_questions) - len(valid)

    output = {
        "metadata": {
            "total_questions": len(valid),
            "total_annulled": annulled,
            "stats": stats,
        },
        "questions": all_questions,
    }

    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"\n{'='*50}")
    print(f"TOTAL: {stats['total']} questions extracted")
    print(f"  Annulled: {annulled}")
    print(f"  Valid: {len(valid)}")
    print(f"\nBy exam: {json.dumps(stats['by_exam'], indent=2)}")
    print(f"\nBy subject: {json.dumps(stats['by_subject'], indent=2)}")
    print(f"\nBy year: {json.dumps(stats['by_year'], indent=2)}")
    print(f"\nSaved to: {OUTPUT}")


if __name__ == "__main__":
    main()
