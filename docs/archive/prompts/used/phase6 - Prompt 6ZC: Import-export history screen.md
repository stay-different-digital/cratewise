## phase6 - Prompt 6ZC: Import-export history screen

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add import/export history screen.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use existing import/export job storage.
- Add an Import and Export History screen or section.
- Show recent jobs.
- Show status, type, item counts, and date.
- Do not add retry behavior in this slice.
- Do not run import/export from history in this slice.
- Do not connect to Discogs.
- Do not hardcode secrets.
- Do not log tokens.

History should show:
- Job type
- Source
- Target
- Status
- Imported or exported count
- Skipped count
- Failed count
- Created date
- Safe message if available

Acceptance criteria:
- User can view import/export history.
- Empty history state is clear.
- Job details use safe wording.
- No token or secret is shown.
- No import/export action runs from this screen.
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