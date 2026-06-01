## Prompt 5N: Record failed cache refresh actions

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: record failed cache refresh actions.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing retry action storage.
* When release metadata refresh from Discogs fails in a retryable way, record a retry action.
* When thumbnail caching fails in a retryable way, record a retry action.
* Do not record tokens.
* Do not record secrets.
* Do not show retry UI yet.
* Do not execute retries yet.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not add background processing.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Store only safe action data.
* Store safe error messages only.
* Avoid duplicate retry actions for the same release and action type where possible.
* Failure to record a retry action should not crash the main flow.

Acceptance criteria:

* Failed metadata refresh can create a retry action.
* Failed thumbnail cache can create a retry action.
* Retry actions do not include tokens.
* Retry actions do not include secrets.
* Duplicate retry actions are reduced where possible.
* No retry UI is added yet.
* No retry execution is added yet.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Security notes
* Tests/checks run
* Known limitations
* Recommended next small task