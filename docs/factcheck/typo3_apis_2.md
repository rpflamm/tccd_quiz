# Fact-check: typo3_apis_2.json

**Summary:** checked 75 / ok 63 / fixed 12 / replaced 0 / flagged 0

Sources: TYPO3 Core v14.3.10 checkout (`typo3/sysext/**`, changelogs, `Build/Sources`), docs.typo3.org 14.3 pages (doc_urls spot-checked: they exist and support the answers).

Author's open doubts, settled:
- JS Notification duration: seconds, default 5, `error()` defaults to 0, 0 = sticky. Notifications show bottom right (`Build/Sources/TypeScript/backend/notification.ts:35,98,116`, `Build/Sources/Sass/element/typo3-notification-message.scss:21-38`). OK.
- `$cObj->stdWrapValue('as', ...)` exists and Core processors use it (`frontend/Classes/ContentObject/ContentObjectRenderer.php:1220`, `frontend/Classes/DataProcessing/DatabaseQueryProcessor.php:80`). OK.
- `setAndSaveSessionData()` exists on AbstractUserAuthentication (`core/Classes/Authentication/AbstractUserAuthentication.php:1060`). OK.
- Session type `'user'` writes to `uc` for a logged-in user (`frontend/Classes/Authentication/FrontendUserAuthentication.php:453-461`). OK.
- `displayErrors = -1` + `devIPmask` picks the debug or production handler (`core/Classes/Core/Bootstrap.php:405-407`). OK.
- Password `hashed` default is true; `false` is ignored for be_users/fe_users (`core/Classes/DataHandling/DataHandler.php:1720`, `core/Classes/Schema/Field/PasswordFieldType.php:34`). OK, nuance added.

| id | verdict | evidence | change |
|---|---|---|---|
| API-XNOTI-003 | fixed | Build/Sources/TypeScript/backend/notification.ts:35,98,116 | Explanation now gives the defaults (5 s, error 0) |
| API-XRTE-002 | fixed | core/Classes/Configuration/Richtext.php:72; :190-204 | Explanation said RTE.default.preset overrides TCA. It is only a fallback after richtextConfiguration; field-specific TSconfig wins |
| API-XDASH-002 | fixed | dashboard/Documentation/Configuration/WidgetRegistration.rst:124-178; dashboard/Classes/DependencyInjection/DashboardWidgetPass.php:48,68-72 | Question now asks what the docs list as mandatory (source sets defaults for identifier and iconIdentifier) |
| API-XASSET-002 | fixed | core/Classes/Page/PageRenderer.php:1245-1249 | "Stylesheets are always in head" is wrong for non-priority inline CSS (goes to footer). Answer narrowed to addStyleSheet() files |
| API-XLOW-003 | fixed | core/Documentation/Changelog/14.0/Breaking-97151-RemoveDatabaseRelationsBackendModule.rst | Database Relations was a submodule of DB Check, not a separate module; wording made precise |
| API-XTUSER-003 | fixed | core/Documentation/Changelog/9.5/Deprecation-86163-TCATypeuserWithoutRenderType.rst | Explanation said userFunc was removed in v12. It was deprecated in 9.5 |
| API-XTSLUG-002 | fixed | core/Classes/DataHandling/SlugHelper.php:171-198 | Answer wording: slug from title only (an exact string value depends on prependSlash) |
| API-XTSPEC-003 | fixed | core/Classes/DataHandling/DataHandler.php:1720 | Correct answer and explanation now say `hashed => false` is ignored for be_users/fe_users |
| API-XMSG-003 | fixed | core/Documentation/Changelog/14.3.x/Important-107032-MessageHandlerFromTransportIsHonoured.rst; core/Classes/DependencyInjection/MessageHandlerPass.php:74 | fromTransport was ignored before a 14.3.x patch and does not restrict synchronously handled messages, so it was ambiguous. Replaced with the tag `message` attribute (verified) |
| API-XCSP-002 | fixed | core/Classes/Security/ContentSecurityPolicy/MutationMode.php | Explanation said Remove removes sources. Reduce removes sources; Remove drops the directive |
| API-XCACHE-003 | fixed | core/Documentation/Changelog/14.0/Breaking-107315-CacheBackendAndFrontendRelatedChanges.rst; core/Classes/Cache/Backend/AbstractBackend.php:43 | Statement reworded from "must use signature" to the actual change (BC $context argument dropped) |
| API-XSESS-001 | fixed | frontend/Classes/Middleware/FrontendUserAuthenticator.php:79-80; frontend/Classes/Authentication/FrontendUserAuthentication.php:354 | The middleware calls storeSessionData() automatically after each FE request, so "what must be called for the next request" was misleading. Question now asks which method writes the data; explanation mentions the automatic call |
