## phase6 - Prompt 6ZD: Import-export final polish.md

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the final small Phase 6 feature slice for Cratewise: polish import and export across the app.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Review import and export flows:
  - Import Collection from Discogs
  - Import Wishlist from Discogs
  - Export Collection to Discogs
  - Export Wishlist to Discogs
  - CSV export
  - CSV import
  - Import preview
  - Export preview
  - Import validation
  - Export validation
  - Import/export history
- Improve user-facing wording.
- Improve empty states.
- Improve error states.
- Improve iPad layout.
- Do not add new major features.
- Do not add background sync.
- Do not use unofficial Discogs endpoints.
- Do not scrape Discogs.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- User understands what will happen before confirming import.
- User understands what will happen before confirming export.
- NotSupported Discogs export states are clear.
- CSV errors are friendly.
- Import/export history is readable.
- No token or secret appears in errors.

Acceptance criteria:
- Import flows are understandable.
- Export flows are understandable.
- Preview states are clear.
- Validation states are clear.
- NotSupported states are clear.
- Import/export history is clear.
- No new major feature is added.
- Token is not shown.
- Token is not logged.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- UX polish choices
- Tests/checks run
- Known limitations
- Recommended next small task