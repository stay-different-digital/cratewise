## phase4 - Prompt 4G: Wishlist detail route and data

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: add a Wishlist detail route and show local wishlist item data.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Wishlist list screen.
- Use the existing local wishlist repository.
- Add a Wishlist detail route.
- Allow the user to tap a wishlist item.
- Open a Wishlist Detail screen.
- Pass the local wishlist item ID to the detail screen.
- Load the wishlist item by local wishlist item ID.
- Show loading state.
- Show not found state.
- Show friendly error state.
- Do not edit wishlist items yet.
- Do not remove wishlist items yet.
- Do not add barcode scanning yet.
- Do not use the Discogs API in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Show:
- Cover image if available
- Artist
- Title
- Label if available
- Catalog number if available
- Format if available
- Country if available
- Year if available
- Target price
- Priority
- Notes
- Created date
- Updated date

Acceptance criteria:
- User can tap a wishlist item.
- App opens a Wishlist Detail screen.
- Wishlist Detail screen loads local wishlist item data.
- Loading state works.
- Not found state works.
- Error state works.
- No edit behavior is added yet.
- No remove behavior is added yet.
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