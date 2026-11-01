# Fact-check of the question bank

All 589 questions were checked against:

- **TYPO3 Core source v14.3.10** (Doctrine DBAL 4.4, Symfony 7.4) including the changelogs 14.0–14.3
- **Fluid 5.3.2 source**
- the official **docs.typo3.org 14.3** documentation, plus PSR, php.net, Symfony, Doctrine and OWASP for generic topics

When the docs (especially `main`, which already describes v15) and the source disagreed, the source and changelog decided.

| File | Checked | OK | Fixed | Replaced | Flagged | Report |
|---|---|---|---|---|---|---|
| typo3_concepts.json | 123 | 109 | 14 | 0 | 0 | [typo3_concepts.md](typo3_concepts.md) |
| typo3_apis_1.json | 87 | 79 | 8 | 0 | 0 | [typo3_apis_1.md](typo3_apis_1.md) |
| typo3_apis_2.json | 75 | 63 | 12 | 0 | 0 | [typo3_apis_2.md](typo3_apis_2.md) |
| extbase.json | 62 | 53 | 9 | 0 | 0 | [extbase_security.md](extbase_security.md) |
| security.json | 18 | 16 | 2 | 0 | 0 | [extbase_security.md](extbase_security.md) |
| dev_concepts.json | 116 | 106 | 10 | 0 | 0 | [dev_concepts.md](dev_concepts.md) |
| dev_standards.json | 59 | 51 | 8 | 0 | 0 | [standards_thirdparty_tooling.md](standards_thirdparty_tooling.md) |
| third_party.json | 27 | 23 | 4 | 0 | 0 | [standards_thirdparty_tooling.md](standards_thirdparty_tooling.md) |
| tooling.json | 22 | 19 | 3 | 0 | 0 | [standards_thirdparty_tooling.md](standards_thirdparty_tooling.md) |
| **Total** | **589** | **519** | **70** | **0** | **0** | |

**Wrong answer keys (now corrected):**
- CON-PLUGIN-003: `configurePlugin()` adds `tt_content.<signature>` TypoScript; it does not create `plugin.tx_…`.
- EXT-ERR-003: a missing required argument throws `RequiredArgumentMissingException` (or returns a 404); it does not call `errorAction()`.

The other 68 fixes fall into three groups:
- **Explanations:** v14 module names, the `Core\Upgrades` namespace, PER-CS 3.0, the error page's request ID, Fluid argument escaping and similar details.
- **Ambiguous distractors:** for example Symfony constraints on action parameters, `og:image` multiplicity and `fromTransport`.
- **Code-snippet details and links:** for example `core.form.tabs:general`, the `typo3/email` site set and the DBAL 4.4 links.

**Links:** 287 of the 294 distinct `doc_url`s return HTTP 200. The 7 `dev.mysql.com` links return 403 to automated requests (bot protection), but they open normally in a browser.

**Note:** These are original practice questions based on the syllabus and the documentation, not real exam questions. Features from 14.1 and 14.2 are valid for 14.3 LTS, but the real exam may not cover them yet.
