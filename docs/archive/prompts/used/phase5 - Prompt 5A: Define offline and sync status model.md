## Prompt 5A: Define offline and sync status model

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the first small Phase 5 feature slice for Cratewise: define the offline and sync status model.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Add a small domain model for local sync status.
* Add clear status values for local-first data.
* Do not add UI yet.
* Do not change collection behavior yet.
* Do not change wishlist behavior yet.
* Do not add metadata caching yet.
* Do not add thumbnail caching yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not hardcode secrets.
* Do not log tokens.

Sync status values should include:

* Local only
* Synced
* Pending
* Failed
* Conflict if useful
* Offline

Acceptance criteria:

* Sync status model exists.
* Status values are clearly named.
* Model can be used by collection, wishlist, metadata cache, and future sync actions.
* No UI behavior changes.
* No API behavior changes.
* No cloud sync is added.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Main model choices
* Tests/checks run
* Known limitations
* Recommended next small task
