## phase6 - Prompt 6U: CSV export mapper

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add CSV export mapping for collection and wishlist data.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Add CSV export mapper logic.
- Support collection export rows.
- Support wishlist export rows.
- Do not write files yet.
- Do not add UI yet.
- Do not add export preview yet.
- Do not add CSV import yet.
- Do not connect to Discogs.
- Do not hardcode secrets.
- Do not log tokens.

Collection CSV fields:
- Artist
- Title
- Label
- Catalog number
- Format
- Country
- Year
- Discogs release ID
- Media condition
- Sleeve condition
- Notes
- Tags
- Storage location
- Created date
- Updated date

Wishlist CSV fields:
- Artist
- Title
- Label
- Catalog number
- Format
- Country
- Year
- Discogs release ID
- Target price
- Priority
- Notes
- Created date
- Updated date

Acceptance criteria:
- Collection CSV mapper exists.
- Wishlist CSV mapper exists.
- CSV headers are defined.
- Mapping handles missing values safely.
- No files are written yet.
- No UI behavior changes.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- CSV field choices
- Tests/checks run
- Known limitations
- Recommended next small task