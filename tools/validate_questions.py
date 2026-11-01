#!/usr/bin/env python3
"""Validate the question bank against the schema and the TCCD v14 syllabus.

Usage:
  python tools/validate_questions.py                 # validate all files in data/questions
  python tools/validate_questions.py --coverage      # additionally print questions per skill
  python tools/validate_questions.py data/questions/extbase.json   # validate single file(s)

Exit code 0 = valid, 1 = errors found.
"""
import glob
import json
import os
import re
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SYLLABUS = os.path.join(ROOT, "data", "syllabus.json")
QUESTION_DIR = os.path.join(ROOT, "data", "questions")

CODE_LANGS = {"php", "yaml", "typoscript", "html", "xml", "json", "sql", "bash", "js", "text", "tsconfig"}
REQUIRED = ["id", "domain", "skill", "type", "difficulty", "question", "answers", "correct", "explanation", "doc_url"]
ID_RE = re.compile(r"^[A-Z]{2,5}-[A-Z0-9]{2,8}-\d{3}$")
MIN_PER_SKILL = 2


def norm(text: str) -> str:
    return re.sub(r"\W+", " ", text.lower()).strip()


def load_syllabus():
    with open(SYLLABUS, encoding="utf-8") as fh:
        data = json.load(fh)
    skills = {}
    for dom in data["domains"]:
        for skill in dom["skills"]:
            skills[(dom["id"], skill["id"])] = skill["name"]
    return data, skills


def validate_question(q, skills, errors, where):
    for key in REQUIRED:
        if key not in q:
            errors.append(f"{where}: missing '{key}'")
    if any(k not in q for k in REQUIRED):
        return
    qid = q["id"]
    if not ID_RE.match(qid):
        errors.append(f"{where}: id '{qid}' must match {ID_RE.pattern}")
    if (q["domain"], q["skill"]) not in skills:
        errors.append(f"{qid}: unknown domain/skill '{q['domain']}/{q['skill']}' (use ids from data/syllabus.json)")
    if q["type"] not in ("single", "multi"):
        errors.append(f"{qid}: type must be 'single' or 'multi'")
    if q["difficulty"] not in (1, 2, 3):
        errors.append(f"{qid}: difficulty must be 1, 2 or 3")
    if not isinstance(q["question"], str) or len(q["question"].strip()) < 10:
        errors.append(f"{qid}: question text too short")
    answers = q["answers"]
    if not isinstance(answers, list) or not 4 <= len(answers) <= 6:
        errors.append(f"{qid}: needs 4-6 answers")
        return
    if any(not isinstance(a, str) or not a.strip() for a in answers):
        errors.append(f"{qid}: empty answer")
    if len({norm(a) for a in answers}) != len(answers):
        errors.append(f"{qid}: duplicate answers")
    correct = q["correct"]
    if not isinstance(correct, list) or not correct:
        errors.append(f"{qid}: 'correct' must be a non-empty list of indices")
        return
    if len(set(correct)) != len(correct) or any(not isinstance(i, int) or i < 0 or i >= len(answers) for i in correct):
        errors.append(f"{qid}: invalid indices in 'correct'")
    if q["type"] == "single" and len(correct) != 1:
        errors.append(f"{qid}: single choice needs exactly one correct index")
    if q["type"] == "multi" and not 2 <= len(correct) < len(answers):
        errors.append(f"{qid}: multi choice needs >= 2 correct answers and at least one wrong answer")
    if len(q["explanation"].strip()) < 20:
        errors.append(f"{qid}: explanation too short")
    if not str(q["doc_url"]).startswith("https://"):
        errors.append(f"{qid}: doc_url must be an https URL")
    code = q.get("code")
    if code is not None:
        if not isinstance(code, dict) or code.get("lang") not in CODE_LANGS or not str(code.get("src", "")).strip():
            errors.append(f"{qid}: code must be {{'lang': one of {sorted(CODE_LANGS)}, 'src': '...'}}")
    lowered = " ".join(answers).lower()
    if "all of the above" in lowered or "none of the above" in lowered:
        errors.append(f"{qid}: avoid 'all/none of the above' (answers are shuffled)")


def main(argv):
    coverage = "--coverage" in argv
    files = [a for a in argv if not a.startswith("--")] or sorted(glob.glob(os.path.join(QUESTION_DIR, "*.json")))
    syllabus, skills = load_syllabus()
    errors, ids, texts = [], Counter(), {}
    per_skill = defaultdict(int)
    total = 0
    for path in files:
        name = os.path.basename(path)
        try:
            with open(path, encoding="utf-8") as fh:
                data = json.load(fh)
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"{name}: cannot parse JSON: {exc}")
            continue
        questions = data.get("questions") if isinstance(data, dict) else None
        if not isinstance(questions, list):
            errors.append(f"{name}: top level must be {{\"questions\": [...]}}")
            continue
        for i, q in enumerate(questions):
            validate_question(q, skills, errors, f"{name}[{i}]")
            qid = q.get("id", f"{name}[{i}]")
            ids[qid] += 1
            key = norm(q.get("question", "")) + "|" + (q.get("code") or {}).get("src", "")
            if key in texts:
                errors.append(f"{qid}: duplicate question text (same as {texts[key]})")
            texts[key] = qid
            per_skill[(q.get("domain"), q.get("skill"))] += 1
            total += 1
    for qid, n in ids.items():
        if n > 1:
            errors.append(f"{qid}: id used {n} times")

    if coverage:
        print("Coverage per skill (domain/skill: count)")
        for dom in syllabus["domains"]:
            dom_total = sum(per_skill[(dom["id"], s["id"])] for s in dom["skills"])
            print(f"\n## {dom['name']} ({dom_total} questions, {len(dom['skills'])} skills)")
            for skill in dom["skills"]:
                n = per_skill[(dom["id"], skill["id"])]
                flag = "" if n >= MIN_PER_SKILL else "   <-- below minimum"
                print(f"  {n:3}  {skill['name']}{flag}")
    print(f"\nFiles: {len(files)}  Questions: {total}  Errors: {len(errors)}")
    for err in errors:
        print("ERROR", err)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
