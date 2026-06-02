## phase6 - Prompt 6S: Wishlist export preview UI

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: show wishlist export to Discogs preview in the UI.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Import and Export screen.
- Use the existing wishlist export preview use case.
- Add a preview screen for Export Wishlist to Discogs.
- Show NotSupported state when Discogs export is not available.
- Do not write anything to Discogs.
- Do not add export execution yet.
- Do not add collection export changes.
- Do not add CSV behavior.
- Do not hardcode secrets.
- Do not log tokens.

Preview UI should show:
- Total local wishlist items
- Eligible items
- Invalid items
- Already synced items if available
- Not supported warning if applicable
- Confirm button disabled unless export is supported

Acceptance criteria:
- User can open Export Wishlist to Discogs preview.
- Preview shows eligible, invalid, and synced counts.
- NotSupported state is clear and friendly.
- No write request is made to Discogs.
- Confirm action is disabled when export is not supported.
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