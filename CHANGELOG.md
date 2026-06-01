# Changelog

All notable changes to Cratewise are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased — Phase 4C: wishlist list UI] — 2026-06-01

### Added
- `WishlistItemCard` widget showing cover thumbnail, artist, title, priority badge, label/year/format meta row, and target price
- `_PriorityBadge` with Material 3 container colors per priority level (low → surfaceContainerHighest, medium → tertiaryContainer, high → secondaryContainer, mustHave → primaryContainer)
- `WishlistScreen` replaced with real list UI; accepts optional `items` param (defaults to 3 fake items); shows `_EmptyWishlistState` when items is empty
- 16 new widget tests covering empty state, list rendering, card content, priority labels, meta row variants, target price presence/absence, cover placeholder

---

## [Unreleased — Phase 4B: local wishlist storage] — 2026-06-01

### Added
- `WishlistItems` Drift table (`WishlistRow`) with all fields including `targetPrice` (real, nullable) and `priority` (text via `WishlistPriorityConverter`)
- `WishlistPriorityConverter` type converter in `app_database.dart`
- `LocalWishlistRepository` implementing `WishlistRepository` with `getAll`, `getById`, `containsRelease`, `add`, `update`, `remove`
- 14 integration tests using `NativeDatabase.memory()` covering add/getAll, getById, containsRelease, update, remove, and full optional-field round-trip

### Changed
- `AppDatabase.schemaVersion` bumped to 2; migration creates `wishlist_items` table for existing v1 databases

---

## [Unreleased — Phase 4A: wishlist data model] — 2026-06-01

### Added
- `WishlistItem` domain model with all required fields (`id`, `discogsReleaseId`, `artist`, `title`, `priority`, `createdAt`, `updatedAt`) and optional fields (`label`, `catno`, `format`, `country`, `year`, `coverUrl`, `targetPrice`, `notes`)
- `WishlistPriority` enum with four values: `low`, `medium`, `high`, `mustHave`; each has a human-readable `label`
- `WishlistRepository` abstract interface (`getAll`, `getById`, `containsRelease`, `add`, `update`, `remove`) mirroring `CollectionRepository`
- 8 new unit tests: required fields, optional fields, null defaults, `copyWith` identity / override / immutability, priority count, priority labels

---

## [Unreleased — Phase 3N: offline collection view polish] — 2026-06-01

### Added
- 2-column `GridView` layout for `CollectionScreen` on wide screens (≥700 logical pixels), replacing the single-column `ListView`; narrow screens keep the existing list
- "No cover" text label and `Semantics(label: 'No cover image')` on the full-width cover placeholder in `CollectionDetailScreen`
- `Semantics(label: 'No cover image')` on the 72×72 thumbnail placeholder in `CollectionItemCard` for screen-reader accessibility
- 5 new widget tests: GridView shows at wide breakpoint, all cards present in grid, narrow screen uses list, tapping grid card navigates to detail, wide empty state shows without grid

---

## [Unreleased — Phase 3M: remove collection item] — 2026-06-01

### Added
- `PopupMenuButton` (overflow / three-dot menu) in `CollectionDetailScreen` app bar, visible only in the loaded state, with a single "Remove from Cratewise" action
- `AlertDialog` confirmation before removal; content explicitly states that only the Cratewise collection is affected and Discogs is not
- After successful removal, the app navigates back to the Collection list
- On removal failure, a 'Could not remove item. Please try again.' snackbar appears and navigation does not occur
- 12 new widget tests: button visibility in all states, menu item visible, dialog appears, dialog mentions Discogs, Cancel closes without removing, Remove calls repository.remove, navigates back on success, snackbar on error, stays on screen on error

---

## [Unreleased — Phase 3L: edit storage location] — 2026-06-01

### Added
- Edit storage location icon button (`Icons.inventory_2_outlined`) in the `CollectionDetailScreen` app bar, visible only in the loaded state
- `_EditStorageLocationSheet` modal bottom sheet with a single-line `TextFormField` pre-filled with the current storage location; `onFieldSubmitted` triggers save; saving stores the trimmed text, clears the Location row when empty, and updates `updatedAt: DateTime.now()`
- After a successful save, the screen updates immediately with the new value and shows a 'Storage location saved.' snackbar
- 14 new widget tests: button visibility in all states, sheet opens with title, pre-fill, Save calls update, success snackbar, value + updatedAt updated on screen, clearing hides Location row, error message, sheet stays open on error

---

## [Unreleased — Phase 3K: edit tags] — 2026-06-01

### Added
- Edit tags icon button (`Icons.label_outlined`) in the `CollectionDetailScreen` app bar, visible only in the loaded state
- `_EditTagsSheet` modal bottom sheet showing existing tags as `InputChip` widgets; each chip has a delete icon (`Icons.close`) to remove it; a text field + add button allows adding new tags; duplicate tags are rejected case-insensitively; empty input is ignored
- After a successful save, the screen updates immediately with the new tag list and `updatedAt: DateTime.now()`
- 15 new widget tests: button visibility in all states, sheet open/chips shown, add tag, remove tag, empty/duplicate guards, Save calls update, success snackbar, tags + updatedAt on screen, error message, sheet stays open on error

---

## [Unreleased — Phase 3J: edit notes] — 2026-06-01

### Added
- Edit notes icon button (`Icons.edit_note`) in the `CollectionDetailScreen` app bar, visible only in the loaded state alongside the existing edit conditions button
- `_EditNotesSheet` modal bottom sheet with a multiline `TextFormField` pre-filled with existing notes; includes Save button with loading spinner, inline error message on failure, and snackbar confirmation on success
- After a successful save the screen state updates immediately via `copyWith(notes: ...)` with `updatedAt: DateTime.now()`; saving empty text clears the notes section from the screen
- 14 new widget tests covering: button visibility in all four states, sheet open/content, pre-fill, Save calls `repository.update`, success snackbar, notes update on screen, updatedAt change, clear hides section, error message, sheet stays open on error

---

## [Unreleased — Phase 3I: edit media and sleeve condition] — 2026-06-01

### Added
- `RecordCondition.notSet` enum value (label "Not set", abbreviation "—") stored as the string `"notSet"` in SQLite via the existing `RecordConditionConverter`; safe to add without a DB migration
- Edit icon button (`Icons.edit_outlined`) in the `CollectionDetailScreen` app bar, visible only in the loaded state
- `_EditConditionsSheet` modal bottom sheet with `DropdownButtonFormField` pickers for media condition and sleeve condition; includes Save button with loading spinner, inline error message on failure, and snackbar confirmation on success
- After a successful save the screen state updates immediately (no reload) using `copyWith(updatedAt: DateTime.now())`; the `_EditConditionsSheet` passes the updated `CollectionItem` back to the screen via `Navigator.pop`
- 12 new widget tests covering: edit button visibility in all states, sheet open/content, Save calls `repository.update`, success snackbar, updated date change, error message on failure, sheet stays open on failure, and condition value update after save

### Changed
- `RecordCondition` count updated from 8 to 9 values; domain model tests updated accordingly

---

## [Unreleased — Fix: single AppDatabase instance] — 2026-06-01

### Fixed
- Eliminated Drift "multiple databases" warning that appeared when navigating to `ReleaseDetailScreen` from Search while the Collection tab was open; both screens were independently opening `AppDatabase` against the same SQLite file, risking race-condition corruption on concurrent writes
- `HomeShellScreen` now creates one `AppDatabase`, `LocalCollectionRepository`, and `AddToCollectionUseCase` in `initState()` and disposes the database in `dispose()`; the shared instances are passed down to `CollectionScreen` (via `repository`) and `SearchScreen` (via `addToCollectionUseCase`), which threads it through to `ReleaseDetailScreen`
- `ReleaseDetailScreen` retains its null-fallback (creates own DB when no use case injected) so it continues to work in isolation for tests

---

## [Unreleased — Phase 3 collection detail data] — 2026-05-31

### Added
- `CollectionDetailScreen` now loads the `CollectionItem` from `LocalCollectionRepository.getById()` using the same owned-`AppDatabase` pattern as other screens
- Loading state (`CircularProgressIndicator`), not-found state ("Item not found."), and friendly error state ("Could not load this item.") with Retry button
- Detail body shows: cover image (placeholder when none), artist, title in app bar; info rows for label/catno, format, country, year, media condition, sleeve condition, storage location; Notes section; Tags section (with `Chip` widgets); history section with added/updated dates in ISO format
- Two-column wide layout (≥700dp) via `LayoutBuilder` mirroring `ReleaseDetailScreen`
- `CollectionScreen._CollectionList` passes its `CollectionRepository` down to `CollectionDetailScreen` on navigation — avoids a second database connection and allows fake repos to propagate cleanly in tests
- `_FakeCollectionRepository.getById()` now looks up from `items` list for accurate navigation tests
- 27 new widget tests (loading × 2, loaded × 19, not-found × 2, error × 4, wide × 1) in `collection_detail_screen_test.dart`; updated 2 navigation tests in `collection_screen_test.dart`

---

## [Unreleased — Phase 3 collection detail route] — 2026-05-31

### Added
- `CollectionDetailScreen` placeholder: receives `itemId` and displays it; shows "Collection Item" app bar title
- Tapping a `CollectionItemCard` in the collection list navigates to `CollectionDetailScreen` via `Navigator.push` / `MaterialPageRoute`
- `AppRoutes.collectionDetail` constant added to `router.dart`
- 3 widget tests for `CollectionDetailScreen` and 3 navigation tests in `collection_screen_test.dart` (tap opens detail, correct id passed, back navigation returns to list)

---

## [Unreleased — Phase 3 connect collection list to storage] — 2026-05-31

### Added
- `CollectionScreen` now loads items from `LocalCollectionRepository` on startup
- Loading state with `CircularProgressIndicator` shown while `getAll()` runs
- Error state with "Could not load your collection." message and "Retry" button
- `CollectionScreen` accepts optional `CollectionRepository? repository` parameter for test injection; creates an owned `AppDatabase(openAppDatabase())` + `LocalCollectionRepository` when none is injected and disposes the database in `dispose()`
- 23 widget tests covering loading, empty, list, error, retry, search field, and card field states

### Removed
- Fake hard-coded collection items (`_fakeItems()`) removed from `CollectionScreen`

---

## [Unreleased — Phase 3 collection list UI] — 2026-05-31

### Added
- `CollectionScreen` replaced with a real list layout showing collection item cards and a search field (UI only, no filtering yet)
- `CollectionItemCard` widget: cover thumbnail (placeholder when no URL), artist, title, label · year · format meta row, storage location row with icon
- Empty state with `Icons.album_outlined` and descriptive text when the items list is empty
- Default fake data (Miles Davis, Massive Attack, The Prodigy) displayed when no `items` param is injected
- `CollectionScreen` accepts optional `List<CollectionItem>? items` parameter for test injection
- Search field with clear button (UI only; filtering deferred to next slice)
- 18 new widget tests for collection screen and card behaviour

---

## [Unreleased — Phase 3 add to collection button] — 2026-05-31

### Added
- "Add to Collection" `FilledButton.icon` in a sticky `bottomNavigationBar` on `ReleaseDetailScreen`, visible only when release is loaded
- Button states: idle ("Add to Collection"), adding ("Adding…" / disabled), in-collection ("In Collection" with check / disabled)
- `SnackBar` feedback: "Added to your collection" on success, "Already in your collection" on duplicate
- `ReleaseDetailScreen` accepts optional `AddToCollectionUseCase` parameter; creates a default `LocalCollectionRepository(AppDatabase(openAppDatabase()))` when none is injected; disposes the owned database in `dispose()`
- 8 widget tests for add-to-collection behaviour

---

## [Unreleased — Phase 3 add to collection use case] — 2026-05-31

### Added
- `AddToCollectionUseCase` in `application/use_cases`: converts a `ReleaseDetail` into a `CollectionItem` with default conditions and saves it via `CollectionRepository`
- `AddToCollectionResult` sealed class with `AddToCollectionSuccess(item)` and `AddToCollectionDuplicate` variants
- Duplicate prevention: `containsRelease` checked before inserting; returns `AddToCollectionDuplicate` without writing if the Discogs release ID is already present
- Empty strings from `ReleaseDetail` (label, catno, format, country) mapped to `null` on the stored item
- `uuid: ^4.5.3` added as a dependency for UUID v4 ID generation
- 20 unit tests using a `FakeCollectionRepository` (no SQLite)

---

## [Unreleased — Phase 3 local collection storage] — 2026-05-31

### Added
- Drift 2.33 SQLite database (`AppDatabase`) with `CollectionItems` table; `RecordConditionConverter` and `StringListConverter` type converters
- `LocalCollectionRepository` implementing `CollectionRepository`: `getAll`, `getById`, `containsRelease`, `add`, `update`, `remove`
- `containsRelease(int discogsReleaseId)` added to `CollectionRepository` interface
- `drift`, `sqlite3_flutter_libs`, `path_provider`, `path` added as dependencies; `drift_dev`, `build_runner` as dev dependencies
- 14 repository integration tests using `NativeDatabase.memory()`

---

## [Unreleased — Phase 3 collection data model] — 2026-05-31

### Added
- `CollectionItem` domain model with all vinyl collection fields: local ID, Discogs release ID, artist, title, label, catno, format, country, year, cover URL, media condition, sleeve condition, notes, tags, storage location, created/updated timestamps
- `RecordCondition` enum with all eight standard Discogs vinyl grades (M through P); each grade exposes `.label` and `.abbreviation`
- `CollectionRepository` abstract interface with `getAll`, `getById`, `add`, `update`, `remove`
- 9 unit tests for `CollectionItem` and `RecordCondition`

---

## [Unreleased — Phase 2 release detail states and iPad polish] — 2026-05-31

### Changed

- `ReleaseDetailScreen` loading state replaced `CircularProgressIndicator` with `_SkeletonBody` — a static layout-matched skeleton with placeholder blocks for the cover, title/artist, info rows, and tracklist rows. Key `'release-detail-loading'` on the skeleton root allows test assertions without depending on `CircularProgressIndicator`.
- App bar title now updates to the album title once the detail is loaded; shows `'Release Detail'` during loading and error states.
- Empty title safeguard: `detail.title.isEmpty` falls back to `'(Untitled)'`.
- `_ErrorBody` accepts an optional `onRetry` callback. A `FilledButton('Retry')` appears for all retriable errors (`NetworkError`, `RateLimitedError`, `StorageError`, `DiscogsUnavailableError`, `UnexpectedApiError`). Non-retriable errors (`NoTokenError`, `InvalidTokenError`) show message only.
- `_DetailBody` uses `LayoutBuilder` to switch between narrow (< 700 dp) and wide (≥ 700 dp) layouts. Wide layout: 300 dp left column (cover image with rounded corners, or a placeholder icon when `coverUrl == null`; title, artist, info rows) and an `Expanded` right column (tracklist, notes, identifiers). Uses the same breakpoint (700 dp) as `HomeShellScreen`.
- Extracted reusable sub-widgets: `_TitleArtist`, `_InfoRows`, `_TracklistSection`, `_NotesSection`, `_IdentifiersSection` — shared between narrow and wide layouts.
- Twenty widget tests in `test/presentation/screens/release_detail_screen_test.dart`: skeleton key check replaces `CircularProgressIndicator` check; title assertion updated to `findsWidgets` (title appears in both app bar and body); added group `'retry'` with three tests: retry button visible on network error, retry button absent on no-token error, retry refetches and shows loaded state (via `_FailThenSucceedService`).
- One navigation test in `test/presentation/screens/search_screen_test.dart` updated: assertion changed from `find.byType(CircularProgressIndicator)` to `find.byKey(const Key('release-detail-loading'))`.

---

## [Unreleased — Phase 2 release detail screen] — 2026-05-31

### Added

- `ReleaseDetail`, `ReleaseTrack`, `ReleaseIdentifier` domain models in `lib/domain/models/release_detail.dart`.
- `DiscogsReleaseDetailService` in `lib/application/services/discogs_release_detail_service.dart` — loads the saved token, calls `DiscogsApiClient.fetchRelease`, maps the DTO to `ReleaseDetail`; throws `NoTokenError` when no token is saved; propagates all other `AppError` subtypes unchanged.
- Nine unit tests in `test/application/services/discogs_release_detail_service_test.dart` covering: `NoTokenError` on missing token, `ReleaseDetail` return type on success, all DTO fields mapped correctly, tracklist mapping, identifier mapping, `RateLimitedError`/`InvalidTokenError`/`NetworkError` propagation, and token absence from error messages.

### Changed

- `ReleaseDetailScreen` rewritten from a `StatelessWidget` placeholder to a `StatefulWidget` with a state machine (`_Loading` / `_Loaded` / `_DetailError`). Accepts optional `DiscogsReleaseDetailService` for injection in tests. On `initState`, fetches release details; while loading shows `CircularProgressIndicator`; on error shows icon and friendly mapped message; on success shows scrollable content: cover image (full-width `AspectRatio`, falls back to placeholder on load error), title + artist header, info rows (label, catalog number, format, country, released year, genre, style, Discogs ID), tracklist rows (position, title, duration), optional notes section, optional identifiers section.
- Fifteen widget tests in `test/presentation/screens/release_detail_screen_test.dart` covering: loading indicator, app bar title, release title, artist, label + catno, tracklist tracks, notes, identifiers, cover image widget present/absent, Discogs ID, notes section hidden when null, no-token error, network error, rate-limit error, back button, back navigation.
- Two navigation tests in `test/presentation/screens/search_screen_test.dart` updated: replaced `pumpAndSettle()` with `pump()` + `pump(Duration(milliseconds: 500))` to advance past the navigation animation without triggering `FlutterSecureStorage` platform-channel calls; updated assertion from release-ID text (no longer shown in loading state) to `CircularProgressIndicator`.

---

## [Unreleased — Phase 2 release detail API method] — 2026-05-31

### Added

- `DiscogsReleaseDto` in `lib/infrastructure/discogs/dto/discogs_release.dart` — parses full Discogs release JSON: joins multiple artists with `, `; takes first label name and catalog number; builds format string from name + descriptions; selects primary cover image (falls back to first); parses `year` as `int?`; collects genres and styles as string lists; filters tracklist headings (only `type_ != "heading"` rows kept) into `DiscogsTrackDto` (position, title, duration); parses all identifiers into `DiscogsIdentifierDto` (type, value); nullable `notes` and `coverUrl`.
- `DiscogsApiClient.fetchRelease(int id, String token)` — calls `GET /releases/{id}`; returns `DiscogsReleaseDto`; reuses existing typed error hierarchy; token passed in headers only, never stored or logged.
- Eighteen unit tests added to `test/infrastructure/discogs/discogs_api_client_test.dart` covering: DTO return type, id/title/artist, label/catno, format with descriptions, country/year/genres/styles, notes, cover URL (primary image), tracklist with heading filtering, identifiers, multi-artist joining, secondary-image fallback, missing-field graceful defaults, correct URL path, all four error status codes, network failure, token absence from error messages.

---

## [Unreleased — Phase 2 release detail placeholder] — 2026-05-31

### Added

- `ReleaseDetailScreen` in `lib/presentation/screens/release_detail_screen.dart` — placeholder screen showing the Discogs release ID, an album icon, app bar title "Release Detail", and "Full release details coming soon." text. No API call is made.
- `AppRoutes.releaseDetail = '/release-detail'` constant added to `lib/app/router.dart` for documentation.
- `onTap: VoidCallback?` parameter added to `ReleaseSearchResultCard` — card body wrapped in `InkWell` with `Card(clipBehavior: Clip.antiAlias)` for proper Material ripple clipping.
- Tapping a `ReleaseSearchResultCard` in the search results pushes `ReleaseDetailScreen` via `Navigator.of(context).push(MaterialPageRoute(...))`, passing only the release ID.
- Five widget tests in `test/presentation/screens/release_detail_screen_test.dart`: shows release ID, shows app bar title, shows placeholder message, shows back button when pushed, back button returns to previous screen.
- Two widget tests added to `test/presentation/screens/search_screen_test.dart` (navigation group): tapping result opens detail screen with correct ID, back from detail returns to search results.

---

## [Unreleased — Phase 2 search debounce & dedup] — 2026-05-31

### Changed

- `SearchScreen` now debounces the search input: a `dart:async` `Timer` fires 300 ms after the last keystroke, triggering the search automatically — no keyboard submit required (though pressing the Search key still fires immediately and cancels the pending timer).
- Duplicate requests are suppressed: if the same trimmed query is submitted while a search is already loading or results are already showing, the request is skipped. Retries are allowed when the previous attempt produced an error. Clearing the field resets the deduplication state.
- `_EmptyState` prompt text updated from "Type an artist, album, or label name and press Search." to "Type an artist, album, or label name to search." to match automatic-search behaviour.
- Eight new widget tests in `test/presentation/screens/search_screen_test.dart` covering: debounce does not fire before 300 ms, debounce fires after 300 ms, debounce resets on mid-wait query change, clearing cancels the timer, dedup skips duplicate when results showing, retry allowed after error, fires again after clear-and-retype.
- Two existing tests updated to drain pending debounce timers via `pumpAndSettle` so the test harness exits cleanly.

---

## [Unreleased — Phase 2 live search] — 2026-05-31

### Added

- `NoTokenError` added to `lib/shared/errors/app_error.dart` — thrown when a search is attempted with no saved token.
- `DiscogsSearchService` in `lib/application/services/discogs_search_service.dart` — loads the saved token from `TokenStorage`, calls `DiscogsApiClient.searchReleases`, maps `DiscogsSearchResultDto` to `ReleaseSearchResult`; throws `NoTokenError` when no token is saved; propagates all other `AppError` subtypes unchanged.
- Eight unit tests in `test/application/services/discogs_search_service_test.dart` covering: `NoTokenError` on missing token, successful result mapping (all fields), empty results, `RateLimitedError`/`InvalidTokenError`/`NetworkError` propagation, and token-not-in-error check.
- `Image.network` cover thumbnail support in `ReleaseSearchResultCard` — displays the cover image when `coverUrl` is non-null, falls back to the `Icons.album` placeholder on load error.

### Changed

- `SearchScreen` rewritten with a state machine (`_Idle` / `_Loading` / `_Results` / `_SearchError`); accepts optional `DiscogsSearchService`; search is triggered by pressing the keyboard Search action (`TextInputAction.search`), not on every keystroke; displays a `CircularProgressIndicator` while loading; shows a no-results state when the API returns zero items; shows typed error messages for `NoTokenError`, `InvalidTokenError`, `RateLimitedError`, `NetworkError`, `StorageError`, and unreachable-Discogs cases; clears back to empty state when the field is cleared; fake placeholder data removed.
- `test/presentation/screens/search_screen_test.dart` rewritten (25 tests) — empty state, pre-submit idle state, loading indicator, result cards for all fields, no-results, no-token, network error, rate-limit, invalid-token, clear button behaviour, and security check (token not visible in any rendered Text widget).

---

## [Unreleased — Phase 2 search API method] — 2026-05-31

### Added

- `DiscogsSearchResultDto` in `lib/infrastructure/discogs/dto/discogs_search_result.dart` — parses a single Discogs search result from JSON: splits the API's combined `"Artist - Title"` field into separate `artist` and `title`, takes the first entry from the `format` and `label` arrays, parses `year` from string to `int?`, normalises an empty `thumb` string to `null`.
- `DiscogsApiClient.searchReleases(query, token)` — calls `GET /database/search?q=…&type=release`; returns `List<DiscogsSearchResultDto>`; reuses the existing typed error hierarchy (`InvalidTokenError`, `RateLimitedError`, `DiscogsUnavailableError`, `NetworkError`); token is passed in headers only and never stored or logged.
- Twelve unit tests added to `test/infrastructure/discogs/discogs_api_client_test.dart` covering: happy-path field parsing (artist, title, format, label, year, country, id, thumbUrl), empty-thumb normalisation, missing-field graceful handling, empty results list, URL query-parameter encoding, all four error status codes, network failure, and token absence from errors.

---

## [Unreleased — Phase 2 search UI] — 2026-05-31

### Added

- `ReleaseSearchResult` model in `lib/domain/models/release_search_result.dart` — `id`, `title`, `artist`, `format`, `label`, `country`, nullable `year`, nullable `coverUrl`.
- `ReleaseSearchResultCard` widget in `lib/presentation/widgets/release_search_result_card.dart` — horizontal card showing cover placeholder (72×72 `Icons.album`), artist, title, format · label, year · country, and `#id`.
- `SearchScreen` replaced — pill-shaped search `TextField` with prefix search icon and clear button; empty state (large search icon + "Search Discogs" heading + prompt text) shown when query is empty; scrollable `ListView` of `ReleaseSearchResultCard` widgets shown when query is non-empty.
- Five hardcoded placeholder releases (Miles Davis, The Beatles, Daft Punk, Amy Winehouse, Boards of Canada) displayed for any non-empty query — no API call, no token used.
- Twelve widget tests in `test/presentation/screens/search_screen_test.dart` covering empty state content, results on query entry, each card field (artist, title, format/label, year/country, release ID, cover icon), clear button behaviour.

---

## [Unreleased — Phase 2 iOS Keychain diagnostics] — 2026-05-31

### Changed

- `DiscogsTokenStorage.saveCredentials` — temporary `dart:developer` debug log added to surface the raw iOS Keychain error code (`PlatformException` code + message, no token value) while investigating a Keychain write failure on iOS. To be removed once root cause is confirmed and fixed.

---

## [Unreleased — Phase 2 secure token storage] — 2026-05-31

### Added

- `flutter_secure_storage: ^9.2.4` added to `pubspec.yaml`; CocoaPods required for iOS (installed via Homebrew).
- `StorageError` added to `lib/shared/errors/app_error.dart` — typed error for keychain/keystore failures.
- `ConnectionStatus` model in `lib/domain/models/connection_status.dart` — `isConnected` + nullable `username`.
- `TokenStorage` abstract interface in `lib/domain/repositories/token_storage.dart` — `loadToken`, `loadUsername`, `saveCredentials`, `deleteCredentials`.
- `DiscogsTokenStorage` in `lib/infrastructure/secure_storage/discogs_token_storage.dart` — wraps `FlutterSecureStorage` using keys `discogs_token` and `discogs_username`; all platform exceptions converted to `StorageError`; token never logged.
- `DiscogsConnectionService` in `lib/application/services/discogs_connection_service.dart` — coordinates `TokenValidationService` + `TokenStorage`: `loadStatus()` (degrades gracefully on storage failure), `connect(token)` (validate then save), `disconnect()` (delete credentials).
- `DiscogsTokenSection` now accepts optional `DiscogsConnectionService`; on `initState` loads saved connection status; on successful validation saves credentials and transitions to connected state; connected state shows masked token display (`••••••••••••••••`) and "Connected as @username" with a Disconnect button; Disconnect transitions back to idle and clears credentials.
- Ten new tests in `test/presentation/widgets/discogs_token_section_test.dart` (replacing the previous 8 validation tests): loading indicator, connected state with masked token, each error path (401/403, 429, network, storage), button disabled during load, disconnect returns to idle, connected state on startup from saved credentials, token absent from rendered Text widgets.
- Nine unit tests in `test/application/services/discogs_connection_service_test.dart` covering all `loadStatus`/`connect`/`disconnect` paths including storage failures and token-in-error-message absence check.

---

## [Unreleased — Phase 2 token validation UI] — 2026-05-31

### Added

- `TokenValidationService` in `lib/application/services/token_validation_service.dart` — wraps `DiscogsApiClient.fetchIdentity`; keeps API calls out of the widget layer.
- `_ValidationStatus` enum (`idle`, `loading`, `success`, `failure`) and async `_validate()` method in `DiscogsTokenSection` — calls the service, guards with `!mounted` after await, maps each `AppError` subtype to a user-friendly message.
- Loading indicator (`CircularProgressIndicator` + "Validating…" label) shown while the request is in flight.
- Success row ("Connected as @username") shown on 200 response.
- Error row with friendly message for each failure case: `InvalidTokenError` → "Token not recognised…", `RateLimitedError` → "Too many requests…", `NetworkError` → "No internet connection…", other `AppError` → "Could not reach Discogs…".
- Validate and Remove buttons both disabled while loading.
- Remove clears validation status in addition to clearing the text field.
- Eight new widget tests: loading indicator, success message with username, each error path (401, 429, network), button disabled during load, status clears on Remove, and token value absent from all rendered `Text` widgets.

---

## [Unreleased — Phase 2 Discogs API client] — 2026-05-31

### Added

- `DiscogsApiClient` in `lib/infrastructure/discogs/discogs_api_client.dart` — injectable `http.Client`, `fetchIdentity(token)` method targeting `/oauth/identity`, correct `User-Agent` and `Authorization` headers, no token persisted or logged.
- `DiscogsIdentity` DTO in `lib/infrastructure/discogs/dto/discogs_identity.dart` — `username` and `resourceUrl` fields parsed from JSON.
- Typed error hierarchy in `lib/shared/errors/app_error.dart` — sealed `AppError` base with `InvalidTokenError` (401/403), `RateLimitedError` (429), `DiscogsUnavailableError` (5xx), `NetworkError` (socket/transport), and `UnexpectedApiError(statusCode)`.
- `http: ^1.6.0` added to `pubspec.yaml`.
- Eight unit tests covering: 200 identity parse, 401/403 → `InvalidTokenError`, 429 → `RateLimitedError`, 500 → `DiscogsUnavailableError`, transport exception → `NetworkError`, correct request headers, and token absence from error messages.

---

## [Unreleased]

### Added

- `AppBottomNav` widget — Material 3 `NavigationBar` with five destinations (Search, Collection, Wishlist, Scan, Settings) for phone layouts.
- `AppNavRail` widget — `NavigationRail` with the same five destinations for wider iPad layouts.
- Placeholder screens for Search, Collection, Wishlist, Barcode Scan, and Settings, each showing a centred icon and description text.
- `AppRoutes` constants in `router.dart` (`/search`, `/collection`, `/wishlist`, `/barcode-scan`, `/settings`).
- Five widget tests covering app title, wide/narrow layout selection, all-tab reachability, and tab switching.

### Changed

- `HomeShellScreen` rewritten as a `StatefulWidget` navigation shell using `IndexedStack`. Phones (< 700 logical pixels) get a bottom `NavigationBar`; wider screens get a `NavigationRail` in a `Row` layout.
- `SettingsScreen` replaced static placeholder with a scrollable `ListView` containing the Discogs connection section.
- Nav reachability test updated to assert on Discogs section heading instead of the removed placeholder text.

---

## [Unreleased — Phase 2 token input UI] — 2026-05-31

### Added

- `DiscogsTokenSection` widget — masked `TextField` for a Discogs personal access token with a show/hide `IconButton`, helper text pointing to `discogs.com/settings/developers`, and "Validate token" / "Remove token" buttons that are disabled while the field is empty.
- "Remove token" clears the in-memory field (UI state only; no storage in this slice).
- `autocorrect: false` and `enableSuggestions: false` on the token field keep the value out of keyboard suggestion history.
- `TextEditingController` is disposed correctly in `State.dispose`.
- Seven widget tests covering: token masked by default, show/hide toggle (both directions), help URL text present, buttons disabled when field is empty, buttons enabled with text, and Remove clearing the field.

---

## [0.0.2] — 2026-05-31

### Added

- Full Flutter project scaffolding for Android and iOS/iPadOS.
- `lib/app/app.dart` — `CratewiseApp` root widget with `MaterialApp`, light/dark theme, and `HomeShellScreen` as home.
- `lib/app/router.dart` — initial `buildHomeRoute` helper.
- `lib/app/theme.dart` — Material 3 `ColorScheme` seeded from the Cratewise brand colour.
- `lib/main.dart` — app entry point.
- Initial `HomeShellScreen` with a wide/narrow layout using `LayoutBuilder` and `NavigationRail` placeholder (three destinations).
- Layered folder structure under `lib/` — `application/`, `domain/`, `infrastructure/`, `presentation/`, `shared/` — with `.gitkeep` placeholders.
- Figma reference link for the Airbnb UI Kit added to the design system doc.
- `pubspec.yaml` with Flutter SDK constraint `^3.12.0` and `flutter_lints`.
- Basic CI workflow (`.github/workflows/flutter-ci.yml`).
- `.env.example` with placeholder keys.

---

## [0.0.1] — 2026-05-31

### Added

- `AGENTS.md` — project context, main product goals, development principles, security rules, branding rules, and agent workflow guide.
- `docs/product/PROJECT_BRIEF.md` — app name, target users, MVP scope, and out-of-scope items.
- `docs/product/ROADMAP.md` — nine-phase roadmap from technical foundation through version 1.0 and growth.
- `docs/architecture/ARCHITECTURE.md` — layered folder structure, dependency rules, recommended packages, core data models, error types, and testing priorities.
- `docs/architecture/ADR-0001-use-flutter.md` — decision record for Flutter as the cross-platform framework.
- `docs/architecture/ADR-0002-use-current-token-first.md` — decision record for Discogs personal token as the initial auth strategy.
- `docs/design/DESIGN_SYSTEM.md` — design direction, UI principles, core screens list, accessibility requirements, and Figma references.
- `docs/api/DISCOGS_API.md` — Discogs API notes and usage guidelines.
- `docs/security/SECURITY.md` — token handling rules, secure storage requirements, error message policy, and production login guidance.
- `docs/workflow/AGENT_WORKFLOW.md` — recommended step-by-step agent workflow for planning, implementing, reviewing, and updating docs.
- `docs/workflow/VSCODE_SETUP.md` — VS Code agent mode setup instructions.
- `.github/agents/` — six VS Code agent definitions (Product Planner, Flutter Architect, Flutter Implementer, QA Reviewer, Security Reviewer, UI Designer).
- `.github/prompts/` — reusable prompt files for common tasks (plan feature, implement feature, code review, prepare PR, update docs, start project).
- `.github/skills/` — skill definitions for Airbnb UI Flutter, Discogs API, Flutter features, Flutter testing, local-first data, release checklist, and secure token storage.
- `.vscode/` — workspace settings, recommended extensions, launch configs, and task definitions.
