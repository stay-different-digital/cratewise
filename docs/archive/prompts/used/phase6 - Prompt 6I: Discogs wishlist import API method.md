## phase6 - Prompt 6I: Discogs wishlist import API method

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add a Discogs wishlist import API method.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Discogs API client.
- Add a method for reading the authenticated user's Discogs wishlist.
- Add pagination support.
- Add typed DTOs for Discogs wishlist items.
- Do not connect this method to UI yet.
- Do not save imported items locally yet.
- Do not add import preview yet.
- Do not add import validation yet.
- Do not add collection import changes.
- Do not add CSV behavior.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Load saved token safely.
- Use Discogs API wishlist lookup.
- Read wishlist items page by page.
- Return typed wishlist import DTOs.
- Handle no token state.
- Handle no internet state.
- Handle rate limit state.
- Handle API unavailable state.
- Do not expose raw API errors to users.

Acceptance criteria:
- Discogs API client can fetch wishlist items.
- Pagination is supported.
- Wishlist import DTOs exist.
- Token is not logged.
- Token is not stored in DTOs.
- No UI behavior changes.
- No local wishlist changes are made.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- API choices
- Tests/checks run
- Known limitations
- Recommended next small task