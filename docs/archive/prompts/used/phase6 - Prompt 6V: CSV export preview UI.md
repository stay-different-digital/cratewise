## phase6 - Prompt 6V: CSV export preview UI

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add CSV export preview UI.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Import and Export screen.
- Use the existing CSV export mappers.
- Add preview for Export Collection to CSV.
- Add preview for Export Wishlist to CSV.
- Show row count and sample rows.
- Do not write CSV files yet.
- Do not add CSV import yet.
- Do not connect to Discogs.
- Do not hardcode secrets.
- Do not log tokens.

Preview UI should show:
- Export type
- Total rows
- CSV columns
- First few sample rows
- Validation warnings if any
- Confirm button disabled or placeholder only

Acceptance criteria:
- User can preview Collection CSV export.
- User can preview Wishlist CSV export.
- Preview shows columns and row count.
- Preview shows safe sample rows.
- No file is written yet.
- No Discogs API call is made.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- UX choices
- Tests/checks run
- Known limitations
- Recommended next small task