## phase1

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the first small Phase 1 feature slice for Cratewise: create a basic app navigation foundation for Android, iPhone, and iPad.

Scope:
- Keep the existing Flutter app runnable.
- Add a simple route structure under lib/app/.
- Add placeholder screens for Search, Collection, Wishlist, Barcode Scan, and Settings.
- Use a mobile-first layout with bottom navigation on phones.
- Use a NavigationRail layout on wider iPad screens.
- Keep UI, app shell, and screen widgets separated.
- Do not add Discogs API integration yet.
- Do not add token storage yet.
- Do not hardcode secrets.

Acceptance criteria:
- App starts on Android and iOS.
- User can switch between all placeholder sections.
- Wider iPad layout uses rail navigation instead of bottom navigation.
- App title and wording say Cratewise, not Discogs as a brand.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Tests/checks run
- Known limitations
- Recommended next small task