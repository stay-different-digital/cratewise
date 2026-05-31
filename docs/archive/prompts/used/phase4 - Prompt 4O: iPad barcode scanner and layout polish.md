## phase4 - Prompt 4O: iPad barcode scanner and layout polish

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the final small Phase 4 feature slice for Cratewise: improve barcode scanning and layout for iPad.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Barcode Scan screen.
- Use the existing barcode lookup use case.
- Keep existing Android barcode scanning working.
- Keep existing iPhone barcode scanning working.
- Add or polish camera barcode scanning for iPad.
- Improve Barcode Scan screen layout for wider iPad screens.
- Keep mobile-first layout on Android phones and iPhones.
- Do not add release detail navigation from barcode results yet.
- Do not add Add to collection from barcode results.
- Do not add Add to wishlist from barcode results.
- Do not add CSV features.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- iPad user can tap Scan barcode.
- iPad user sees a scanner layout that uses the larger screen well.
- Manual barcode input remains visible or easy to access.
- Scan results remain readable on iPad.
- Empty, loading, and error states look good on iPad.
- Permission denied state is clear.
- Phone layouts still work well.

Acceptance criteria:
- iPad barcode scanning works.
- iPad layout is improved.
- Android barcode scanning still works.
- iPhone barcode scanning still works.
- Manual barcode lookup still works.
- Loading state works.
- Empty state works.
- Error state works.
- Token is not shown.
- Token is not logged.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- iPad layout choices
- Tests/checks run
- Known limitations
- Recommended next small task