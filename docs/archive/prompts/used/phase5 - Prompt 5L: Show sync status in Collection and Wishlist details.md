## Prompt 5L: Show sync status in Collection and Wishlist details

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: show sync status on Collection and Wishlist detail screens.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use existing sync status fields.
* Show sync status on Collection Detail.
* Show sync status on Wishlist Detail.
* Use friendly wording.
* Do not add global sync status yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not change editing behavior.
* Do not hardcode secrets.
* Do not log tokens.

Suggested user-facing wording:

* Saved on this device
* Synced
* Waiting to sync
* Sync failed
* Offline
* Needs review

Acceptance criteria:

* Collection Detail shows sync status.
* Wishlist Detail shows sync status.
* Status wording is friendly.
* Status does not expose technical details.
* No retry action is added yet.
* No cloud sync is added.
* UI works on Android phones, iPhones, and iPads.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* UX wording choices
* Tests/checks run
* Known limitations
* Recommended next small task