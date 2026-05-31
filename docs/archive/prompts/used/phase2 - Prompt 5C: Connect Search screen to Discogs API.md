## Prompt 5C: Connect Search screen to Discogs API

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: connect the Search screen to the Discogs release search API method.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Search screen UI.
* Use the existing secure token storage.
* Use the existing Discogs API client release search method.
* Load the saved token before searching.
* Show a friendly message when no token is connected.
* Search Discogs releases by text.
* Replace fake local result data with real Discogs search results.
* Do not add debounce logic yet.
* Do not add release detail navigation yet.
* Do not add advanced filters yet.
* Do not add collection features.
* Do not add wishlist features.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* User enters a search term.
* User can trigger a search.
* If no token is saved, the screen tells the user to connect a token in Settings.
* If a token is saved, the screen uses the Discogs API.
* Results show:

  * Cover thumbnail if available
  * Artist
  * Title
  * Format if available
  * Label if available
  * Year if available
  * Country if available
  * Discogs release ID

Acceptance criteria:

* User can search Discogs releases from the Search screen.
* User sees real Discogs search results.
* User sees a clear message when no token is connected.
* Token is not shown.
* Token is not logged.
* No release detail screen is added yet.
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