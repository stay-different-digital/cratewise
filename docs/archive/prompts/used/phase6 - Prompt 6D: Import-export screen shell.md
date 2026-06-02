## phase6 - Prompt 6D: Import-export screen shell

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add an Import and Export screen shell.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Add an Import and Export screen or Settings section.
- Add navigation to the screen.
- Show cards for available actions.
- Use placeholder actions only.
- Do not connect buttons to real import/export behavior yet.
- Do not connect to Discogs yet.
- Do not add CSV logic yet.
- Do not add sync behavior yet.
- Do not hardcode secrets.
- Do not log tokens.

Action cards:
- Import Collection from Discogs
- Import Wishlist from Discogs
- Export Collection to Discogs
- Export Wishlist to Discogs
- Export Collection to CSV
- Export Wishlist to CSV
- Import Collection from CSV
- Import Wishlist from CSV

Acceptance criteria:
- User can open Import and Export screen.
- Screen shows all action cards.
- Actions are clearly marked as not implemented yet.
- UI works on Android phones, iPhones, and iPads.
- No API calls are made.
- No files are read or written.
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