## Prompt 5K: Add sync status to local items

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: add sync status fields to local Collection and Wishlist items.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing sync status model.
* Add sync status to local CollectionItem if not already present.
* Add sync status to local WishlistItem if not already present.
* Set sensible default values for existing and new items.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not change collection editing behavior unless needed for status updates.
* Do not change wishlist editing behavior unless needed for status updates.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* New collection items get a default sync status.
* New wishlist items get a default sync status.
* Existing local records can be read safely.
* Missing sync status should not break old local data.

Acceptance criteria:

* Collection items have sync status.
* Wishlist items have sync status.
* New local records get default sync status.
* Existing local records remain readable.
* No sync UI is added yet.
* No retry behavior is added yet.
* No cloud sync is added.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Data migration or compatibility notes
* Tests/checks run
* Known limitations
* Recommended next small task