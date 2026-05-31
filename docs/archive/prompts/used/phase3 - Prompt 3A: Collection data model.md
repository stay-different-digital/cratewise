## phase3 - Prompt 3A: Collection data model 

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the first small Phase 3 feature slice for Cratewise: add the local collection data model.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Add a CollectionItem domain model.
- Add fields needed for a local vinyl collection item.
- Add a repository interface for collection items.
- Do not implement local database storage yet.
- Do not add UI yet.
- Do not add Add to collection yet.
- Do not edit collection items yet.
- Do not remove collection items yet.
- Do not add sync logic.
- Do not hardcode secrets.
- Do not log tokens.

CollectionItem should support:
- Local collection item ID
- Discogs release ID
- Artist
- Title
- Label if available
- Catalog number if available
- Format if available
- Country if available
- Year if available
- Cover image URL if available
- Media condition
- Sleeve condition
- Notes
- Tags
- Storage location
- Created date
- Updated date

Acceptance criteria:
- CollectionItem model exists.
- Collection repository interface exists.
- Model supports the fields listed above.
- No UI behavior changes.
- No local database implementation is added yet.
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