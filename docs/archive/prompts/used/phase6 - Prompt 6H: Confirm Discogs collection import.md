## phase6 - Prompt 6H: Confirm Discogs collection import

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 6 feature slice for Cratewise: confirm and save Discogs collection import.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Discogs collection import preview UI.
- Use the existing local collection repository.
- Add confirm import behavior.
- Save only valid new collection items.
- Skip duplicates.
- Skip invalid items.
- Create an import job result.
- Do not overwrite existing local collection items.
- Do not delete local collection items.
- Do not add wishlist import behavior.
- Do not add CSV behavior.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- User can confirm import after preview.
- App saves valid new items locally.
- App shows import summary.
- Summary shows imported, skipped, and failed counts.
- Existing local items stay unchanged.
- Invalid items do not crash the import.

Acceptance criteria:
- User can import collection from Discogs into local collection.
- Duplicate items are skipped.
- Invalid items are skipped safely.
- Import summary is shown.
- Import job result is saved.
- No local items are deleted.
- Token is not logged.
- UI works on Android phones, iPhones, and iPads.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Import rules
- Tests/checks run
- Known limitations
- Recommended next small task