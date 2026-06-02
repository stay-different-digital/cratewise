## phase6 - Prompt 6C: Local import-export job storage

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add local storage for import/export jobs.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing import/export domain models.
- Use the existing import/export repository contracts.
- Implement local storage for import/export jobs.
- Do not add UI yet.
- Do not connect to Discogs yet.
- Do not add CSV logic yet.
- Do not add sync behavior yet.
- Do not hardcode secrets.
- Do not log tokens.

Architecture requirements:
- Keep storage implementation in the infrastructure layer.
- Keep repository interface in the domain layer.
- Keep storage code out of widgets.
- Keep implementation testable.

Acceptance criteria:
- Local import/export job storage exists.
- Jobs can be saved locally.
- Jobs can be updated locally.
- Recent jobs can be loaded.
- Job storage does not store tokens or secrets.
- No UI behavior changes.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Main storage choices
- Tests/checks run
- Known limitations
- Recommended next small task