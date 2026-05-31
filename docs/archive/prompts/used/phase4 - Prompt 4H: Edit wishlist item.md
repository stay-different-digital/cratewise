## phase4 - Prompt 4H: Edit wishlist item

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: allow editing wishlist item details.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Wishlist Detail screen.
- Use the existing local wishlist repository.
- Add edit controls for:
  - Target price
  - Priority
  - Notes
- Save updated wishlist fields locally.
- Update the updated date.
- Show success feedback after saving.
- Show friendly error feedback if saving fails.
- Do not remove wishlist items in this slice.
- Do not add barcode scanning yet.
- Do not add sync logic.
- Do not use the Discogs API in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Acceptance criteria:
- User can edit target price.
- User can edit priority.
- User can edit notes.
- Changes are saved locally.
- Wishlist Detail screen shows updated values.
- Updated date changes after saving.
- Remove behavior is not added in this slice.
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