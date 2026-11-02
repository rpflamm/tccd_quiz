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

`tools/ci/export_release.sh [version]` runs both exports and packages them in `dist/` as `TCCD-Quizz-<version>-windows-portable.exe`, `TCCD-Quizz-<version>-web.zip` (with `index.html` at the top level) and `SHA256SUMS.txt`. With a version argument (`v1.2.0` or `1.2.0`) it first writes that version into `project.godot` and the Windows file version.

## CI & releases

Both pipelines use `tools/ci/install_godot.sh`, which downloads Godot 4.7.2 for Linux and, for releases, only the two export templates the presets need.

| | Tests | Release |
|---|---|---|
| **GitHub Actions** | `.github/workflows/tests.yml` on every push to `main` and every pull request | `.github/workflows/release.yml`: **publish a release** with a tag like `v1.2.0`. The tests run, then the exe, the Web ZIP and `SHA256SUMS.txt` are attached to the release. |
| **GitLab CI** | `.gitlab-ci.yml`, job `test`, on every branch, merge request and tag | **Push a tag** like `v1.2.0`. The files are uploaded to the generic package registry and the pipeline creates the GitLab release with links to them. Do not create the release in the UI first. |

The release version comes from the tag, so you do not need to bump `config/version` by hand.

## Hosting & installation

### Web version on your own web server

The Web build is a plain static site. It needs no PHP, no database and no server-side code. It is single-threaded, so it works **without** the `Cross-Origin-Opener-Policy`/`Cross-Origin-Embedder-Policy` headers and in any subdirectory.

1. **Upload everything in `export/web/`** to the target directory, for example `https://example.com/tccd-quiz/`:

   | File | Purpose |
   |---|---|
   | `index.html` | Entry page |
   | `index.js` | Engine loader |
   | `index.wasm` | Engine (~38 MB, compresses to ~11 MB) |
   | `index.pck` | Game data incl. all questions |
   | `index.audio.worklet.js`, `index.audio.position.worklet.js` | Audio |
   | `index.png`, `index.icon.png`, `index.apple-touch-icon.png` | Splash/icons |
   | `index.manifest.json`, `index.service.worker.js`, `index.offline.html`, `index.144x144.png`, `index.180x180.png`, `index.512x512.png` | Installable web app (PWA) |

2. **Check the MIME types.** This is the most common source of problems:
   - `.json` (manifest) must be served as `application/json` or `application/manifest+json`
   - `.wasm` must be served as `application/wasm`
   - `.js` must be served as `text/javascript`
   - `.pck` must be served as `application/octet-stream`

   If they are wrong, the game does not start, or it starts without sound ("Failed to load worklet module … MIME type mismatch").
3. **Recommended:** use HTTPS and compress `.wasm`/`.pck`/`.js` (gzip or brotli).

   **Do not let browsers cache the game files for a fixed time** (`max-age`, `expires 7d`, …). The file names stay the same on every export, so the browser would keep loading the old `index.pck` (game code and questions) until the time is up. Even the service worker would then store the old file as the new version. Send `Cache-Control: no-cache` instead. The browser then checks the file on every start, and if nothing changed the server answers `304 Not Modified` without sending the file again.
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
    Header set Cache-Control "no-cache"
    Header unset Expires
</IfModule>
<IfModule mod_expires.c>
    ExpiresActive Off
</IfModule>
```

**nginx** (inside the `server { … }` block; `^~` keeps generic rules such as `location ~* \.(png|wasm)$ { expires 7d; }` from overriding this block):

```nginx
location ^~ /tccd-quiz/ {
    alias /var/www/tccd-quiz/;
    types {
        text/html                html;
        text/javascript          js;
        application/wasm         wasm;
        application/octet-stream pck;
        application/json         json;
        image/png                png;
    }
    gzip on;
    gzip_types application/wasm text/javascript application/octet-stream;
    # Always revalidate: file names never change between exports.
    expires off;
    add_header Cache-Control "no-cache";
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

**Updates:** export again and replace all files. The player's progress is kept.

The service worker serves the game cache-first, so a plain reload (or Ctrl+F5) keeps showing the old version. When the page starts, the browser checks for a new service worker and downloads the new build in the background. As soon as it is ready, the main menu shows an *Update available* banner, and *Reload* switches to the new version. A player who ignores the banner gets the new version once every tab and the installed app have been closed.

Builds exported before November 2026 do not have this banner yet. To switch them over once, close every tab and the installed app and open the game again, or clear the site data. Clearing the site data also deletes the progress.

### Smartphones & tablets

The Web version is responsive and adapts to the screen:

| Screen | Layout |
|---|---|
| Desktop / tablet landscape | Original 3-column layout (logical canvas 1280×720) |
| Phone landscape (height < 640 CSS px) | Compact layout, scaled so the text stays readable |
| Phone portrait | Single-column layout, two-line HUD, icon buttons in the exam, full-width answers |

- **Rotating the device:** the layout rebuilds immediately. Progress, timer, the answer you picked and an open explanation are all kept.
- **Touch:** you tap the answer cards. Keyboard hints are hidden on touch devices.
- **Install as an app (PWA):** the Web export contains a manifest, a service worker and icons.
  - Android/Chrome: menu → *Add to Home screen* / *Install app*
  - iOS/Safari: share button → *Add to Home Screen*

  The quiz then starts full screen like an app, works offline after the first load, and the browser keeps its saved progress. On iOS, Safari may otherwise delete website data after 7 days without use.
- **HTTPS is required** for installing and for the service worker (except on `localhost`).
- **First load:** about 12 MB with gzip compression (about 40 MB uncompressed). After that it is cached.

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
