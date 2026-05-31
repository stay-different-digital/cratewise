## phase2 - Prompt 6A: Release detail route and placeholder screen

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: add a release detail route and placeholder screen.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Search screen.
* Add a release detail route.
* Allow the user to tap a search result.
* Open a placeholder Release Detail screen.
* Pass the Discogs release ID to the detail screen.
* Show the release ID on the placeholder screen.
* Do not fetch release details from Discogs yet.
* Do not add a release detail API method yet.
* Do not add Add to collection.
* Do not add Add to wishlist.
* Do not add barcode scanning.
* Do not hardcode secrets.
* Do not log tokens.

Acceptance criteria:

* User can tap a search result.
* App opens a Release Detail placeholder screen.
* Release Detail screen receives and shows the Discogs release ID.
* No release detail API request is made.
* Search screen still works.
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