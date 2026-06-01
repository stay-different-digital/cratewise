## Prompt 5I: Cache thumbnails after viewing release detail

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: cache cover thumbnails after viewing release details.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Release Detail screen.
* Use the existing thumbnail cache service.
* When a release detail has a cover image or thumbnail URL, cache it locally where possible.
* Do not change Collection list images yet.
* Do not change Wishlist images yet.
* Do not add bulk image caching.
* Do not add background sync.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Thumbnail cache runs after successful release detail load.
* Thumbnail cache failure does not break the screen.
* Missing image URL does not break the screen.
* Cache should avoid repeated downloads when already available if possible.

Acceptance criteria:

* Thumbnail is cached after viewing release details where possible.
* Missing image URL is handled safely.
* Failed thumbnail caching does not crash the app.
* Release Detail screen still works as before.
* No Collection list image behavior changes.
* No Wishlist image behavior changes.
* No token is logged.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Tests/checks run
* Known limitations
* Recommended next small task
