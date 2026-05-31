## phase3 - Prompt 3H: Collection detail data

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 3 feature slice for Cratewise: show local collection item data on the Collection Detail screen.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Collection Detail route.
- Use the existing local collection repository.
- Load the collection item by local collection item ID.
- Replace placeholder content with real local collection data.
- Show loading state.
- Show not found state.
- Show friendly error state.
- Do not edit collection items yet.
- Do not remove collection items yet.
- Do not add sync logic.
- Do not use the Discogs API in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Show:
- Cover image if available
- Artist
- Title
- Label if available
- Catalog number if available
- Format if available
- Country if available
- Year if available
- Media condition
- Sleeve condition
- Notes
- Tags
- Storage location
- Created date
- Updated date

Acceptance criteria:
- Collection Detail screen loads local collection item data.
- Loading state works.
- Not found state works.
- Error state works.
- No edit behavior is added yet.
- No remove behavior is added yet.
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