Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: add a Discogs release detail screen.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing secure token storage.
- Use the existing Discogs API client.
- Use the existing Search screen.
- Allow the user to open a release detail screen from a search result.
- Fetch release details from Discogs.
- Show loading, error, and content states.
- Do not add Add to collection yet.
- Do not add Add to wishlist yet.
- Do not add barcode scanning.
- Do not add CSV import or export.
- Do not add full Discogs OAuth login.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- User can tap a search result.
- App opens a release detail screen.
- Release detail screen loads data from Discogs.
- Show:
  - Cover image if available
  - Artist
  - Title
  - Label
  - Catalog number
  - Format
  - Country
  - Released year
  - Genre
  - Style
  - Tracklist
  - Notes if available
  - Barcode and identifiers if available
  - Discogs release ID
- Show loading state while loading details.
- Show friendly error state when details cannot load.
- Show friendly message when no token is connected.
- Handle rate limit response with a friendly message.
- Handle no internet with a friendly message.

Architecture requirements:
- Keep release detail API logic out of widgets.
- Keep DTO parsing separate from UI.
- Reuse existing API client patterns.
- Reuse existing error handling patterns.
- Keep route setup clean.

Acceptance criteria:
- User can open a release detail screen from search results.
- Release detail screen shows Discogs release data.
- Loading state works.
- Error state works.
- Rate limit message works.
- No Add to collection feature is implemented.
- No Add to wishlist feature is implemented.
- Token is not logged.
- Token is not hardcoded.
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