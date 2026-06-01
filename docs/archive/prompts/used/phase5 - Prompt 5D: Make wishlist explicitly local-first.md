## Prompt 5D: Make wishlist explicitly local-first

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: make the Wishlist explicitly local-first.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing local wishlist repository.
* Make sure Wishlist list loads from local storage only.
* Make sure Wishlist Detail loads from local storage only.
* Make sure Wishlist does not require a Discogs token.
* Make sure Wishlist does not require internet.
* Add clear empty, not found, and error states if needed.
* Do not add metadata caching yet.
* Do not add thumbnail caching yet.
* Do not change wishlist editing.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not call Discogs from Wishlist list or Wishlist Detail.
* Do not hardcode secrets.
* Do not log tokens.

Acceptance criteria:

* Wishlist list works without internet.
* Wishlist Detail works without internet.
* Wishlist works without a saved Discogs token.
* Wishlist reads from local storage only.
* Wishlist does not call the Discogs API.
* Empty state is clear.
* Not found state is clear.
* Error state is clear.
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

---

## Prompt 5E: Add cached release metadata model and storage

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: add local cached release metadata storage.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Add a CachedReleaseMetadata model.
* Add a repository interface for cached release metadata.
* Add a local storage implementation for cached release metadata.
* Do not connect this cache to the Release Detail screen yet.
* Do not connect this cache to Search yet.
* Do not add thumbnail caching yet.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not hardcode secrets.
* Do not log tokens.

Cached metadata should support:

* Discogs release ID
* Artist
* Title
* Label if available
* Catalog number if available
* Format if available
* Country if available
* Year if available
* Genre if available
* Style if available
* Tracklist if available
* Notes if available
* Barcode and identifiers if available
* Cover image URL if available
* Last fetched date
* Cache source
* Sync status if useful

Acceptance criteria:

* CachedReleaseMetadata model exists.
* Cached release metadata repository interface exists.
* Local cache storage implementation exists.
* Cached metadata can be saved.
* Cached metadata can be loaded by Discogs release ID.
* No UI behavior changes.
* No API behavior changes.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Main cache model choices
* Tests/checks run
* Known limitations
* Recommended next small task

---

## Prompt 5F: Cache release metadata after loading release detail

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: save release detail metadata to the local metadata cache after loading from Discogs.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Release Detail screen.
* Use the existing Discogs release detail API method.
* Use the existing cached release metadata repository.
* When release details load successfully from Discogs, save the metadata locally.
* Do not change how release details are displayed yet.
* Do not add offline fallback yet.
* Do not add thumbnail caching yet.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Successful release detail API response is saved to local cache.
* Cache save failure should not break the release detail screen.
* Cache save failure should be handled safely.
* Token must never be cached, shown, or logged.

Acceptance criteria:

* Release metadata is cached after successful detail load.
* Release Detail screen still behaves as before.
* Cache save failure does not crash the app.
* No offline fallback is added yet.
* No token is cached.
* No token is logged.
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

## Prompt 5G: Use cached release metadata as offline fallback

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: use cached release metadata as an offline fallback for the Release Detail screen.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Release Detail screen.
* Use the existing cached release metadata repository.
* If Discogs release detail loading fails, try loading cached metadata.
* Show cached metadata when available.
* Show clear wording that cached data is being shown.
* Do not change Search behavior.
* Do not add thumbnail caching yet.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* If online API load succeeds, show fresh data.
* If online API load fails and cache exists, show cached data.
* If online API load fails and cache does not exist, show friendly error state.
* Cached data should show last fetched date if available.
* Token must never be shown or logged.

Acceptance criteria:

* Release Detail can show cached metadata when offline or API fails.
* Cached fallback is clearly marked.
* No cache available state is clear.
* Fresh API behavior still works.
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

---

## Prompt 5H: Add thumbnail cache abstraction

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: add a thumbnail cache abstraction.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Add a small thumbnail cache service or repository.
* The cache should support saving and reading cover thumbnails where possible.
* The cache should use local app storage.
* Do not connect the thumbnail cache to UI yet.
* Do not download all images in bulk.
* Do not add background sync.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Cache can store a thumbnail by release ID or image URL key.
* Cache can return a local thumbnail path or bytes if available.
* Cache handles failed downloads safely.
* Cache avoids crashing when image URL is missing.
* Cache does not store tokens.
* Cache does not log tokens.

Acceptance criteria:

* Thumbnail cache abstraction exists.
* Thumbnail cache implementation exists.
* Thumbnail can be stored where possible.
* Thumbnail can be loaded where possible.
* Failed thumbnail download is handled safely.
* No UI behavior changes.
* No bulk image download is added.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Main cache choices
* Tests/checks run
* Known limitations
* Recommended next small task

---

## Prompt 5I: Cache thumbnails after viewing release detail

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: cache cover thumbnails after viewing release details.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Release Detail screen.
* Use the existing thumbnail cache service.
* When a release detail has a cover image or thumbnail URL, cache it locally where possible.
* Do not change Collection list images yet.
* Do not change Wishlist images yet.
* Do not add bulk image caching.
* Do not add background sync.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Thumbnail cache runs after successful release detail load.
* Thumbnail cache failure does not break the screen.
* Missing image URL does not break the screen.
* Cache should avoid repeated downloads when already available if possible.

Acceptance criteria:

* Thumbnail is cached after viewing release details where possible.
* Missing image URL is handled safely.
* Failed thumbnail caching does not crash the app.
* Release Detail screen still works as before.
* No Collection list image behavior changes.
* No Wishlist image behavior changes.
* No token is logged.
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

## Prompt 5J: Use cached thumbnails in local collection and wishlist

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: use cached thumbnails in local Collection and Wishlist views.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing thumbnail cache service.
* Use cached thumbnails in Collection list where available.
* Use cached thumbnails in Collection Detail where available.
* Use cached thumbnails in Wishlist list where available.
* Use cached thumbnails in Wishlist Detail where available.
* Show a clean placeholder when no cached thumbnail exists.
* Do not add bulk image downloads.
* Do not add background sync.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not call Discogs from local Collection or Wishlist screens.
* Do not hardcode secrets.
* Do not log tokens.

Acceptance criteria:

* Collection list can show cached thumbnails where available.
* Collection Detail can show cached thumbnails where available.
* Wishlist list can show cached thumbnails where available.
* Wishlist Detail can show cached thumbnails where available.
* Missing cached thumbnails show clean placeholders.
* Collection and Wishlist screens still work offline.
* Collection and Wishlist screens do not call Discogs.
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

---

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
