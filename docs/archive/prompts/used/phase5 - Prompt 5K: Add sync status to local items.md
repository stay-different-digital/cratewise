## Prompt 5K: Add sync status to local items

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: add sync status fields to local Collection and Wishlist items.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing sync status model.
* Add sync status to local CollectionItem if not already present.
* Add sync status to local WishlistItem if not already present.
* Set sensible default values for existing and new items.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not change collection editing behavior unless needed for status updates.
* Do not change wishlist editing behavior unless needed for status updates.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* New collection items get a default sync status.
* New wishlist items get a default sync status.
* Existing local records can be read safely.
* Missing sync status should not break old local data.

Acceptance criteria:

* Collection items have sync status.
* Wishlist items have sync status.
* New local records get default sync status.
* Existing local records remain readable.
* No sync UI is added yet.
* No retry behavior is added yet.
* No cloud sync is added.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Data migration or compatibility notes
* Tests/checks run
* Known limitations
* Recommended next small task

---

## Prompt 5L: Show sync status in Collection and Wishlist details

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: show sync status on Collection and Wishlist detail screens.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use existing sync status fields.
* Show sync status on Collection Detail.
* Show sync status on Wishlist Detail.
* Use friendly wording.
* Do not add global sync status yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not change editing behavior.
* Do not hardcode secrets.
* Do not log tokens.

Suggested user-facing wording:

* Saved on this device
* Synced
* Waiting to sync
* Sync failed
* Offline
* Needs review

Acceptance criteria:

* Collection Detail shows sync status.
* Wishlist Detail shows sync status.
* Status wording is friendly.
* Status does not expose technical details.
* No retry action is added yet.
* No cloud sync is added.
* UI works on Android phones, iPhones, and iPads.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* UX wording choices
* Tests/checks run
* Known limitations
* Recommended next small task

---

## Prompt 5M: Add failed action queue model

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: add a failed action queue model for retryable local app actions.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Add a FailedAction or RetryAction model.
* Add a repository interface for retry actions.
* Add local storage for retry actions.
* Do not connect this to UI yet.
* Do not retry actions yet.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not add background processing.
* Do not hardcode secrets.
* Do not log tokens.

Retry action should support:

* Action ID
* Action type
* Related entity type
* Related entity ID
* Safe error message
* Created date
* Last attempted date if available
* Attempt count
* Status

Important security rule:

* Do not store tokens inside retry actions.
* Do not store secrets inside retry actions.
* Do not store raw API headers inside retry actions.

Acceptance criteria:

* Retry action model exists.
* Retry action repository interface exists.
* Local retry action storage exists.
* Retry actions can be saved.
* Retry actions can be loaded.
* Retry actions do not contain tokens or secrets.
* No UI behavior changes.
* No retry execution is added yet.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Main model choices
* Security notes
* Tests/checks run
* Known limitations
* Recommended next small task

---

## Prompt 5N: Record failed cache refresh actions

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: record failed cache refresh actions.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing retry action storage.
* When release metadata refresh from Discogs fails in a retryable way, record a retry action.
* When thumbnail caching fails in a retryable way, record a retry action.
* Do not record tokens.
* Do not record secrets.
* Do not show retry UI yet.
* Do not execute retries yet.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not add background processing.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Store only safe action data.
* Store safe error messages only.
* Avoid duplicate retry actions for the same release and action type where possible.
* Failure to record a retry action should not crash the main flow.

Acceptance criteria:

* Failed metadata refresh can create a retry action.
* Failed thumbnail cache can create a retry action.
* Retry actions do not include tokens.
* Retry actions do not include secrets.
* Duplicate retry actions are reduced where possible.
* No retry UI is added yet.
* No retry execution is added yet.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Security notes
* Tests/checks run
* Known limitations
* Recommended next small task

---

## Prompt 5O: Add retry failed actions screen

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: add a screen to view failed retry actions.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing retry action storage.
* Add a Failed Actions screen or section in Settings.
* Show failed retry actions.
* Show action type, safe message, attempt count, and last attempted date if available.
* Add empty state.
* Do not execute retries yet.
* Do not add background processing.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not expose tokens or secrets.
* Do not hardcode secrets.
* Do not log tokens.

Acceptance criteria:

* User can view failed retry actions.
* Empty state is clear.
* Retry action details use safe wording.
* No token is shown.
* No secret is shown.
* No retry execution is added yet.
* UI works on Android phones, iPhones, and iPads.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* UX choices
* Tests/checks run
* Known limitations
* Recommended next small task

---

## Prompt 5P: Retry failed metadata refresh action

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: retry failed metadata refresh actions manually.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Failed Actions screen.
* Use the existing retry action storage.
* Use the existing Discogs API client.
* Use the existing cached metadata repository.
* Add a Retry button for metadata refresh actions only.
* When retry succeeds, update cached metadata and mark action as resolved.
* When retry fails, update attempt count and last attempted date.
* Do not retry thumbnail actions in this slice.
* Do not add retry all yet.
* Do not add background retry.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not expose tokens or secrets.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Load saved token safely when retry needs Discogs.
* If no token is connected, show friendly message.
* Do not store token in retry action.
* Do not show token in errors.
* Use safe error messages.

Acceptance criteria:

* User can retry a failed metadata refresh action.
* Successful retry updates cached metadata.
* Successful retry marks action as resolved or removes it from failed list.
* Failed retry updates attempt count.
* No token is shown.
* No token is logged.
* Thumbnail retry is not added yet.
* Retry all is not added yet.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Tests/checks run
* Known limitations
* Recommended next small task

---

## Prompt 5Q: Retry failed thumbnail cache action

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: retry failed thumbnail cache actions manually.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Failed Actions screen.
* Use the existing retry action storage.
* Use the existing thumbnail cache service.
* Add a Retry button for thumbnail cache actions only.
* When retry succeeds, cache the thumbnail and mark action as resolved.
* When retry fails, update attempt count and last attempted date.
* Do not change metadata retry behavior.
* Do not add retry all yet.
* Do not add background retry.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not expose tokens or secrets.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Retry should handle missing image URL safely.
* Retry should handle no internet safely.
* Retry should use safe error messages.
* Retry action should not include tokens or secrets.

Acceptance criteria:

* User can retry a failed thumbnail cache action.
* Successful retry caches the thumbnail.
* Successful retry marks action as resolved or removes it from failed list.
* Failed retry updates attempt count.
* No token is shown.
* No token is logged.
* Metadata retry still works.
* Retry all is not added yet.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Tests/checks run
* Known limitations
* Recommended next small task

---

## Prompt 5R: Offline mode final polish

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the final small Phase 5 feature slice for Cratewise: polish offline mode across the app.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Review offline behavior for:

  * Collection list
  * Collection Detail
  * Wishlist list
  * Wishlist Detail
  * Release Detail cached fallback
  * Barcode manual lookup error state
  * Search error state
  * Failed Actions screen
* Improve user-facing wording for offline states.
* Improve placeholders for missing metadata and thumbnails.
* Improve iPad layout where needed.
* Do not add new features.
* Do not add cloud sync.
* Do not add Discogs write-sync.
* Do not add background retry.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Local collection remains usable offline.
* Local wishlist remains usable offline.
* Cached release detail fallback remains clear.
* Missing cached data shows friendly wording.
* Search and barcode lookup explain that internet is required.
* No token or secret appears in errors.

Acceptance criteria:

* App is reliable without internet for local collection data.
* App is reliable without internet for local wishlist data.
* Cached metadata fallback is understandable.
* Missing thumbnails have clean placeholders.
* Failed actions are visible in Settings.
* Offline wording is clear and friendly.
* No new major feature is added.
* Token is not shown.
* Token is not logged.
* UI works on Android phones, iPhones, and iPads.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Tests/checks run
* Known limitations
* Recommended next small task
