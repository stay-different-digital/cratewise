## Prompt 4D: Connect Wishlist list to local storage

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: connect the Wishlist list screen to local wishlist storage.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Wishlist list UI.
- Use the existing local wishlist repository.
- Replace fake local display data with real locally saved wishlist items.
- Show all saved wishlist items.
- Show an empty state when the wishlist is empty.
- Show a friendly error state if local wishlist data cannot load.
- Do not add filtering yet.
- Do not add sorting yet.
- Do not add Wishlist detail navigation yet.
- Do not add Add to wishlist yet.
- Do not edit wishlist items yet.
- Do not remove wishlist items yet.
- Do not add barcode scanning yet.
- Do not add sync logic.
- Do not hardcode secrets.
- Do not log tokens.

Acceptance criteria:
- Wishlist list shows locally saved wishlist items.
- Wishlist list shows an empty state when there are no items.
- Wishlist list shows a friendly error state if loading fails.
- Fake local data is removed from the active screen behavior.
- No Wishlist detail navigation is added yet.
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