# Fact-check: typo3_concepts.json

**Summary:** 123 checked / 109 ok / 14 fixed / 0 replaced / 0 flagged

Checked against the TYPO3 Core v14.3.10 source and changelogs (`typo3/sysext/**`), Fluid 5.3.2, and the 14.3 docs. Paths are relative to the core checkout.

| id | verdict | evidence | change |
|---|---|---|---|
| CON-PLUGIN-003 | fixed (wrong answer) | typo3/sysext/extbase/Classes/Utility/ExtensionUtility.php:47-74 | Answer "creates plugin.tx_myextension_conferencelist" was marked correct but is wrong. configurePlugin() adds `tt_content.<signature>` TypoScript (EXTBASEPLUGIN). The `$pluginType` parameter still exists (optional, must be omitted or 'CType'), so I fixed the explanation and the distractor (now PLUGIN_TYPE_PLUGIN). The question now names the plugin. |
| CON-ERR-003 | fixed | typo3/sysext/frontend/Classes/ContentObject/Exception/ProductionExceptionHandler.php:72; ContentObjectRenderer.php:765 | The default message is "Oops, an error occurred! Request: {requestId}", not "Code: …". The answer and explanation now say "request ID". |
| CON-VALID-002 | fixed (ambiguous distractor) | typo3/sysext/core/Documentation/Changelog/14.0/Feature-106945-AllowUsageOfSymfonyValidatorsInExtbase.rst; extbase/Classes/Reflection/ClassSchema.php:143-252 | The changelog says constraints work on "controller methods", but the ClassSchema code only reads them on properties. The distractor "Symfony constraints are supported on controller action parameters" was therefore disputable, so I replaced it with a TypoScript-validation distractor and rewrote the explanation. |
| CON-CGL-001 | fixed (explanation) | Build/php-cs-fixer/config.php:58 | The Core uses `@PER-CS3x0`, not PER-CS 1.0/2.0. |
| CON-TCA-003 | fixed (wording) | typo3/sysext/core/Classes/Configuration/Tca/TcaMigration.php:527 | `eval=required` is still migrated automatically. I reworded the distractor to "must be configured with…" so it is clearly wrong. |
| CON-XSS-003 | fixed (explanation) | fluid/src/Core/Parser/TemplateParser.php:557-567 | Arguments are passed unescaped only when registered without `escape: true`. Added that nuance. |
| CON-EXTEND-003 | fixed (explanation) | typo3/sysext/core/Classes/DependencyInjection/ListenerProviderPass.php:88 | Listeners are keyed by identifier, so the override only works when your extension loads after the other one. Added that. |
| CON-BEMOD-002 | fixed (explanation) | typo3/sysext/core/Documentation/Changelog/14.0/Feature-107628-ImprovedBackendModuleNamingAndStructure.rst:46-135 | The list of main modules was presented as complete. It now says that 'site' is kept and that admin/system were regrouped. |
| CON-PERF-002 | fixed (wording) | typo3/sysext/adminpanel/Documentation/Inspecting/Info/Index.rst:27 | The Info section shows whether USER_INT objects exist, not a "number". |
| CON-SCHED-001 | fixed (doc_url) | typo3/sysext/scheduler/Documentation/Installation/CronJob/Index.rst:58 | doc_url now points to the 14.3 cron job page. |
| CON-SCHED-002 | fixed (doc_url) | typo3/sysext/scheduler/Documentation/DevelopersGuide/CreatingTasks/Index.rst | doc_url changed from main to 14.3. |
| CON-EVDBG-002 | fixed (doc_url) | typo3/sysext/adminpanel/Documentation/Inspecting/Debug/Index.rst | doc_url changed from main to 14.3. |
| CON-PERF-001 | fixed (doc_url) | typo3/sysext/adminpanel/Documentation/Inspecting/Debug/Index.rst | doc_url changed from main to 14.3. |
| CON-CHASH-001 | fixed (doc_url) | https://docs.typo3.org/m/typo3/reference-coreapi/14.3/en-us/ApiOverview/CachingFramework/Index.html | Removed the `#chash` anchor, which could not be verified. cHash is covered in the "Caching variants" section. |

## Notable verifications (no change needed)

- composer.json required in Classic mode: Breaking-108310. ext_emconf.php deprecated: 14.2/Deprecation-108345. ext_tables.php deprecated: 14.3/Deprecation-109438. XLF uses 2 spaces: 14.1/Important-107971.
- `searchable` option: Feature-106972. registerPlugin `$flexForm`: Feature-107047. list_type, PLUGIN_TYPE_PLUGIN, Extbase HashService and GeneralUtility::hmac removed: Breaking-105377.
- Translation domains (`my_extension.db`): Feature-93334. cHash SHA3-256 and `fallbackToLegacyHash`: Breaking-106307, DefaultConfiguration.php:1815.
- BitSet::get(): core/Classes/Type/BitSet.php:104. VersionState values: core/Classes/Versioning/VersionState.php. Default cache: CacheManager.php:52-53. Deprecation writer disabled by default: DefaultConfiguration.php:1912-1920.
- Upgrade wizard interface: core/Classes/Upgrades/UpgradeWizardInterface.php. STI `recordType`: extbase DataMapFactory.php:99. Fluid `.fluid.html`: Feature-108166. `{namespace}` syntax still supported in Fluid 5.
