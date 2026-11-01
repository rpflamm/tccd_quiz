# Question Authoring Guide (TCCD 14 LTS)

All questions live in `data/questions/*.json`. Every file has the shape `{"questions": [ ... ]}`.
The game loads every JSON file in that folder, so files can be split freely (e.g. `typo3_apis_1.json`).

## Schema

```json
{
  "id": "API-QB-003",
  "domain": "typo3_apis",
  "skill": "using_the_querybuilder",
  "type": "single",
  "difficulty": 2,
  "question": "Which method must be called to execute a SELECT query built with the QueryBuilder?",
  "code": {"lang": "php", "src": "$rows = $queryBuilder\n    ->select('*')\n    ->from('pages')\n    ->???;"},
  "answers": ["executeQuery()", "execute()", "fetchAll()", "run()"],
  "correct": [0],
  "explanation": "Since Doctrine DBAL 3 (TYPO3 v11.5+), SELECT queries are run with executeQuery(), which returns a Result object. execute() was removed.",
  "doc_url": "https://docs.typo3.org/m/typo3/reference-coreapi/14.3/en-us/ApiOverview/Database/QueryBuilder/Index.html",
  "since": "11.5",
  "tags": ["database"]
}
```

| Field | Rules |
|---|---|
| `id` | `PREFIX-TOPIC-NNN`, globally unique. Prefixes: `CON` (TYPO3 Concepts), `API` (TYPO3 APIs), `SDC` (Software Development Concepts), `STD` (Software Development Standards), `EXT` (Extbase), `TPA` (Third Party APIs), `SEC` (Security Concepts), `TOOL` (Development Tooling). TOPIC = 2–8 uppercase letters/digits. |
| `domain` / `skill` | Must be ids from `data/syllabus.json`. |
| `type` | `single` (exactly 1 correct) or `multi` (≥ 2 correct, at least 1 wrong). The UI shows "(choose N)" like the real exam. |
| `difficulty` | 1 = recall basics, 2 = applied knowledge, 3 = tricky details / code reading. |
| `answers` | 4–6 answers, unique, plausible distractors. Answers get **shuffled**: never use "all/none of the above", "A and B", etc. |
| `code` | Optional. `lang` ∈ php, yaml, typoscript, tsconfig, html, xml, json, sql, bash, js, text. Use `\n` for newlines, 4 spaces indentation. Keep under ~15 lines. |
| `explanation` | 1–3 sentences: why the correct answer(s) are right and the main distractor is wrong. |
| `doc_url` | Official source, prefer `docs.typo3.org/.../14.3/...` or `main`, PSR (`php-fig.org`), Symfony docs, php.net. |
| `since` / `tags` | Optional. Tag `breaking-change` for things that changed in v14. |

## Content rules

- **Target is TYPO3 14 LTS.** Facts must be true for v14. Do not ask about APIs removed in v14 except when the question is explicitly "what replaced X / what was removed".
- Questions are in **English**, exam style: precise, unambiguous, one defensible answer set.
- Mix ~65 % single choice / ~35 % multi choice; difficulty mix roughly 30 % / 45 % / 25 %.
- At least 2 questions per syllabus skill; cover the skill description's aspects, not trivia.
- Code snippets must be valid for v14 (PHP 8.2+, attributes instead of annotations where applicable, Services.yaml DI, `#[AsEventListener]`, etc.).

## Validation

```bash
python tools/validate_questions.py              # schema + uniqueness
python tools/validate_questions.py --coverage   # questions per skill
```
The GUT test `tests/test_question_bank.gd` also loads all files and fails on invalid questions.
