## phase4 - Prompt 4L: Connect manual barcode input to lookup

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: connect manual barcode input to the barcode lookup use case.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Barcode Scan screen UI.
- Use the existing barcode lookup use case.
- Connect the manual barcode input to real Discogs barcode lookup.
- Replace fake local result data with real lookup results.
- Show loading, empty, and error states.
- Show no token state.
- Do not use the camera yet.
- Do not request camera permission yet.
- Do not add Android camera behavior yet.
- Do not add iPhone camera behavior yet.
- Do not add iPad camera behavior yet.
- Do not add release detail navigation from barcode results yet.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- User can enter a barcode manually.
- User can press Search barcode.
- App searches Discogs by barcode.
- Results show:
  - Cover thumbnail if available
  - Artist
  - Title
  - Format if available
  - Label if available
  - Year if available
  - Country if available
  - Discogs release ID
- Empty result state is clear.
- No token state tells the user to connect Discogs in Settings.
- API error state is friendly.
- Rate limit state is friendly.

Acceptance criteria:
- Manual barcode lookup works.
- Real Discogs results are shown.
- Loading state works.
- Empty state works.
- Error state works.
- No token state works.
- No camera behavior is added yet.
- Token is not shown.
- Token is not logged.
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