## phase3 - Prompt 3F: Connect Collection list to local storage

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 3 feature slice for Cratewise: connect the Collection list screen to local collection storage.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Collection list UI.
- Use the existing local collection repository.
- Replace fake local display data with real locally saved collection items.
- Show all saved collection items.
- Show an empty state when the collection is empty.
- Show a friendly error state if local collection data cannot load.
- Do not add filtering yet.
- Do not add sorting yet.
- Do not add Collection detail navigation yet.
- Do not edit collection items yet.
- Do not remove collection items yet.
- Do not add sync logic.
- Do not hardcode secrets.
- Do not log tokens.

Acceptance criteria:
- Collection list shows locally saved collection items.
- Collection list shows an empty state when there are no items.
- Collection list shows a friendly error state if loading fails.
- Fake local data is removed from the active screen behavior.
- No Collection detail navigation is added yet.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Main architecture choices
- Tests/checks run
- Known limitations
- Recommended next small task