## phase3 - Prompt 3I: Edit media and sleeve condition

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 3 feature slice for Cratewise: allow editing media condition and sleeve condition for a collection item.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Collection Detail screen.
- Use the existing local collection repository.
- Add edit controls for media condition and sleeve condition.
- Save updated media condition and sleeve condition locally.
- Update the updated date.
- Show success feedback after saving.
- Show friendly error feedback if saving fails.
- Do not edit notes in this slice.
- Do not edit tags in this slice.
- Do not edit storage location in this slice.
- Do not remove collection items.
- Do not add sync logic.
- Do not use the Discogs API in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Suggested condition values:
- Mint
- Near Mint
- Very Good Plus
- Very Good
- Good Plus
- Good
- Fair
- Poor
- Not set

Acceptance criteria:
- User can edit media condition.
- User can edit sleeve condition.
- Changes are saved locally.
- Collection Detail screen shows the updated values.
- Updated date changes after saving.
- Notes, tags, and storage location are not edited in this slice.
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