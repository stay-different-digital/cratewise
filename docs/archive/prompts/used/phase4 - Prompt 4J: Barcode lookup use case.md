## phase4 - Prompt 4J: Barcode lookup use case

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: add a barcode lookup use case.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing secure token storage.
- Use the existing Discogs API client.
- Add a use case that accepts a barcode string.
- Use Discogs release search to find releases matching the barcode.
- Return a list of release search results.
- Handle no token state.
- Handle no result state.
- Handle API error state.
- Handle rate limit state.
- Do not add barcode scanner UI yet.
- Do not use the camera yet.
- Do not add Android camera behavior yet.
- Do not add iPhone camera behavior yet.
- Do not add iPad camera behavior yet.
- Do not add Add to collection behavior.
- Do not add Add to wishlist behavior.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Barcode input is plain text.
- Empty barcode should return a validation error.
- Saved token is loaded safely.
- Token is never shown or logged.
- Result format should match the existing search result model where possible.

Acceptance criteria:
- Barcode lookup use case exists.
- Use case can search Discogs by barcode.
- Use case handles no token state.
- Use case handles empty barcode input.
- Use case handles no results.
- Use case handles API errors.
- No UI behavior changes.
- No camera behavior is added.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Main use case choices
- Tests/checks run
- Known limitations
- Recommended next small task