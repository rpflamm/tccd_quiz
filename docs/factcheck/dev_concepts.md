# Fact-check: dev_concepts.json

**Checked: 116 / ok: 106 / fixed: 10 / replaced: 0 / flagged: 0**

Sources: TYPO3 Core v14.3.10 source and changelogs; docs.typo3.org 14.3 (all TYPO3 doc_urls return HTTP 200); semver.org, getcomposer.org, php-fig.org, php.net, martinfowler.com, Wikipedia.

Author doubts settled:
- **SDC-DBMS-001**: correct. `install/Classes/SystemEnvironment/DatabaseCheck/Platform/` has exactly MySql (MySQL 8.0.17 / MariaDB 10.4.3), PostgreSql and Sqlite.
- **SDC-STI-002**: correct. `Changelog/10.0/Breaking-87623-ReplaceConfigpersistenceclassesTyposcriptConfiguration.rst`.
- **SDC-MIG-003**: answer correct. SC_OPTIONS registration was deprecated in 12.2 (#99586) and removed in 13.0 (Breaking-100963). Fixed the explanation because the namespaces moved to EXT:core in v14 (#106947).
- **SDC-RECUR-002**: `schedulable: false` still works (`ConsoleCommandPass.php:56`). In v14 each schedulable command is its own Scheduler task type (`AddSchedulableCommandsAsNativeTaskTypes`), and `#[AsNonSchedulableCommand]` was added in 14.0 (#107151). Rephrased.
- **SDC-ROUTE-001**: correct. routeEnhancers go in the site config.yaml. Site sets can ship `route-enhancers.yaml` since 14.1 (Feature-107837). Core enhancers are Simple, Plugin, PageType and Extbase (`DefaultConfiguration.php:155-158`).

| id | verdict | evidence | change |
|---|---|---|---|
| SDC-DBMS-001 | fixed (explanation) | `install/.../DatabaseCheck/Platform/MySql.php:50-52`, PostgreSql.php, Sqlite.php | Explanation now names the verified platforms and minimum MySQL/MariaDB versions |
| SDC-PREP-003 | fixed (answer text) | Snippet uses `$queryBuilder`, but the answer used an undefined `$qb` | Answer now uses `$queryBuilder` consistently |
| SDC-RECUR-002 | fixed (answers + explanation) | `scheduler/Classes/EventListener/AddSchedulableCommandsAsNativeTaskTypes.php`; `core/Classes/DependencyInjection/ConsoleCommandPass.php:56`; `Changelog/14.0/Feature-107151` | v14 offers each command as its own task type, and `#[AsNonSchedulableCommand]` was added; option 0 no longer depends on the old "Execute console commands" task label |
| SDC-MIG-001 | fixed (answers) | `Changelog/14.0/Feature-107628` (Admin Tools became System in v14) | Module paths changed to "System > Upgrade (formerly Admin Tools)" |
| SDC-MIG-003 | fixed (explanation, since) | `Changelog/14.0/Deprecation-106947`; `core/Classes/Upgrades/UpgradeWizardInterface.php`; `core/Classes/Attribute/UpgradeWizard.php` | The explanation named the deprecated `TYPO3\CMS\Install\Updates` namespace; it now gives the `TYPO3\CMS\Core\Upgrades` / `Core\Attribute\UpgradeWizard` namespaces and the SC_OPTIONS removal history; since=14.0 |
| SDC-PHPEXT-003 | fixed (question, explanation) | `core/composer.json:103` suggest ext-gd "required for building images with text (GIFBUILDER) and can also be used to scale images"; `frontend/Classes/Imaging/GifBuilder.php` | The question no longer calls GD an "alternative to ImageMagick"; it now asks what GIFBUILDER relies on |
| SDC-REL-003 | fixed (distractor) | Feature-107628: List module renamed to Records | Distractor wording changed to "Records (formerly List) module" |
| SDC-ERR-001 | fixed (doc_url) | php.net `language.exceptions.php` returns 404 | Link changed to `control-structures.try-catch.php` |
| SDC-DEBUG-002 | fixed (answer) | Feature-107628 module renaming; `install/Classes/Configuration/Context/DebugPreset.php` | Changed to "System > Settings (formerly Admin Tools)" |
| SDC-AUTO-003 | fixed (answer) | getcomposer.org: install, update and dump-autoload all regenerate the autoloader | Changed "dump-autoload must be run" to "autoloader must be regenerated, e.g. with composer dump-autoload" so the answer is strictly true |
