## Prompt 5D: Make wishlist explicitly local-first

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: make the Wishlist explicitly local-first.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing local wishlist repository.
* Make sure Wishlist list loads from local storage only.
* Make sure Wishlist Detail loads from local storage only.
* Make sure Wishlist does not require a Discogs token.
* Make sure Wishlist does not require internet.
* Add clear empty, not found, and error states if needed.
* Do not add metadata caching yet.
* Do not add thumbnail caching yet.
* Do not change wishlist editing.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not call Discogs from Wishlist list or Wishlist Detail.
* Do not hardcode secrets.
* Do not log tokens.

Acceptance criteria:

* Wishlist list works without internet.
* Wishlist Detail works without internet.
* Wishlist works without a saved Discogs token.
* Wishlist reads from local storage only.
* Wishlist does not call the Discogs API.
* Empty state is clear.
* Not found state is clear.
* Error state is clear.
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