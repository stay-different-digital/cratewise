## phase2 - Prompt 5B: Add Discogs release search API method

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: add a release search method to the existing Discogs API client.

Scope:

* Keep the existing Flutter app runnable.
* Use the existing Discogs API client.
* Add a method for searching Discogs releases by text.
* Add typed response models or DTOs for search results.
* Parse the fields needed by the Search screen:

  * Cover thumbnail if available
  * Artist
  * Title
  * Format if available
  * Label if available
  * Year if available
  * Country if available
  * Discogs release ID
* Add safe error handling.
* Add rate limit detection if not already present.
* Do not connect this method to the Search screen yet.
* Do not change the Search UI behavior yet.
* Do not add release detail logic yet.
* Do not add collection features.
* Do not add wishlist features.
* Do not hardcode secrets.
* Do not log tokens.

Architecture requirements:

* Keep API logic inside the infrastructure layer.
* Keep DTO parsing outside widgets.
* Keep the API method testable.
* Keep token handling safe.
* The method may receive a token as input.
* The method must not store the token.

Acceptance criteria:

* Discogs API client has a release search method.
* Search response parsing exists.
* Search errors are typed or clearly handled.
* Rate limit response can be detected.
* Search UI still works with fake local data.
* No UI is connected to the real API yet.
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