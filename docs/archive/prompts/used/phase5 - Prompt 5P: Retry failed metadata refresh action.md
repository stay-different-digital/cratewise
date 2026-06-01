## Prompt 5P: Retry failed metadata refresh action

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: retry failed metadata refresh actions manually.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Failed Actions screen.
* Use the existing retry action storage.
* Use the existing Discogs API client.
* Use the existing cached metadata repository.
* Add a Retry button for metadata refresh actions only.
* When retry succeeds, update cached metadata and mark action as resolved.
* When retry fails, update attempt count and last attempted date.
* Do not retry thumbnail actions in this slice.
* Do not add retry all yet.
* Do not add background retry.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not expose tokens or secrets.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Load saved token safely when retry needs Discogs.
* If no token is connected, show friendly message.
* Do not store token in retry action.
* Do not show token in errors.
* Use safe error messages.

Acceptance criteria:

* User can retry a failed metadata refresh action.
* Successful retry updates cached metadata.
* Successful retry marks action as resolved or removes it from failed list.
* Failed retry updates attempt count.
* No token is shown.
* No token is logged.
* Thumbnail retry is not added yet.
* Retry all is not added yet.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Tests/checks run
* Known limitations
* Recommended next small task