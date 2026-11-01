#!/usr/bin/env python3
"""Convert the extracted TCCD v14 syllabus text (pdftotext -layout) into data/syllabus.json.

Usage: python tools/syllabus_to_json.py docs/syllabus/tccd14.txt data/syllabus.json
"""
import json
import re
import sys

DOMAINS = {
    "TYPO3 Concepts": "typo3_concepts",
    "Software Development Standards": "dev_standards",
    "TYPO3 APIs": "typo3_apis",
    "Software Development Concepts": "dev_concepts",
    "Extbase": "extbase",
    "Third Party APIs": "third_party",
    "Security Concepts": "security",
    "Development Tooling": "tooling",
}

SKIP = re.compile(r"(Created by the TYPO3 Education Committee|^CMS Certified Developer|Created on:)")


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


def parse(lines):
    domains = []
    current_domain = None
    current_skill = None
    for raw in lines:
        line = raw.replace("\f", "").rstrip()
        if not line.strip() or SKIP.search(line):
            continue
        stripped = line.strip()
        if stripped.startswith("Maintainer:") or stripped.startswith("http"):
            continue
        if not line.startswith(" "):
            if stripped in DOMAINS:
                current_domain = {"id": DOMAINS[stripped], "name": stripped, "skills": []}
                domains.append(current_domain)
                current_skill = None
            else:
                current_skill = {"id": slug(stripped), "name": stripped, "description": ""}
                current_domain["skills"].append(current_skill)
        elif current_skill is not None:
            sep = "" if current_skill["description"].endswith("-") else " "
            current_skill["description"] = (current_skill["description"] + sep + stripped).strip()
    return domains


def main():
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, encoding="utf-8") as fh:
        domains = parse(fh.readlines())
    total = sum(len(d["skills"]) for d in domains)
    data = {
        "exam": "TYPO3 CMS Certified Developer (TCCD) 14 LTS",
        "source": "https://typo3.com/fileadmin/Services/Certified_Developer/CMS_Certified_Developer_14_LTS.pdf",
        "exam_format": {"questions": 75, "minutes": 90, "pass_correct": 51},
        "domains": domains,
    }
    with open(dst, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    for d in domains:
        print(f"{d['id']:16} {len(d['skills']):3}")
    print(f"{'total':16} {total:3}")


if __name__ == "__main__":
    main()
