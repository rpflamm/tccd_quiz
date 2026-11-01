# TCCD Quizz

A practice game for the **TYPO3 CMS Certified Developer (TCCD) 14 LTS** exam, built with Godot 4.7.

The questions follow the official syllabus (8 domains, 185 skills). Each question has an explanation and a link to the official documentation.

## Game modes

| Mode | What it is |
|---|---|
| **Exam Simulation** | Works like the real exam: 75 questions, 90 minutes, pass with 51 correct. There is no feedback until the end. You can flag questions and jump between them using an overview grid. Shorter variants have 38 or 15 questions. |
| **Practice** | Pick a domain (or all of them). You get instant feedback, an explanation and a docs link after every answer. Questions you have not mastered come first. |
| **Arcade Survival** | You have 3 lives and a countdown on every question. A streak multiplier goes up to ×5 and difficulty rises as you go. Your highscore is saved. |
| **Spaced Repetition** | Uses Leitner boxes 1–5 with intervals of 0, 1, 3, 7 and 14 days. Due questions come first, then new ones. |
| **Daily Challenge** | 10 questions chosen by the date, so everyone gets the same set that day. Playing on consecutive days builds a daily streak. |

On top of the modes there are XP and ranks, 19 achievements, a statistics screen with a mastery radar per domain, and a mistake review after every round.

**Controls:** `1`–`6` choose an answer, `Enter`/`Space` confirms or continues, `Esc` pauses or quits, `F11` toggles fullscreen. In the exam, `F` flags a question and `←`/`→` move between questions.

## Project layout

```
data/syllabus.json        syllabus (generated from docs/syllabus/tccd14.txt)
data/questions/*.json     question bank (schema: docs/QUESTIONS.md)
src/quiz/                 pure game logic: Question, QuestionPool, ProfileData, modes, ranks, achievements
src/autoload/             Settings, QuestionBank, Profile, Audio, Router
scenes/screens/           all screens (built in code, see Screen base class)
ui/                       theme, palette, components, shaders, FX helpers
tests/                    GUT unit tests (+ fixture questions)
tools/                    syllabus parser, question validator, icon/audio generators, screenshot tour
```

## Development

```bash
# Unit tests (GUT) + question validation
GODOT=/path/to/godot tools/run_tests.sh

# Validate questions and show coverage per syllabus skill
python3 tools/validate_questions.py --coverage

# Visual smoke test: plays through all screens and saves screenshots
godot --path . -s tools/screenshot_tour.gd -- /tmp/shots

# Regenerate the generated assets
python3 tools/syllabus_to_json.py docs/syllabus/tccd14.txt data/syllabus.json
python3 tools/gen_icons.py
python3 tools/gen_audio.py
```

## Export

You need the Godot 4.7.2 export templates (Editor → Manage Export Templates).

```bash
godot --headless --path . --export-release "Windows Desktop" "export/windows/TCCD Quizz.exe"
godot --headless --path . --export-release "Web" export/web/index.html
```

The Web build is single-threaded, so it runs without COOP/COEP headers. You can upload it as is, for example to itch.io or any static web host. Progress is stored in the browser's IndexedDB.

## Adding questions

Read `docs/QUESTIONS.md`, add entries to a file in `data/questions/`, and run the validator.

## Disclaimer

This is an unofficial learning tool and is not affiliated with the TYPO3 Association or TYPO3 GmbH. See [CREDITS.md](CREDITS.md).
