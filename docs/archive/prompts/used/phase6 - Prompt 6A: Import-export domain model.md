## phase6 - Prompt 6A: Import-export domain model

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the first small Phase 6 feature slice for Cratewise: add import/export domain models.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Add domain models for import and export jobs.
- Add status values for import and export.
- Add result models for validation, preview, success, skipped rows, and failed rows.
- Do not add UI yet.
- Do not connect to Discogs yet.
- Do not add CSV import yet.
- Do not add CSV export yet.
- Do not add sync behavior yet.
- Do not hardcode secrets.
- Do not log tokens.

Models should support:
- Job ID
- Job type
- Source
- Target
- Status
- Total items
- Valid items
- Skipped items
- Failed items
- Safe error message
- Created date
- Updated date

Job types should include:
- Import collection from Discogs
- Import wishlist from Discogs
- Export collection to Discogs
- Export wishlist to Discogs
- CSV collection export
- CSV wishlist export
- CSV collection import
- CSV wishlist import

Acceptance criteria:
- Import/export domain models exist.
- Import/export status values exist.
- Models do not depend on Flutter widgets.
- Models do not store tokens or secrets.
- No UI behavior changes.
- No API behavior changes.
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