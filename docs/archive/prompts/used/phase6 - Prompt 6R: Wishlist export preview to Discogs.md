## phase6 - Prompt 6R: Wishlist export preview to Discogs.md

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: add a preview for exporting local wishlist items to Discogs.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing local wishlist repository.
- Use the existing wishlist export capability check.
- Build an export preview result.
- Show which local wishlist items are eligible for Discogs export.
- Show which items are already linked to Discogs release IDs.
- Show which items cannot be exported.
- Do not write anything to Discogs.
- Do not add export execution yet.
- Do not add collection export changes.
- Do not add CSV behavior.
- Do not hardcode secrets.
- Do not log tokens.

Preview should identify:
- Eligible items
- Items missing Discogs release ID
- Items already marked as synced if applicable
- Items that cannot be exported safely
- Capability status

Acceptance criteria:
- Wishlist export preview use case exists.
- Preview does not write to Discogs.
- Preview identifies eligible and invalid items.
- Preview handles NotSupported capability state.
- No UI behavior changes.
- No token is logged.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Preview rules
- Tests/checks run
- Known limitations
- Recommended next small task