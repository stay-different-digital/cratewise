## Prompt 5G: Use cached release metadata as offline fallback

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: use cached release metadata as an offline fallback for the Release Detail screen.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Release Detail screen.
* Use the existing cached release metadata repository.
* If Discogs release detail loading fails, try loading cached metadata.
* Show cached metadata when available.
* Show clear wording that cached data is being shown.
* Do not change Search behavior.
* Do not add thumbnail caching yet.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* If online API load succeeds, show fresh data.
* If online API load fails and cache exists, show cached data.
* If online API load fails and cache does not exist, show friendly error state.
* Cached data should show last fetched date if available.
* Token must never be shown or logged.

Acceptance criteria:

* Release Detail can show cached metadata when offline or API fails.
* Cached fallback is clearly marked.
* No cache available state is clear.
* Fresh API behavior still works.
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
