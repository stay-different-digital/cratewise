## phase6 - Prompt 6M: Discogs collection export capability check

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add a capability check for exporting local collection items to Discogs.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Add a use case that checks whether the app can safely export collection items to Discogs.
- Check existing Discogs API client capabilities.
- Check project docs for supported endpoints.
- If export to Discogs is not supported yet, return a clear NotSupported result.
- Do not write anything to Discogs yet.
- Do not add export preview yet.
- Do not add collection export API method yet unless the endpoint is already clearly supported.
- Do not add wishlist export behavior.
- Do not add CSV behavior.
- Do not hardcode secrets.
- Do not log tokens.

Important:
- Do not invent Discogs write endpoints.
- Do not use unofficial endpoints.
- Do not scrape Discogs.
- If support is uncertain, return NotSupported.

Acceptance criteria:
- Collection export capability use case exists.
- Use case returns supported or not supported.
- NotSupported includes friendly safe wording.
- No write request is made to Discogs.
- No local data changes.
- Token is not logged.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Capability decision
- Tests/checks run
- Known limitations
- Recommended next small task