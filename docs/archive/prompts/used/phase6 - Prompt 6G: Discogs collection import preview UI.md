## phase6 - Prompt 6G: Discogs collection import preview UI

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: show Discogs collection import preview in the UI.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Import and Export screen.
- Use the existing Discogs collection import API method.
- Use the existing collection import preview use case.
- Add a preview screen for Import Collection from Discogs.
- Do not save imported items yet.
- Do not update local collection yet.
- Do not add CSV behavior.
- Do not add wishlist import behavior.
- Do not hardcode secrets.
- Do not log tokens.

Preview UI should show:
- Total items found
- New items
- Duplicates
- Invalid items
- Safe warning messages
- Confirm button disabled or placeholder only

Acceptance criteria:
- User can start Import Collection from Discogs preview.
- Preview loads Discogs collection data.
- Preview shows new, duplicate, and invalid counts.
- Preview does not import anything yet.
- Loading state works.
- Error state works.
- No token state works.
- Rate limit state works.
- Token is not shown.
- Token is not logged.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- UX choices
- Tests/checks run
- Known limitations
- Recommended next small task