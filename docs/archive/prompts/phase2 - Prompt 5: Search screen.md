Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: make the Search screen search Discogs releases.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing secure token storage.
- Use the existing Discogs API client.
- Replace the placeholder Search screen with a working release search screen.
- Add a search input.
- Search Discogs releases by text.
- Debounce search input.
- Show release results.
- Show loading, empty, and error states.
- Do not add release detail screen yet.
- Do not add collection features.
- Do not add wishlist features.
- Do not add barcode scanning.
- Do not add CSV import or export.
- Do not add full Discogs OAuth login.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- If no token is saved, show a friendly message that the user must connect a Discogs token in Settings.
- If a token is saved, allow the user to search.
- Search input should be debounced.
- Search results should show:
  - Cover thumbnail if available
  - Artist
  - Title
  - Format if available
  - Label if available
  - Year if available
  - Country if available
  - Discogs release ID
- Empty result should show a clear empty state.
- API failure should show a friendly error state.
- Rate limit response should show a friendly message.
- No internet should show a friendly message.

Architecture requirements:
- Keep search logic out of widgets where possible.
- Add a use case or state class if the architecture already uses that pattern.
- Keep API DTO parsing separate from UI rendering.
- Keep token retrieval separate from screen widgets where possible.

Acceptance criteria:
- User can search Discogs releases when a valid token is saved.
- User sees a clear message when no token is connected.
- Search input is debounced.
- Search results show useful release information.
- Loading state works.
- Empty state works.
- Error state works.
- Rate limit message works.
- No release detail screen is added yet.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Main architecture choices
- Tests/checks run
- Known limitations
- Recommended next small task