## phase2 - Prompt 6B: Add Discogs release detail API method

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: add a release detail method to the existing Discogs API client.

Scope:

* Keep the existing Flutter app runnable.
* Use the existing Discogs API client.
* Add a method for fetching release details by Discogs release ID.
* Add typed response models or DTOs for release details.
* Parse the fields needed by the Release Detail screen:

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
* Add safe error handling.
* Add rate limit detection if not already present.
* Do not connect this method to the Release Detail screen yet.
* Do not change the Release Detail placeholder behavior yet.
* Do not add Add to collection.
* Do not add Add to wishlist.
* Do not hardcode secrets.
* Do not log tokens.

Architecture requirements:

* Keep API logic inside the infrastructure layer.
* Keep DTO parsing outside widgets.
* Keep the API method testable.
* The method may receive a token as input.
* The method must not store the token.

Acceptance criteria:

* Discogs API client has a release detail method.
* Release detail response parsing exists.
* Release detail errors are typed or clearly handled.
* Rate limit response can be detected.
* Release Detail screen still shows placeholder content only.
* No UI is connected to the real release detail API yet.
* No token is logged.
* No token is hardcoded.
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