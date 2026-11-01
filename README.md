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

## Hosting & installation

### Web version on your own web server

The Web build is a plain static site. It needs no PHP, no database and no server-side code. It is single-threaded, so it works **without** the `Cross-Origin-Opener-Policy`/`Cross-Origin-Embedder-Policy` headers and in any subdirectory.

1. **Upload everything in `export/web/`** to the target directory, for example `https://example.com/tccd-quiz/`:

   | File | Purpose |
   |---|---|
   | `index.html` | Entry page |
   | `index.js` | Engine loader |
   | `index.wasm` | Engine (~40 MB, compresses well) |
   | `index.pck` | Game data incl. all questions |
   | `index.audio.worklet.js`, `index.audio.position.worklet.js` | Audio |
   | `index.png`, `index.icon.png`, `index.apple-touch-icon.png` | Splash/icons |

2. **Check the MIME types.** This is the most common source of problems:
   - `.wasm` must be served as `application/wasm`
   - `.js` must be served as `text/javascript`
   - `.pck` must be served as `application/octet-stream`

   If they are wrong, the game does not start, or it starts without sound ("Failed to load worklet module … MIME type mismatch").
3. **Recommended:** use HTTPS, compress `.wasm`/`.pck`/`.js` (gzip or brotli), and cache the large files.
4. Open `index.html`. Progress (XP, Leitner boxes, highscores) is stored per browser in IndexedDB, so it stays on that device and browser.

**Apache** (`.htaccess` in the game directory, needs `mod_mime`, and `mod_deflate`/`mod_headers` for the optional parts):

```apache
AddType application/wasm .wasm
AddType text/javascript .js
AddType application/octet-stream .pck

<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE application/wasm text/javascript application/octet-stream text/html
</IfModule>
<IfModule mod_headers.c>
    <FilesMatch "\.(wasm|pck)$">
        Header set Cache-Control "public, max-age=86400"
    </FilesMatch>
</IfModule>
```

**nginx** (inside the `server { … }` block):

```nginx
location /tccd-quiz/ {
    alias /var/www/tccd-quiz/;
    types {
        text/html                html;
        text/javascript          js;
        application/wasm         wasm;
        application/octet-stream pck;
        image/png                png;
    }
    gzip on;
    gzip_types application/wasm text/javascript application/octet-stream;
    location ~* \.(wasm|pck)$ { add_header Cache-Control "public, max-age=86400"; }
}
```

**Caddy** (`Caddyfile`; Caddy already sets the right MIME types):

```caddy
example.com {
    root * /var/www/tccd-quiz
    encode zstd gzip
    file_server
}
```

**Testing locally:** opening `index.html` straight from disk (`file://`) does not work. Run:

```bash
python3 tools/serve_web.py          # serves export/web at http://localhost:8060/
```

The script sets the correct MIME types. The plain `python -m http.server` often serves `.js` as `text/plain` on Windows, which breaks the audio.

**Updates:** export again and replace all files. If the browser still shows the old version, reload with Ctrl+F5. The player's progress is kept.

### Web version on itch.io

1. Zip the **contents** of `export/web/`, so that `index.html` is at the top level of the ZIP.
2. On itch.io, create a new project and set *Kind of project* to **HTML**.
3. Upload the ZIP and tick **"This file will be played in the browser"**.
4. Set the viewport to **1280 × 720** and tick **"Fullscreen button"**. Leave "SharedArrayBuffer support" off; the build does not need it.

### Desktop version (Windows)

- `export/windows/TCCD Quizz.exe` is a **single portable file**: the game data is embedded and there is no installer. Copy it anywhere, for example onto the desktop or a USB stick, and start it.
- The exe is not code-signed, so Windows SmartScreen may warn on first launch. Click *More info → Run anyway*.
- Progress and settings are stored in `%APPDATA%\Godot\app_userdata\TCCD Quizz\` (`profile.json`, `settings.cfg`). To reset, delete that folder or use *Statistics → Reset all progress*.
- `F11` toggles fullscreen.

## Adding questions

Read `docs/QUESTIONS.md`, add entries to a file in `data/questions/`, and run the validator.

## Disclaimer

This is an unofficial learning tool and is not affiliated with the TYPO3 Association or TYPO3 GmbH. See [CREDITS.md](CREDITS.md).
