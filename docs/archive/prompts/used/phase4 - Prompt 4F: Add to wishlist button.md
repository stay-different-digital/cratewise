## phase4 - Prompt 4F: Add to wishlist button

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: add an Add to wishlist button on the Release Detail screen.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Release Detail screen.
- Use the existing Add to wishlist use case.
- Add an Add to wishlist button.
- Save the current release as a local wishlist item.
- Show success feedback after saving.
- Show friendly feedback when the release is already in the wishlist.
- Do not change the Collection feature.
- Do not add Wishlist detail behavior yet.
- Do not edit wishlist items yet.
- Do not remove wishlist items yet.
- Do not add barcode scanning yet.
- Do not add sync logic.
- Do not hardcode secrets.
- Do not log tokens.

Acceptance criteria:
- Release Detail screen has an Add to wishlist button.
- User can save the release to the local wishlist.
- Duplicate save shows a clear friendly message.
- Success save shows a clear friendly message.
- Collection behavior still works.
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