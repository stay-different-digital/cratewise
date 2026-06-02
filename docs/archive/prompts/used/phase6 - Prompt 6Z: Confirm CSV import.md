## phase6 - Prompt 6Z: Confirm CSV import

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: confirm CSV import into local collection or wishlist.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing CSV import preview UI.
- Use the existing local collection repository.
- Use the existing local wishlist repository.
- Save only valid rows.
- Skip duplicates.
- Skip invalid rows.
- Create import job result.
- Do not overwrite existing items.
- Do not delete existing items.
- Do not connect to Discogs.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- User can confirm Collection CSV import.
- User can confirm Wishlist CSV import.
- App saves valid new rows locally.
- Duplicates are skipped.
- Invalid rows are skipped.
- Import summary is shown.

Acceptance criteria:
- User can import collection from CSV.
- User can import wishlist from CSV.
- Duplicate rows are skipped.
- Invalid rows are skipped safely.
- Import summary shows imported, skipped, and failed counts.
- No existing local items are deleted.
- No token or secret is imported or shown.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Import behavior
- Tests/checks run
- Known limitations
- Recommended next small task