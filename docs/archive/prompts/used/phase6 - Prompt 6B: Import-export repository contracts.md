## phase6 - Prompt 6B: Import-export repository contracts

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add import/export repository contracts.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing import/export domain models.
- Add repository interfaces for import/export jobs.
- Add repository methods for creating, updating, reading, and listing jobs.
- Do not implement local storage yet.
- Do not add UI yet.
- Do not connect to Discogs yet.
- Do not add CSV logic yet.
- Do not hardcode secrets.
- Do not log tokens.

Repository contracts should support:
- Create import/export job
- Update job status
- Add validation result
- Add preview result
- Add safe error result
- Get job by ID
- Get recent jobs

Acceptance criteria:
- Import/export repository contracts exist.
- Contracts live in the domain layer.
- Contracts do not expose tokens.
- Contracts do not depend on Flutter widgets.
- No local implementation is added yet.
- No UI behavior changes.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Main repository choices
- Tests/checks run
- Known limitations
- Recommended next small task