## Prompt 5C: Make collection detail explicitly local-first

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: make the Collection Detail screen explicitly local-first.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing local collection repository.
* Make sure Collection Detail loads from local storage only.
* Make sure Collection Detail does not require a Discogs token.
* Make sure Collection Detail does not require internet.
* Add clear not found and error states if needed.
* Do not add metadata refresh from Discogs.
* Do not add thumbnail caching yet.
* Do not change collection editing.
* Do not change wishlist behavior.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not call Discogs from Collection Detail.
* Do not hardcode secrets.
* Do not log tokens.

Acceptance criteria:

* Collection Detail works without internet.
* Collection Detail works without a saved Discogs token.
* Collection Detail reads from local storage only.
* Collection Detail does not call the Discogs API.
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