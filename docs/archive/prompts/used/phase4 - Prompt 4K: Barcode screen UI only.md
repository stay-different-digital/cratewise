## phase4 - Prompt 4K: Barcode screen UI only

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: replace the placeholder Barcode Scan screen with barcode lookup UI only.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Replace the placeholder Barcode Scan screen with a proper barcode lookup layout.
- Add a manual barcode input field.
- Add a placeholder scan area.
- Add a Scan barcode button.
- Add a Search barcode button.
- Show fake local result cards only.
- Add empty state.
- Do not connect to the barcode lookup use case yet.
- Do not use the camera yet.
- Do not request camera permission yet.
- Do not add Android camera behavior yet.
- Do not add iPhone camera behavior yet.
- Do not add iPad camera behavior yet.
- Do not add release detail navigation from barcode results yet.
- Do not hardcode secrets.
- Do not log tokens.

Barcode result cards should show:
- Cover placeholder
- Artist
- Title
- Format if available
- Label if available
- Year if available
- Country if available
- Discogs release ID

Acceptance criteria:
- Barcode Scan screen has a proper layout.
- User can enter a barcode manually.
- Screen shows fake local barcode result cards.
- Screen has a clear empty state.
- No API request is made.
- No camera is used.
- No permission is requested.
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