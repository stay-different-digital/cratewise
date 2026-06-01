## Prompt 5J: Use cached thumbnails in local collection and wishlist

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: use cached thumbnails in local Collection and Wishlist views.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing thumbnail cache service.
* Use cached thumbnails in Collection list where available.
* Use cached thumbnails in Collection Detail where available.
* Use cached thumbnails in Wishlist list where available.
* Use cached thumbnails in Wishlist Detail where available.
* Show a clean placeholder when no cached thumbnail exists.
* Do not add bulk image downloads.
* Do not add background sync.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not call Discogs from local Collection or Wishlist screens.
* Do not hardcode secrets.
* Do not log tokens.

Acceptance criteria:

* Collection list can show cached thumbnails where available.
* Collection Detail can show cached thumbnails where available.
* Wishlist list can show cached thumbnails where available.
* Wishlist Detail can show cached thumbnails where available.
* Missing cached thumbnails show clean placeholders.
* Collection and Wishlist screens still work offline.
* Collection and Wishlist screens do not call Discogs.
* UI works on Android phones, iPhones, and iPads.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Tests/checks run
* Known limitations
* Recommended next small task