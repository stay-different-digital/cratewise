## phase2 - Prompt 6D: Release Detail states and iPad polish

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: improve Release Detail screen states and responsive layout.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Release Detail screen connected to the Discogs API.
* Improve loading state.
* Improve empty or missing-data handling.
* Improve no token state.
* Improve no internet error state if detectable.
* Improve rate limit error state if detectable.
* Improve layout for wider iPad screens.
* Keep mobile-first layout on Android phones and iPhones.
* Do not add Add to collection.
* Do not add Add to wishlist.
* Do not add barcode scanning.
* Do not add CSV import or export.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Missing fields should not break the UI.
* Missing images should show a clean placeholder.
* Long tracklists should remain readable.
* Notes should remain readable.
* iPad layout should use available width well.
* Error messages should be friendly and safe.
* Token should never be visible in errors.

Acceptance criteria:

* Release Detail screen handles missing data safely.
* Missing cover image has a clean placeholder.
* Long release data remains readable.
* No token state is clear.
* No internet state is clear if detectable.
* Rate limit state is clear if detectable.
* iPad layout is improved.
* Phone layout still works well.
* No Add to collection feature is implemented.
* No Add to wishlist feature is implemented.
* Token is not logged.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Tests/checks run
* Known limitations
* Recommended next small task
