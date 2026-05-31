## phase2 - Prompt 5A: Search UI only

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: replace the placeholder Search screen with a search UI only.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Keep the existing navigation foundation.
* Replace the placeholder Search screen with a proper search layout.
* Add a search input field.
* Add static placeholder search results using fake local data only.
* Show basic result cards.
* Result cards should show:

  * Cover placeholder
  * Artist
  * Title
  * Format
  * Label
  * Year
  * Country
  * Discogs release ID
* Add a clear empty state when the input is empty.
* Do not call the Discogs API yet.
* Do not use the saved token yet.
* Do not add debounce logic yet.
* Do not add release detail navigation yet.
* Do not add collection features.
* Do not add wishlist features.
* Do not hardcode secrets.
* Do not log tokens.

Acceptance criteria:

* App starts on Android and iOS.
* Search screen has a search input.
* Search screen shows fake local result cards.
* Empty search state is clear.
* UI works on Android phones, iPhones, and iPads.
* No API request is made.
* No token is used.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Tests/checks run
* Known limitations
* Recommended next small task