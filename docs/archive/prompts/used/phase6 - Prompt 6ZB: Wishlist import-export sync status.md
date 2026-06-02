## phase6 - Prompt 6ZB: Wishlist import-export sync status

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: keep local wishlist import/export status in sync.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use existing WishlistItem sync status.
- Use existing import/export job storage.
- Update wishlist item sync status after Discogs import.
- Update wishlist item sync status after successful Discogs export.
- Mark failed exports safely.
- Do not add background sync.
- Do not add automatic scheduled sync.
- Do not change collection sync in this slice.
- Do not add CSV behavior.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Imported from Discogs wishlist items get a clear sync status.
- Successfully exported wishlist items get a clear sync status.
- Failed exports get a safe failed status.
- Import/export job result is linked where useful.
- No local wishlist item is deleted automatically.

Acceptance criteria:
- Wishlist import updates sync status.
- Wishlist export updates sync status.
- Failed wishlist export updates status safely.
- Existing wishlist UI still works.
- No background sync is added.
- Token is not logged.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Sync status rules
- Tests/checks run
- Known limitations
- Recommended next small task