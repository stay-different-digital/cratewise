## Prompt 5R: Offline mode final polish

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the final small Phase 5 feature slice for Cratewise: polish offline mode across the app.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Review offline behavior for:

  * Collection list
  * Collection Detail
  * Wishlist list
  * Wishlist Detail
  * Release Detail cached fallback
  * Barcode manual lookup error state
  * Search error state
  * Failed Actions screen
* Improve user-facing wording for offline states.
* Improve placeholders for missing metadata and thumbnails.
* Improve iPad layout where needed.
* Do not add new features.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not add background retry.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Local collection remains usable offline.
* Local wishlist remains usable offline.
* Cached release detail fallback remains clear.
* Missing cached data shows friendly wording.
* Search and barcode lookup explain that internet is required.
* No token or secret appears in errors.

Acceptance criteria:

* App is reliable without internet for local collection data.
* App is reliable without internet for local wishlist data.
* Cached metadata fallback is understandable.
* Missing thumbnails have clean placeholders.
* Failed actions are visible in Settings.
* Offline wording is clear and friendly.
* No new major feature is added.
* Token is not shown.
* Token is not logged.
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
