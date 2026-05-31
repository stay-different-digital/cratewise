## phase 4 - Prompt 4A: Wishlist data model

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the first small Phase 4 feature slice for Cratewise: add the local wishlist data model.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Add a WishlistItem domain model.
- Add fields needed for a local wishlist item.
- Add a repository interface for wishlist items.
- Do not implement local database storage yet.
- Do not add UI yet.
- Do not add Add to wishlist yet.
- Do not edit wishlist items yet.
- Do not remove wishlist items yet.
- Do not add barcode scanning yet.
- Do not add sync logic.
- Do not hardcode secrets.
- Do not log tokens.

WishlistItem should support:
- Local wishlist item ID
- Discogs release ID
- Artist
- Title
- Label if available
- Catalog number if available
- Format if available
- Country if available
- Year if available
- Cover image URL if available
- Target price
- Priority
- Notes
- Created date
- Updated date

Wishlist priority options:
- Low
- Medium
- High
- Must have

Acceptance criteria:
- WishlistItem model exists.
- Wishlist repository interface exists.
- Model supports the fields listed above.
- Priority values are defined clearly.
- No UI behavior changes.
- No local database implementation is added yet.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Main model choices
- Tests/checks run
- Known limitations
- Recommended next small task