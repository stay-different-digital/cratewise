## Prompt 5Q: Retry failed thumbnail cache action

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: retry failed thumbnail cache actions manually.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Failed Actions screen.
* Use the existing retry action storage.
* Use the existing thumbnail cache service.
* Add a Retry button for thumbnail cache actions only.
* When retry succeeds, cache the thumbnail and mark action as resolved.
* When retry fails, update attempt count and last attempted date.
* Do not change metadata retry behavior.
* Do not add retry all yet.
* Do not add background retry.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not expose tokens or secrets.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Retry should handle missing image URL safely.
* Retry should handle no internet safely.
* Retry should use safe error messages.
* Retry action should not include tokens or secrets.

Acceptance criteria:

* User can retry a failed thumbnail cache action.
* Successful retry caches the thumbnail.
* Successful retry marks action as resolved or removes it from failed list.
* Failed retry updates attempt count.
* No token is shown.
* No token is logged.
* Metadata retry still works.
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