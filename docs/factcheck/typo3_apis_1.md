# Fact-check: typo3_apis_1.json

**Summary:** checked 87 / ok 79 / fixed 8 / replaced 0 / flagged 0

Verified against TYPO3 Core v14.3.10 (`typo3/sysext/**`, changelogs 14.0–14.3), Fluid 5.3.2 and docs.typo3.org (14.3). All 45 `doc_url`s return HTTP 200.

The author's open doubts are settled as follows:
- **API-VH-002:** `renderStatic()` and `CompileWithRenderStatic` do not exist anywhere in `fluid/src` (Fluid 5.3.2). The method was deprecated in v13 (#104789, see `Changelog/14.0/Breaking-108148-Fluid50.rst:38`). The question is correct as written.
- **API-CLI-004:** `Configuration/Commands.php` was deprecated in 10.3 (`Changelog/10.3/Deprecation-89139-ConsoleCommandsConfigurationFormatCommandsPhp.rst`) and removed in 11.0 (`Changelog/11.0/Breaking-91473-DeprecatedFunctionalityRemoved.rst`). The question is correct as written.
- **`'mail'` transport:** it is not valid. `core/Classes/Mail/TransportFactory.php:60-186` only handles `spool`, `smtp`, `sendmail`, `mbox`, `null` and `dsn`. Any other value is passed to `makeInstance()` as a class name, and `'spool'` throws an exception (line 53).
- **`GeneralUtility::devLog()`:** it is not in the v14 source. It was deprecated in 9.0 and removed in 10.0 (`Changelog/10.0/Breaking-87193-DeprecatedFunctionalityRemoved.rst`). The API-DBG-001 distractor is correct.

| id | verdict | evidence | change |
|---|---|---|---|
| API-FF-003 | fixed | core/Documentation/Changelog/12.0/Deprecation-97126-TCEformsRemovedInFlexForm.rst; 13.0/Breaking-100963-DeprecatedFunctionalityRemoved.rst:451 | Explanation: `<TCEforms>` was deprecated in v12 and its compatibility layer was removed in v13 (the old text said "removed in v12"). |
| API-FFR-001 | fixed | extbase/Classes/Configuration/FrontendConfigurationManager.php:260-275 | Explanation: FlexForm values override TypoScript even when empty, unless the field is listed in `ignoreFlexFormSettingsIfEmpty` (the old text said only non-empty values override). |
| API-FFR-003 | fixed | frontend/Classes/ContentObject/ContentObjectRenderer.php:3664-3667, 3881-3891 | Answer A changed to the canonical form `data = flexform:pi_flexform:settings.categories`, without the stray space. |
| API-SCH-002 | fixed | scheduler/Configuration/TCA/Overrides/scheduler_file_storage_extraction_task.php:41; Changelog/14.0/Feature-107526-CustomTCATypesForSchedulerTasks.rst | Code snippet: `core.tabs:general` → `core.form.tabs:general` (the label reference that exists in v14). |
| API-MAIL-002 | fixed | core/Classes/Mail/TransportFactory.php:53-186 | Explanation now lists all handled values (smtp, sendmail, mbox, dsn, null, custom class) and says that `'spool'` throws an exception. The answer set is unchanged. |
| API-MAIL-003 | fixed | core/Classes/Mail/TemplatedEmailFactory.php:51-76; Changelog/14.2/Feature-91724-TemplatedEmailFactory.rst | The distractor named a site set `typo3/mail`, which does not exist (the real one is `typo3/email`). It is now "Only in the email.templateRootPaths site settings of the current site". The explanation now says which factory methods merge site settings. |
| API-DH-003 | fixed | Changelog/14.0/Feature-107519-AddDiscardCommandToDataHandler.rst (no deprecation of clearWSID in 14.x changelogs) | Explanation: `clearWSID`/`flush` are "still supported but discouraged", not "deprecated". |
| API-MT-003 | fixed | seo/Classes/MetaTag/OpenGraphMetaTagManager.php:53-58; core/Classes/MetaTag/AbstractMetaTagManager.php | The distractor "By default the same meta property can be added any number of times" was ambiguous, because og:image allows multiple occurrences. It is now "Meta tags are never de-duplicated: every addProperty() call for the same property renders an additional tag". The explanation mentions `allowMultipleOccurrences`. |
