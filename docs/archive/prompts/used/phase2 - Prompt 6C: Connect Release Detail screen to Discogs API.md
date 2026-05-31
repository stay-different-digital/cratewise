## Prompt 6C: Connect Release Detail screen to Discogs API

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: connect the Release Detail screen to the Discogs release detail API method.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Release Detail route.
* Use the existing secure token storage.
* Use the existing Discogs API client release detail method.
* Load the saved token before fetching details.
* Fetch release details by Discogs release ID.
* Replace placeholder detail content with real Discogs release data.
* Show a simple loading state while fetching.
* Show a simple error state if fetching fails.
* Do not add advanced error polish yet.
* Do not add Add to collection.
* Do not add Add to wishlist.
* Do not add barcode scanning.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* User taps a search result.
* App opens Release Detail screen.
* App fetches release details from Discogs.
* Screen shows:

  * Cover image if available
  * Artist
  * Title
  * Label
  * Catalog number
  * Format
  * Country
  * Released year
  * Genre
  * Style
  * Tracklist
  * Notes if available
  * Barcode and identifiers if available
  * Discogs release ID

Acceptance criteria:

* User can open real release details from search results.
* Release Detail screen shows Discogs release data.
* Loading state works.
* Simple error state works.
* Token is not shown.
* Token is not logged.
* No Add to collection feature is implemented.
* No Add to wishlist feature is implemented.
* UI works on Android phones, iPhones, and iPads.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Main architecture choices
* Tests/checks run
* Known limitations
* Recommended next small task