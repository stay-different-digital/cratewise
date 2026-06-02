## phase6 - Prompt 6W: CSV file export execution

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: export collection and wishlist data to CSV files.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing CSV export mappers.
- Use the existing CSV export preview UI.
- Add export execution after preview.
- Let the user save or share the generated CSV where supported.
- Create export job result.
- Do not add CSV import yet.
- Do not connect to Discogs.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Export Collection to CSV.
- Export Wishlist to CSV.
- Handle file save or share failure with friendly error.
- Show export summary after success.
- Generated CSV should not include tokens or secrets.

Acceptance criteria:
- User can export collection to CSV.
- User can export wishlist to CSV.
- Export summary is shown.
- CSV contains expected headers.
- CSV contains expected rows.
- Failure state is friendly.
- No token or secret is exported.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Export behavior
- Tests/checks run
- Known limitations
- Recommended next small task