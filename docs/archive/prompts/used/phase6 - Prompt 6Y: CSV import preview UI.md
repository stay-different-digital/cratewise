## phase6 - Prompt 6Y: CSV import preview UI

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add CSV import preview UI.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing CSV parser and validation logic.
- Add file picker for CSV files.
- Add import preview for Collection CSV.
- Add import preview for Wishlist CSV.
- Show valid, skipped, and failed rows.
- Do not save imported rows yet.
- Do not connect to Discogs.
- Do not hardcode secrets.
- Do not log tokens.

Preview UI should show:
- File name
- Total rows
- Valid rows
- Skipped rows
- Failed rows
- Safe validation errors
- Confirm button disabled or placeholder only

Acceptance criteria:
- User can select a CSV file.
- App can parse the selected CSV.
- App shows import preview.
- App shows validation errors safely.
- No data is imported yet.
- No token or secret is shown.
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