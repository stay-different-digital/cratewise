## phase3 - Prompt 3G: Collection detail route

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 3 feature slice for Cratewise: add a Collection detail route and placeholder screen.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Collection list screen.
- Add a Collection detail route.
- Allow the user to tap a collection item.
- Open a placeholder Collection Detail screen.
- Pass the local collection item ID to the detail screen.
- Show the local collection item ID on the placeholder screen.
- Do not load collection detail data yet.
- Do not edit collection items yet.
- Do not remove collection items yet.
- Do not add sync logic.
- Do not use the Discogs API in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Acceptance criteria:
- User can tap a collection item.
- App opens a Collection Detail placeholder screen.
- Collection Detail screen receives and shows the local collection item ID.
- No detail data is loaded yet.
- Collection list still works.
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