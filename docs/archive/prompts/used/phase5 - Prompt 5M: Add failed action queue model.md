## Prompt 5M: Add failed action queue model

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: add a failed action queue model for retryable local app actions.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Add a FailedAction or RetryAction model.
* Add a repository interface for retry actions.
* Add local storage for retry actions.
* Do not connect this to UI yet.
* Do not retry actions yet.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not add background processing.
* Do not hardcode secrets.
* Do not log tokens.

Retry action should support:

* Action ID
* Action type
* Related entity type
* Related entity ID
* Safe error message
* Created date
* Last attempted date if available
* Attempt count
* Status

Important security rule:

* Do not store tokens inside retry actions.
* Do not store secrets inside retry actions.
* Do not store raw API headers inside retry actions.

Acceptance criteria:

* Retry action model exists.
* Retry action repository interface exists.
* Local retry action storage exists.
* Retry actions can be saved.
* Retry actions can be loaded.
* Retry actions do not contain tokens or secrets.
* No UI behavior changes.
* No retry execution is added yet.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Main model choices
* Security notes
* Tests/checks run
* Known limitations
* Recommended next small task