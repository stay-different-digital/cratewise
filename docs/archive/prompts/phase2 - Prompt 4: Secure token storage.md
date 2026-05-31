Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: securely save and remove a validated Discogs current token.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing token input UI.
- Use the existing token validation flow.
- Add secure token storage.
- Allow the user to save a token only after it validates successfully.
- Allow the user to remove the saved token.
- Show masked saved token status in Settings.
- Show connection status in Settings.
- Do not add search yet.
- Do not add release details yet.
- Do not add full Discogs OAuth login.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Add a small storage abstraction, for example DiscogsTokenStorage.
- Store the token using secure storage.
- Load saved connection status when Settings opens.
- Show whether a Discogs token is connected.
- Mask the saved token in the UI.
- Allow removing the token.
- After removal, show disconnected state.
- Handle secure storage failures with friendly errors.

Security requirements:
- Do not store token in plain text files.
- Do not store token in shared preferences.
- Do not print token.
- Do not show token in errors.
- Do not include token in crash output.
- Keep token storage separate from UI widgets.
- Keep token storage separate from the API client.

Acceptance criteria:
- User can save a valid token securely.
- User cannot save an invalid token.
- User can remove a saved token.
- Settings shows connected state after saving.
- Settings shows disconnected state after removing.
- Saved token is masked in the UI.
- Token is not logged.
- Token is not hardcoded.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Main security choices
- Tests/checks run
- Known limitations
- Recommended next small task