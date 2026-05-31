Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the first small Phase 2 feature slice for Cratewise: add a Discogs current token input UI.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Keep the existing navigation foundation from Phase 1.
- Add a Discogs connection section in Settings.
- Add a token input field for the Discogs current token.
- Add help text that tells the user where to find the token:
  https://www.discogs.com/settings/developers
- Mask the token input by default.
- Add a show/hide token toggle.
- Add placeholder buttons for Validate token and Remove token if useful, but do not implement their behavior yet.
- Keep this as UI only.
- Do not validate the token yet.
- Do not store the token yet.
- Do not add Discogs API integration yet.
- Do not add search yet.
- Do not hardcode secrets.
- Do not log tokens.

Acceptance criteria:
- App starts on Android and iOS.
- Settings contains a Discogs connection section.
- User can enter a token in a masked input field.
- User can toggle token visibility.
- Help text links or mentions the Discogs developer settings page.
- No token is stored.
- No token is validated.
- No API request is made.
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