## Prompt 5O: Add retry failed actions screen

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: add a screen to view failed retry actions.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing retry action storage.
* Add a Failed Actions screen or section in Settings.
* Show failed retry actions.
* Show action type, safe message, attempt count, and last attempted date if available.
* Add empty state.
* Do not execute retries yet.
* Do not add background processing.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not expose tokens or secrets.
* Do not hardcode secrets.
* Do not log tokens.

Acceptance criteria:

* User can view failed retry actions.
* Empty state is clear.
* Retry action details use safe wording.
* No token is shown.
* No secret is shown.
* No retry execution is added yet.
* UI works on Android phones, iPhones, and iPads.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* UX choices
* Tests/checks run
* Known limitations
* Recommended next small task