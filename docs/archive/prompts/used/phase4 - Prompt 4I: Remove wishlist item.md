## phase4 - Prompt 4I: Remove wishlist item

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 4 feature slice for Cratewise: allow removing a wishlist item from the local wishlist.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Wishlist Detail screen.
- Use the existing local wishlist repository.
- Add a remove action for the current wishlist item.
- Ask for confirmation before removing.
- Remove the item from local storage.
- Navigate back to the Wishlist list after successful removal.
- Show friendly error feedback if removing fails.
- Do not remove anything from Discogs.
- Do not add barcode scanning yet.
- Do not add sync logic.
- Do not edit wishlist fields in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Confirmation text should make clear this removes the item only from Cratewise.
- User can cancel the remove action.
- User can confirm the remove action.
- After remove, the item no longer appears in the Wishlist list.

Acceptance criteria:
- User can remove a local wishlist item.
- User sees a confirmation before removal.
- User can cancel removal.
- Removed item disappears from the Wishlist list.
- App does not call Discogs to remove anything.
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