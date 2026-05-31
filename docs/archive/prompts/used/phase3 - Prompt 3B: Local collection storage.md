## phase3 - Prompt 3B: Local collection storage.md

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 3 feature slice for Cratewise: add local storage for collection items.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing CollectionItem model.
- Use the existing collection repository interface.
- Implement local storage for collection items.
- Add methods for:
  - Save collection item
  - Get all collection items
  - Get one collection item by ID
  - Check if a Discogs release is already in the collection
- Do not add UI yet.
- Do not add Add to collection button yet.
- Do not edit collection items yet.
- Do not remove collection items yet.
- Do not add sync logic.
- Do not use the Discogs API in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Architecture requirements:
- Keep storage implementation in the infrastructure layer.
- Keep repository interface in the domain layer.
- Keep storage code out of widgets.
- Keep the implementation testable.

Acceptance criteria:
- Local collection storage exists.
- Collection repository implementation exists.
- App can save collection items locally through the repository.
- App can read collection items locally through the repository.
- App can check duplicate Discogs release IDs.
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