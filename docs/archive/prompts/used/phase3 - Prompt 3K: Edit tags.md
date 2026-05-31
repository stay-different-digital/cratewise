## phase3 - Prompt 3K: Edit tags

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 3 feature slice for Cratewise: allow editing tags for a collection item.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Collection Detail screen.
- Use the existing local collection repository.
- Add simple tag editing.
- Let the user add tags.
- Let the user remove tags.
- Save updated tags locally.
- Update the updated date.
- Show success feedback after saving.
- Show friendly error feedback if saving fails.
- Do not edit conditions in this slice.
- Do not edit notes in this slice.
- Do not edit storage location in this slice.
- Do not remove collection items.
- Do not add sync logic.
- Do not use the Discogs API in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Acceptance criteria:
- User can add tags.
- User can remove tags.
- Tags are saved locally.
- Collection Detail screen shows updated tags.
- Updated date changes after saving.
- Conditions, notes, and storage location are not changed by this slice.
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