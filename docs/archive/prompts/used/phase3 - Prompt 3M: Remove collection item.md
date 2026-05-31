Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 3 feature slice for Cratewise: allow removing a collection item from the local collection.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Use the existing Collection Detail screen.
- Use the existing local collection repository.
- Add a remove action for the current collection item.
- Ask for confirmation before removing.
- Remove the item from local storage.
- Navigate back to the Collection list after successful removal.
- Show friendly error feedback if removing fails.
- Do not remove anything from Discogs.
- Do not add sync logic.
- Do not edit collection fields in this slice.
- Do not hardcode secrets.
- Do not log tokens.

Functional requirements:
- Confirmation text should make clear this removes the item only from Cratewise.
- User can cancel the remove action.
- User can confirm the remove action.
- After remove, the item no longer appears in the Collection list.

Acceptance criteria:
- User can remove a local collection item.
- User sees a confirmation before removal.
- User can cancel removal.
- Removed item disappears from the Collection list.
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