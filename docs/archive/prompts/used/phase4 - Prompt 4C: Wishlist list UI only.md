## phase4 - Prompt 4C: Wishlist list UI only

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: replace the placeholder Wishlist screen with a Wishlist list UI only.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Replace the placeholder Wishlist screen with a proper list layout.
- Use fake local display data only.
- Add wishlist item cards.
- Add a clear empty state.
- Do not connect to local storage yet.
- Do not add Wishlist detail navigation yet.
- Do not add Add to wishlist yet.
- Do not edit wishlist items yet.
- Do not remove wishlist items yet.
- Do not add barcode scanning yet.
- Do not use the Discogs API in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Wishlist cards should show:
- Cover image placeholder
- Artist
- Title
- Label if available
- Year if available
- Format if available
- Priority
- Target price if available

Acceptance criteria:
- Wishlist screen has a real list layout.
- Wishlist screen can show fake local wishlist cards.
- Wishlist screen has a clear empty state.
- No local storage is used yet.
- No detail navigation is added yet.
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