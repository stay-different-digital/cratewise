## phase2 - Prompt 3: Token validation

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: validate a Discogs current token from the Settings screen.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Discogs token input UI.
- Use the existing Discogs API client.
- Add a Validate token action.
- Show a loading state while validation runs.
- Show a success message when the token is valid.
- Show a friendly error message when the token is invalid.
- Keep the token only in memory during this step.
- Do not store the token yet.
- Do not add secure storage yet.
- Do not add search yet.
- Do not add release details yet.
- Do not add full Discogs OAuth login.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- User can enter a token.
- User can press Validate token.
- The app validates the token through the Discogs API client.
- The app shows success when Discogs accepts the token.
- The app shows a friendly error when Discogs rejects the token.
- The app handles no internet connection with a friendly message.
- The app handles rate limit errors with a friendly message.

Security requirements:
- Do not persist the token.
- Do not print the token.
- Do not show the token in error messages.
- Do not include the token in exceptions shown to the user.
- Keep token masking from the previous slice.

Acceptance criteria:
- User can validate a Discogs current token.
- Valid token shows a clear success state.
- Invalid token shows a clear error state.
- No internet shows a clear error state.
- Rate limit response shows a clear error state.
- Token is not stored yet.
- Token is not logged.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Tests/checks run
- Known limitations
- Recommended next small task