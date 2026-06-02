## phase6 - Prompt 6X: CSV import parser and validation

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add CSV import parser and validation.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Add CSV parser logic.
- Add validation for collection CSV import.
- Add validation for wishlist CSV import.
- Do not add file picker UI yet.
- Do not save imported rows yet.
- Do not add import preview UI yet.
- Do not connect to Discogs.
- Do not hardcode secrets.
- Do not log tokens.

Validation should check:
- Required columns
- Valid Discogs release ID where present
- Valid condition values for collection rows
- Valid priority values for wishlist rows
- Safe text lengths
- Duplicate rows in the same file
- Missing artist or title where needed

Acceptance criteria:
- CSV parser exists.
- Collection CSV validation exists.
- Wishlist CSV validation exists.
- Validation returns valid rows, skipped rows, and failed rows.
- Parser handles empty files safely.
- Parser handles invalid CSV safely.
- No local data is saved yet.
- No UI behavior changes.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Validation rules
- Tests/checks run
- Known limitations
- Recommended next small task