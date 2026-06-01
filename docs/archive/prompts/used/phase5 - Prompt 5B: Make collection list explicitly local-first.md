## Prompt 5B: Make collection list explicitly local-first

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: make the Collection list explicitly local-first.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing local collection repository.
* Make sure the Collection list loads from local storage only.
* Make sure the Collection list does not require a Discogs token.
* Make sure the Collection list does not require internet.
* Add clear empty and error states if needed.
* Do not add metadata caching yet.
* Do not add thumbnail caching yet.
* Do not change collection editing.
* Do not change wishlist behavior.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not call Discogs from the Collection list.
* Do not hardcode secrets.
* Do not log tokens.

Acceptance criteria:

* Collection list works without internet.
* Collection list works without a saved Discogs token.
* Collection list reads from local storage only.
* Collection list does not call the Discogs API.
* Empty state is clear.
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