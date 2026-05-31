
## Prompt 5D: Search states, debounce, and polish

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: improve Search screen states and search behavior.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Search screen connected to the Discogs API.
* Add debounce logic to the search input.
* Add loading state.
* Add empty result state.
* Add friendly error state.
* Add no internet error state if detectable.
* Add rate limit error state if detectable.
* Prevent duplicate repeated requests for the same query.
* Do not add release detail navigation yet.
* Do not add advanced filters yet.
* Do not add collection features.
* Do not add wishlist features.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Search input is debounced.
* Loading state appears while searching.
* Empty state appears when no results are found.
* Error state appears when the request fails.
* Rate limit state uses friendly wording.
* No token state still works.
* Results remain readable on phones and iPads.

Acceptance criteria:

* Search input is debounced.
* Loading state works.
* Empty state works.
* Error state works.
* Rate limit message works.
* Duplicate requests are reduced.
* No release detail screen is added yet.
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