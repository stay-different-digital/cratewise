## phase3 - Prompt 3C: Add to collection use case

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 3 feature slice for Cratewise: add a use case for saving a Discogs release as a local collection item.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing CollectionItem model.
- Use the existing local collection repository.
- Use release data from the existing Release Detail flow.
- Add a use case that converts release detail data into a CollectionItem.
- Save the CollectionItem locally.
- Prevent duplicate collection items for the same Discogs release ID.
- Do not add UI yet.
- Do not add an Add to collection button yet.
- Do not edit collection items yet.
- Do not remove collection items yet.
- Do not add sync logic.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Use release detail data as the source.
- Create default empty values for:
  - Media condition
  - Sleeve condition
  - Notes
  - Tags
  - Storage location
- Set created date and updated date.
- Return a clear result when the release is already in the collection.

Acceptance criteria:
- Add to collection use case exists.
- Use case saves release data as a local CollectionItem.
- Use case prevents duplicate Discogs release IDs.
- No UI behavior changes.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Main use case choices
- Tests/checks run
- Known limitations
- Recommended next small task