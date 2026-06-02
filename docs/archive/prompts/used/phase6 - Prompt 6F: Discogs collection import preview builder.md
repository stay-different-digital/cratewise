## phase6 - Prompt 6F: Discogs collection import preview builder

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: build a preview for importing collection items from Discogs.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Discogs collection import DTOs.
- Use the existing local collection repository.
- Add a use case that compares Discogs collection items with local collection items.
- Build an import preview result.
- Do not show the preview in UI yet.
- Do not save imported items yet.
- Do not update local collection yet.
- Do not add CSV behavior.
- Do not hardcode secrets.
- Do not log tokens.

Preview should identify:
- New items
- Already existing items
- Items with missing metadata
- Items that cannot be imported safely

Acceptance criteria:
- Collection import preview use case exists.
- Preview detects new items.
- Preview detects duplicate local items by Discogs release ID.
- Preview detects invalid or incomplete items.
- No local collection changes are made.
- No UI behavior changes.
- Token is not logged.
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