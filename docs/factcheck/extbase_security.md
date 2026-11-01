# Fact-check: Extbase and Security

Source: TYPO3 Core v14.3.10 (`typo3/sysext/...`, paths below are relative to it), Fluid 5.3.2, docs.typo3.org 14.3.

- `data/questions/extbase.json`: 62 checked / 53 ok / 9 fixed / 0 replaced / 0 flagged
- `data/questions/security.json`: 18 checked / 16 ok / 2 fixed / 0 replaced / 0 flagged

The author's open doubts are settled in the source:
- **redirect() vs. persistAll():** `redirect()` only builds a `RedirectResponse` (303 by default, `extbase/Classes/Mvc/Controller/ActionController.php:756-790`). `persistAll()` runs afterwards in `Bootstrap::resetSingletons()`, after dispatch, for every response (`extbase/Classes/Core/Bootstrap.php:190,237-240`). EXT-PM-002 and EXT-PM-004 are correct.
- **storagePid:** `findByUid()` → `Backend::getObjectByIdentifier()` sets `setRespectStoragePage(false)` (`extbase/Classes/Persistence/Generic/Backend.php:187`). When no storagePid is configured, it defaults to 0 (`extbase/Classes/Configuration/FrontendConfigurationManager.php:64-66`). None of the questions depends on that default.
- **STI:** `recordType`, `subclasses`, `tableName` and `properties` are read in `extbase/Classes/Persistence/Generic/Mapper/DataMapFactory.php:96-107` and `ClassesConfiguration.php:53-64`. The record type column comes from TCA `ctrl.type` (`DataMapFactory.php:157`). The record type constraint is in `Typo3DbQueryParser.php:558-583` and the subclass selection per row in `DataMapper.php:125-130`. All STI questions are correct.
- **PropagateResponseException:** this is `TYPO3\CMS\Core\Http\PropagateResponseException`. Core itself uses it with `ErrorController::pageNotFoundAction()` (`ActionController.php:840-846`).
- **Default password hash:** Argon2id for FE and BE (`core/Configuration/DefaultConfiguration.php:1706,1832`).

| id | verdict | evidence | change |
|---|---|---|---|
| EXT-ERR-003 | fixed (wrong answer set) | `extbase/Classes/Mvc/Controller/ActionController.php:856-871` (missing required argument throws RequiredArgumentMissingException, it does not call errorAction); `:306-311` (IgnoreValidation skips the validators entirely) | Correct set is now [0,2]. The ambiguous distractor about IgnoreValidation was replaced by "must be placed on errorAction()". Explanation rewritten. |
| EXT-VAL-003 | fixed (second defensible answer) | `extbase/Classes/Reflection/ClassSchema.php:143-163` vs. `:247-254` (constraints only on properties); changelog `14.0/Feature-106945` says "properties and controller methods" | Answer "constraints on action parameters" (source and changelog disagree) replaced by a clearly wrong distractor about registering in Services.yaml. Explanation updated (symfony/validator is a dependency of typo3/cms-extbase). |
| EXT-CREPO-004 | fixed (explanation) | `extbase/Classes/Persistence/Generic/Storage/Typo3DbQueryParser.php:385-396` | An empty in() throws BadConstraintException. It does not "never match" as the old text said. |
| EXT-MVC-004 | fixed (explanation) | `ActionController.php:830-846, 897-902` | A record that is not found raises TargetNotFoundException, or a 404 via `showPageNotFoundIfTargetNotFoundException`. It does not call errorAction(). |
| EXT-PLUG-004 | fixed (ambiguous wording) | `extbase/Classes/Utility/ExtensionUtility.php:47-78,119-139` | "for the plugin to work" changed to "so that editors can select this plugin as a content element". The old wording contradicted EXT-TSO-003, where EXTBASEPLUGIN renders without registerPlugin(). |
| EXT-EXC-001 | fixed (doc_url) | `core/Documentation/Changelog/13.3/Feature-104321-AllowHandlingOfArgumentMappingExceptionsInActionController.rst` | The old doc_url (RequestLifeCycle/Index) does not mention PropagateResponseException. It now points to the changelog, and the explanation names the Core usage. |
| EXT-ERR-001 | fixed (explanation) | `ActionController.php:591-605` | Explanation now mentions that the forward carries HTTP status 400. |
| EXT-REQ-002 | fixed (explanation) | `extbase/Classes/Mvc/Dispatcher.php:69-72`; `Http/ForwardResponse.php` | Removed "keeping flash messages" (true only when withFlashMessages() is used). Arguments are passed via withArguments(). |
| EXT-PERS-001 | fixed (explanation) | `extbase/Classes/Persistence/Generic/Mapper/DataMapFactory.php:168-179` | The name is built from the namespace segments after the vendor. "Extension name without underscores" was imprecise. |
| SEC-INPUT-003 | fixed (question and explanation) | `core/Classes/Database/Query/QueryBuilder.php:912-916` | TYPO3 `orderBy()` already quotes identifiers, so "make this query safe" overstated the risk. The question is now about restricting the columns that can be used. The explanation states that orderBy() quotes, and that an allow-list is still required. |
| SEC-AUTH-002 | fixed (explanation) | `core/Configuration/DefaultConfiguration.php:1706,1832` | The default is Argon2id. The vague "e.g. Argon2i/Argon2id or bcrypt" was removed. |

Spot-checked doc URLs exist on docs.typo3.org (14.3) and api.typo3.org: the Extbase chapter pages, Classes.php persistence, Security guidelines, QueryBuilder, FormProtection, PasswordHashing, Context, Fluid, MFA, AuthenticationService, BackendUserObject, Typo3Request, TypoScript EXTBASEPLUGIN and plugin, and PersistenceManagerInterface.
