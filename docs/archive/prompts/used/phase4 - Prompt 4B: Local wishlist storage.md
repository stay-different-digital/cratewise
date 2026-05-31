## phase 4 - Prompt 4B: Local wishlist storage

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: add local storage for wishlist items.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing WishlistItem model.
- Use the existing wishlist repository interface.
- Implement local storage for wishlist items.
- Add methods for:
  - Save wishlist item
  - Get all wishlist items
  - Get one wishlist item by ID
  - Check if a Discogs release is already in the wishlist
- Do not add UI yet.
- Do not add Add to wishlist button yet.
- Do not edit wishlist items yet.
- Do not remove wishlist items yet.
- Do not add barcode scanning yet.
- Do not add sync logic.
- Do not use the Discogs API in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Architecture requirements:
- Keep storage implementation in the infrastructure layer.
- Keep repository interface in the domain layer.
- Keep storage code out of widgets.
- Keep the implementation testable.

Acceptance criteria:
- Local wishlist storage exists.
- Wishlist repository implementation exists.
- App can save wishlist items locally through the repository.
- App can read wishlist items locally through the repository.
- App can check duplicate Discogs release IDs.
- No UI behavior changes.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Main storage choices
- Tests/checks run
- Known limitations
- Recommended next small task