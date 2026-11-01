# Fact check: Standards, Third Party APIs, Tooling

Sources: TYPO3 Core v14.3.10 source code and changelogs (`typo3/sysext/**`, `Build/`, `composer.json`/`composer.lock`), docs.typo3.org 14.3, PSR specs, Symfony 7.4, Doctrine DBAL 4.4, Sphinx, PHP-CS-Fixer, phpDocumentor, Xdebug docs.

- `data/questions/dev_standards.json`: 59 checked / 51 ok / 8 fixed / 0 replaced / 0 flagged
- `data/questions/third_party.json`: 27 checked / 23 ok / 4 fixed / 0 replaced / 0 flagged
- `data/questions/tooling.json`: 22 checked / 19 ok / 3 fixed / 0 replaced / 0 flagged

The author's open doubts, settled:
- STD-PSR15-003: `typo3/cms-frontend/site` and `typo3/cms-frontend/page-resolver` exist in `frontend/Configuration/RequestMiddlewares.php`. The site resolver runs before the page resolver, so the question is OK.
- STD-PSR11-003: `GeneralUtility::makeInstance()` uses the container only if `$container->has($className)`, otherwise it calls `new` with no arguments. The answer is OK; the explanation is fixed.
- PSR-18 / TYPO3: `Psr\Http\Client\ClientInterface` is wired in core `Services.yaml`. `RequestFactory::request(string $uri, string $method, array $options)` has the URI first; the explanation is fixed.
- TPA-CONSOLE-003: `schedulable: false` is evaluated by `CommandRegistry::getSchedulableCommandsConfiguration()`. `hidden` does not exclude a command from the scheduler. `#[AsNonSchedulableCommand]` is Feature #107151 (14.0). The question is OK.
- TOOL-ADMP-003: v14 still registers modules via `$GLOBALS['TYPO3_CONF_VARS']['EXTCONF']['adminpanel']['modules']`; core `adminpanel/ext_localconf.php` does the same. The question is OK; the explanation now also mentions the "public service" requirement.
- TOOL-SCAN-001: the card "Scan Extension Files" is in module `system_upgrade` (System > Upgrade, v14 naming). The question is OK.
- TPA-SYMF-002 (Symfony release cycle): minors every 6 months, majors every 2 years, x.4 is LTS. OK.
- TPA-DBAL-003: DBAL 4.4.4 is locked. The `ArrayParameterType` enum is correct, and TYPO3 `createNamedParameter()` accepts `string|ParameterType|Type|ArrayParameterType`, so no `\PDO::PARAM_*` int is accepted. OK.
- TOOL-CS-002: `fix --dry-run` exits non-zero (bit 8) when files need fixing. OK.
- TOOL-PHPDOC-001: `phpdoc run -d <dir> -t <target>` is correct.
- TOOL-DEBUG-002: the Xdebug 3 default `client_port` is 9003. OK.
- STD-DOC-002: Breaking #107229 confirmed (annotations removed). The explanation now also covers the new `TYPO3\CMS\Extbase\Attribute` namespace (Deprecation #107229).

| id | verdict | evidence | change |
|---|---|---|---|
| STD-PSR-001 | fixed (explanation) | `Build/php-cs-fixer/config.php` uses `'@PER-CS3x0'`; docs still say PER-CS 1.0 → 2.0 | Explanation names PER-CS 3.0 in the v14.3 Core config |
| STD-DOC-001 | fixed (explanation) | phpDocumentor: a DocBlock can also be a single line | Removed the claim that a DocBlock must be "multi-line" |
| STD-DOC-002 | fixed (explanation) | Changelog 14.0 Breaking-107229 and Deprecation-107229 | Mentions the `Extbase\Attribute` namespace; "silently ignored" became "no longer evaluated" |
| STD-PSR18-001 | fixed (explanation) | `core/Classes/Http/RequestFactory.php::request($uri, $method, $options)` | The explanation wrongly said RequestFactory has the Guzzle signature |
| STD-PSR11-003 | fixed (explanation) | `GeneralUtility::makeInstance()` uses `has()`, then falls back to `new` | Precise fallback behaviour, plus the `#[Autoconfigure(public: true)]` alternative |
| STD-XLF-003 | fixed (distractor + explanation) | `XliffLoader::parseXliff2()` iterates over all `<file>` elements, which contradicts the explanation "only one `<file>`" | Replaced the distractor with "a single XLIFF file can hold several target languages" (clearly wrong); explanation rewritten |
| STD-RST-001 | fixed (explanation) | docutils default role; TYPO3 renders the default role as code | Clarified that single backquotes are interpreted text, not an inline literal |
| STD-RST-003 | fixed (doc_url + explanation) | The TYPO3 Hyperlinks page recommends permalinks and does not mention `:ref:` | doc_url now points to the Sphinx `:ref:` role docs |
| TPA-DBAL-001 | fixed (doc_url) | composer.lock: doctrine/dbal 4.4.4 | DBAL 4.2 URL changed to the 4.4 data-retrieval page |
| TPA-DBAL-003 | fixed (doc_url + explanation) | The DBAL 4.4 query-builder page does not cover array params; the data-retrieval page does | doc_url changed; lists all ArrayParameterType cases |
| TPA-MAILER-002 | fixed (explanation) | `core/Classes/Mail/TransportFactory.php` cases: spool, smtp, sendmail, mbox, null, dsn | The explanation now lists all supported values |
| TPA-DI-002 | fixed (explanation) | Breaking #107229; no Inject attribute/annotation in v14 | `@inject` is no longer evaluated at all, not just "not recommended" |
| TOOL-LOG-004 | fixed (question + answer + explanation) | `frontend/.../ContentObject/Exception/ProductionExceptionHandler.php`: default message `Oops, an error occurred! Request: {requestId}` (13-character request ID), logged with `requestId` | The question showed the outdated "Code: <date+hex>" format; it now uses the request ID |
| TOOL-CS-002 | fixed (explanation) | PHP-CS-Fixer usage docs: exit code 8 in dry-run | Mentions the exit code bit and the `check` alias |
| TOOL-ADMP-003 | fixed (explanation) | adminpanel `ext_localconf.php`; docs "Extending": the module must be public | Added that the class must be public and that this is still valid in v14 |

Validation: `python3 tools/validate_questions.py` reports 589 questions and 0 errors.
