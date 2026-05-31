Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the final small Phase 3 feature slice for Cratewise: polish the offline collection view.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing local collection list.
- Use the existing local collection detail screen.
- Make sure collection list works without internet.
- Make sure collection detail works without internet.
- Add clear offline-friendly empty and error states.
- Improve missing cover image placeholders.
- Improve iPad layout for collection list and detail.
- Do not add Discogs sync.
- Do not refresh data from Discogs.
- Do not add search filters.
- Do not add sorting.
- Do not add wishlist behavior.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Collection list should load from local storage only.
- Collection detail should load from local storage only.
- App should not require a Discogs token to view local collection.
- App should not require internet to view local collection.
- Missing images should use a clean local placeholder.
- Offline wording should be friendly and simple.

Acceptance criteria:
- User can view Collection list without internet.
- User can view Collection detail without internet.
- User does not need a saved Discogs token to view the local collection.
- Missing images show clean placeholders.
- Empty state is clear.
- Error state is clear.
- iPad layout is improved.
- Phone layout still works well.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Tests/checks run
- Known limitations
- Recommended next small task