## phase3 - Prompt 3E: Collection list UI only

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 3 feature slice for Cratewise: replace the placeholder Collection screen with a Collection list UI only.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Replace the placeholder Collection screen with a proper list layout.
- Use fake local display data only.
- Add collection item cards.
- Add an empty state.
- Add a basic search field UI if useful, but do not implement filtering yet.
- Do not connect to local storage yet.
- Do not add Collection detail navigation yet.
- Do not edit collection items yet.
- Do not remove collection items yet.
- Do not add sync logic.
- Do not use the Discogs API in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Collection cards should show:
- Cover image placeholder
- Artist
- Title
- Label if available
- Year if available
- Format if available
- Storage location if available

Acceptance criteria:
- Collection screen has a real list layout.
- Collection screen can show fake local collection cards.
- Collection screen has a clear empty state.
- No local storage is used yet.
- No detail navigation is added yet.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Tests/checks run
- Known limitations
- Recommended next small task