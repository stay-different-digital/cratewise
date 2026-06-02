## phase6 - Prompt 6P: Execute collection export to Discogs only if supported

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: execute collection export to Discogs only when the API capability is supported.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing collection export preview UI.
- Use the existing collection export capability check.
- If export is supported, export eligible collection items to Discogs.
- If export is not supported, show NotSupported and do not call Discogs.
- Update local sync status only after successful export.
- Create an export job result.
- Do not export wishlist items in this slice.
- Do not add CSV behavior.
- Do not use unofficial endpoints.
- Do not scrape Discogs.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Load saved token safely when needed.
- Export only eligible items.
- Skip invalid items.
- Show export summary.
- Summary shows exported, skipped, failed, and not supported counts.
- Failed export should not delete local data.

Acceptance criteria:
- Export only runs when capability is supported.
- NotSupported state prevents write requests.
- Successful export updates local sync status.
- Failed export keeps local data unchanged.
- Export summary is shown.
- Export job result is saved.
- Token is not shown.
- Token is not logged.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Export behavior
- Security notes
- Tests/checks run
- Known limitations
- Recommended next small task