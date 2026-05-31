## Prompt 3D: Add to collection button

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 3 feature slice for Cratewise: add an Add to collection button on the Release Detail screen.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Release Detail screen.
- Use the existing Add to collection use case.
- Add an Add to collection button.
- Save the current release as a local collection item.
- Show success feedback after saving.
- Show friendly feedback when the release is already in the collection.
- Do not add Collection list changes yet.
- Do not edit collection items yet.
- Do not remove collection items yet.
- Do not add wishlist behavior.
- Do not add sync logic.
- Do not hardcode secrets.
- Do not log tokens.

Acceptance criteria:
- Release Detail screen has an Add to collection button.
- User can save the release to the local collection.
- Duplicate save shows a clear friendly message.
- Success save shows a clear friendly message.
- No Collection list behavior is changed yet.
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