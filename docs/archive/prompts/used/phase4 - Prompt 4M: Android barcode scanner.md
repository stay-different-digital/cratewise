## phase4 - Prompt 4M: Android barcode scanner

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: add barcode scanning for Android.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Barcode Scan screen.
- Use the existing barcode lookup use case.
- Add camera barcode scanning for Android.
- Request camera permission on Android.
- When a barcode is scanned, fill the barcode input.
- After scanning, trigger barcode lookup.
- Show scanned barcode value.
- Show lookup results using the existing result UI.
- Do not change iPhone camera behavior in this slice.
- Do not change iPad camera behavior in this slice.
- Do not add release detail navigation from barcode results yet.
- Do not add Add to collection from barcode results.
- Do not add Add to wishlist from barcode results.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Android user can tap Scan barcode.
- Android user sees camera scanner.
- App asks for camera permission.
- If permission is denied, show friendly message.
- If scan succeeds, search Discogs by barcode.
- If no result is found, show empty result state.
- If lookup fails, show friendly error state.

Acceptance criteria:
- Android barcode scanning works.
- Camera permission flow works on Android.
- Denied permission shows a friendly message.
- Scanned barcode triggers lookup.
- Manual barcode lookup still works.
- iPhone and iPad behavior are not changed by this slice.
- Token is not shown.
- Token is not logged.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Android permission changes
- Tests/checks run
- Known limitations
- Recommended next small task