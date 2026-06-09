# Changelog

All notable changes to Cratewise are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased — Phase 8N: Cached release detail banner shows data age (US-41)] — 2026-06-09

### Changed
- `_CachedBanner` — computes `_isStale` (`fetchedAt` is ≥ 30 days ago); when stale switches from `secondaryContainer`/`onSecondaryContainer` to `errorContainer`/`onErrorContainer` and replaces the `offline_pin_outlined` icon with `warning_amber_rounded` (keyed `cached-banner-stale`) so users get a prominent visual signal that offline data is dated; text already wraps naturally via `Expanded` — no truncation possible
- 30-day threshold is a named constant (`_CachedBanner._kStaleDays = 30`)

### Tests
- 2 new tests in `release_detail_screen_test.dart` (`cached banner data age` group):
  - banner does not show stale indicator for data within 30 days (`_freshCachedKindOfBlue` fixture, 1-day-old cache)
  - banner shows stale indicator for data older than 30 days (existing `_cachedKindOfBlue` fixture, Jan 2026 = ~145 days old)

---

## [Unreleased — Phase 8M: Camera scan area has flashlight toggle (US-40)] — 2026-06-09

### Changed
- `_CameraScanArea` converted from `StatelessWidget` to `StatefulWidget` (`_CameraScanAreaState`) so it can own and manage a `MobileScannerController`
- `MobileScannerController` is created in `initState` and disposed in `dispose()` — disposal stops the camera and turns the torch off automatically
- `_CameraScanAreaState` listens to the controller (`ValueNotifier<MobileScannerState>`) via `addListener`; calls `setState` on each change so the torch button icon updates reactively

### Added
- `_TorchToggleButton` widget — an `IconButton` with a semi-transparent (`Colors.black54`) background, `Icons.flash_on` / `Icons.flash_off` icon, and yellow / white foreground colour reflecting the current `TorchState`; keyed `torch-toggle-button`
- Torch button overlaid on the camera view (`Align(Alignment.topRight)` within the existing `Stack`) and shown only when `torchState != TorchState.unavailable` (hidden gracefully on devices without a torch)

### Tests
- 2 new tests in `barcode_scan_screen_test.dart` (`torch toggle` group):
  - torch toggle button absent in the initial placeholder state
  - torch toggle button remains absent after scan button tap on non-scanner platform (macOS/Linux test environment)

---

## [Unreleased — Phase 8L: Barcode scanner uses wide two-panel layout on iPad (US-39)] — 2026-06-09

### Changed
- `_buildWide` left panel changed from `SizedBox(width: 360)` to `Expanded(flex: 2)`, giving a proportional 40% of available width (vs the old fixed 360 dp); right results panel changed from `Expanded` (flex: 1) to `Expanded(flex: 3)` for a 40/60 split that scales with the iPad screen width in both portrait and landscape
- `_onBarcodeDetected` — in wide layout the camera scan area stays active after a barcode is detected (no longer resets to placeholder); in narrow layout the existing dismiss-to-placeholder behaviour is unchanged
- `build` — `LayoutBuilder.builder` now writes `_isWide` before selecting the layout so `_onBarcodeDetected` always reads the current state

### Tests
- 4 new tests in `barcode_scan_screen_test.dart` (`wide layout` group):
  - `VerticalDivider` present at ≥ 700 dp viewport; absent at < 700 dp viewport
  - left scan panel width grows with viewport (proportional layout confirmed at 800 dp vs 1000 dp)
  - scan area placeholder and result cards both visible simultaneously after a search in wide layout

---

## [Unreleased — Phase 8K: Manual barcode entry validates the format before searching (US-38)] — 2026-06-09

### Added
- `_validateBarcode(String trimmed)` static method in `_BarcodeScanScreenState` — returns `null` for blank or valid EAN/UPC input (8, 12, or 13 numeric digits), `"This doesn't look like a barcode"` for non-numeric input (QR codes, alphanumeric), and `'Barcode must be 8, 12, or 13 digits'` for numeric input of the wrong length
- `_canSearch` getter — `true` only when the trimmed field is non-empty and `_validationError` is null; drives the Search button's `onPressed`
- `_onInputChanged()` controller listener registered in `initState` — calls `setState(() => _validationError = _validateBarcode(...))` on every text change, so validation and button state update in real time

### Changed
- `_BarcodeScanScreenState.initState` — adds `_controller.addListener(_onInputChanged)` to wire up real-time validation
- `_BarcodeScanScreenState.dispose` — removes the listener before disposing the controller
- `_onSearch()` — early-returns if `_validationError != null`, guarding the keyboard-submit path as well as the button path
- Both `TextField` decorations (narrow and wide layouts) — changed from `const InputDecoration` to `InputDecoration` with `errorText: _validationError`, displaying the inline validation message below the field
- Both Search `FilledButton.onPressed` — changed from `_onSearch` to `_canSearch ? _onSearch : null`; button is visually disabled while input is invalid

### Tests
- 11 new tests in `barcode_scan_screen_test.dart` (`barcode validation` group):
  - button disabled for empty input; enabled for valid 13-, 12-, and 8-digit barcodes; disabled for non-numeric and wrong-length input
  - non-numeric input shows `"This doesn't look like a barcode"` error message
  - wrong-length numeric input shows `'Barcode must be 8, 12, or 13 digits'` error message
  - keyboard submit with invalid input fires no search
  - validation error clears when a valid barcode is entered; blank input shows no error
- 4 existing tests updated: `'1234567890'` (10-digit, now invalid) replaced with `'5099706035422'` (valid EAN-13) to remain compatible with the new validation rules
- 12 existing tests updated: `await tester.pump()` added between `enterText` and `tap(search-barcode-button)` — required so the `setState` from the controller listener is processed before the button's `onPressed` is read

---

## [Unreleased — Phase 8J: Barcode scan area shows a viewfinder frame (US-37)] — 2026-06-08

### Added
- `_ViewfinderOverlay` widget — `CustomPaint` with key `'viewfinder-overlay'` placed in a `Stack` above the `MobileScanner` inside `_CameraScanArea`
- `_ViewfinderPainter` (`CustomPainter`) — draws four L-shaped bracket corners (white, 90% opacity, 24 dp arms, 3 dp stroke) inset 15% from each edge of the scan area; `shouldRepaint` always returns false (static drawing)
- The overlay uses `Stack(fit: StackFit.expand)` so it fills the full camera container and adapts automatically to both the 160 dp phone height and the 280 dp iPad height; no separate sizing logic needed

### Tests
- 2 new tests in `barcode_scan_screen_test.dart` (`viewfinder overlay` group):
  - `'viewfinder overlay is absent in initial placeholder state'` — verifies the `'viewfinder-overlay'` key is not present when the screen shows the placeholder (guards against overlay leaking to wrong states)
  - `'viewfinder overlay remains absent after scan button tap on non-scanner platform'` — verifies the placeholder is still shown and no overlay appears after tapping Scan on macOS/Linux where `_supportsScanner` is false

---

## [Unreleased — Phase 8I: Dates displayed in the device's locale format (US-36)] — 2026-06-08

### Added
- `intl: ^0.20.0` dependency (resolves to 0.20.2)
- `lib/shared/utils/date_format_utils.dart` — two top-level utility functions: `formatDate(DateTime, Locale)` (date-only, `yMMMd` skeleton) and `formatDateTime(DateTime, Locale)` (date + locale-aware short time, `yMMMd + jm` combined)

### Changed
- `CollectionDetailScreen` (`_HistorySection`) — "Added" and "Updated" rows now use `formatDate(dt, Localizations.localeOf(context))` instead of the hardcoded `YYYY-MM-DD` formatter; output for en_US: `"Jan 5, 2026"`
- `WishlistDetailScreen` (`_HistorySection`) — same change; "Added" and "Updated" rows are now locale-aware
- `FailedActionsScreen` (`_ActionCardState`) — "Last tried" and "Queued" rows now use `formatDateTime(dt, locale)` instead of the hardcoded `"d MMM y, HH:mm"` formatter; output for en_US: `"Jun 1, 2026, 2:30 PM"`
- `ReleaseDetailScreen` (`_CachedBanner`) — "last updated" date in the offline cached-data banner now uses `formatDate(dt, locale)` instead of the hardcoded `"d MMM y"` formatter
- `ImportExportHistoryScreen` (`_JobCard`) — "Started" row now uses `formatDateTime(dt, locale)` instead of the hardcoded `"d MMM y, HH:mm"` formatter
- All hardcoded month-name arrays (`'Jan'`, `'Feb'`, …, `'Dec'`) and manual zero-padding removed from all five screens

### Tests
- 8 new tests in `test/shared/utils/date_format_utils_test.dart`: `formatDate` produces `yMMMd` output, contains expected month/day/year, is not ISO-8601, converts UTC to local; `formatDateTime` includes date and time, uses AM/PM in en_US, contains comma separator, matches expected `yMMMd + jm` composition
- 10 existing test assertions updated from old format strings (`'2026-01-05'`, `'15 Jan 2026'`, `'1 Jun 2026, 14:30'`) to locale-aware equivalents (`'Jan 5, 2026'`, `'Jan 15, 2026'`, `find.textContaining('Jun 1, 2026')`)

---

## [Unreleased — Phase 8H: Collection detail live-reloads when the item is changed (US-35)] — 2026-06-05

### Changed
- `CollectionDetailScreen` now mixes in `RouteAware` and subscribes to `appRouteObserver` (already attached to the Collection branch navigator in `router.dart`)
- On `didPopNext()` (fired when any route above the detail screen — including edit sheets — is popped), the screen silently re-fetches the item from local storage via the existing `_refresh()` method
- Silent re-fetch: existing content remains visible during the fetch; no full-screen loading spinner
- If the item has been removed since the detail was opened, the screen transitions to the `_NotFound` state
- No change to the existing edit-and-save flow (sheet handlers continue to update state immediately and show snackbars)

### Tests
- 1 new fake `_ThenRemovedCollectionRepository` in `collection_detail_screen_test.dart`
- 2 new tests in `collection_detail_screen_test.dart` (`live-reload on route pop` group): silent re-fetch reflects updated item; silent re-fetch transitions to not-found if item removed; both tests use `_wrapWithObserver` which wires `appRouteObserver` into the test navigator

---

## [Unreleased — Phase 8G: Retry button uses back-off delay after rate-limit errors (US-34)] — 2026-06-05

### Added
- `lib/presentation/widgets/rate_limit_retry_button.dart` — `RateLimitRetryButton` StatefulWidget: shows a disabled "Retry in X s" countdown (60 s default) when `isRateLimited` is true; becomes active once the window elapses; immediately active for non-rate-limit errors

### Changed
- Release Detail `_ErrorBody` — Retry button replaced with `RateLimitRetryButton`; rate-limit errors now show a countdown and are disabled until the window elapses
- Search `_SearchErrorState` — added `onRetry` callback and `RateLimitRetryButton`; non-retriable errors (no-token, invalid-token) show no retry button; rate-limit errors show countdown; other errors show an immediately-active Retry button
- Search pagination footer (`_ResultsList._buildFooter`) — rate-limit pagination error now shows a disabled "Retry in X s" countdown (TextButton.icon style); becomes active once the window elapses; previously showed "Rate limited — tap to retry" with no countdown

### Tests
- 4 new tests in `rate_limit_retry_button_test.dart`: active immediately when not rate-limited; disabled countdown when rate-limited; countdown decrements each second; button active and tappable after countdown
- 1 new test in `release_detail_screen_test.dart`: `shows countdown on Retry button when error is rate limit`
- 2 new tests in `search_screen_test.dart`: `shows countdown Retry button when search returns rate limit error`; `shows active Retry button when search returns non-rate-limit error`
- Updated `search_screen_test.dart`: pagination rate-limit test renamed + text assertion updated to check for `'Retry in'` countdown; uses `pump()` instead of `pumpAndSettle()` to avoid advancing 60 s of fake time

---

## [Unreleased — Phase 8F: Multi-format releases show all format entries (US-33)] — 2026-06-05

### Changed
- `DiscogsReleaseDto.fromJson` — format now built from all entries in the `formats` array (previously only the first); each entry is `name + descriptions` joined with `, `; multiple entries are joined with `\n`
- `DiscogsCollectionItemDto.fromJson` — same multi-format change, so imported Discogs collection items also carry all format entries
- `DiscogsWantlistItemDto.fromJson` — same multi-format change for imported wantlist items
- Release Detail, Collection Detail, and Wishlist Detail screens — no code change needed; the Format row displays the `format` string as-is, and Flutter's `Text` widget renders `\n` as line breaks

### Tests
- 3 new tests in `discogs_api_client_test.dart`: `joins all format entries with newline when multiple formats present` for `fetchRelease`, `fetchCollectionPage`, and `fetchWantlistPage`
- 1 new test in `release_detail_screen_test.dart`: `shows all format entries separated by newline`

---

## [Unreleased — Phase 8E: ANV (credited artist name) shown on release detail (US-32)] — 2026-06-05

### Changed
- `DiscogsReleaseDto` — added `displayArtist` field: joins artist entries using `anv` when non-empty, `name` otherwise; equals `artist` when no ANV is present
- `ReleaseDetail` — added optional `displayArtist` field (null when same as canonical `artist`)
- `DiscogsReleaseDetailService._toDetail` — maps `dto.displayArtist` to `detail.displayArtist` (null when equal to canonical, so storage is unaffected)
- Release Detail screen — `_TitleArtist` and `_appBarTitle` use `displayArtist ?? artist`, so the ANV is shown when available and canonical name is shown otherwise
- Canonical `artist` field remains unchanged in use-cases and cache, preserving search/filter consistency

### Tests
- 2 new tests in `discogs_api_client_test.dart`: `displayArtist` equals canonical when `anv` absent; `displayArtist` uses `anv` when present and non-empty
- 2 new tests in `release_detail_screen_test.dart`: ANV shown in detail body instead of canonical; app bar uses ANV in title

---

## [Unreleased — Phase 8D: Artist name parsed correctly for releases with " – " in the title (US-31)] — 2026-06-05

### Fixed
- `DiscogsSearchResultDto.fromJson` — artist name now parsed correctly when the Discogs `title` field contains more than one ` - ` separator (e.g., `"This - Artist - The Album"` → artist=`"This - Artist"`, title=`"The Album"`). Previously, `indexOf` split on the first separator; now `lastIndexOf` is used so artist names containing ` - ` are preserved
- `DiscogsSearchResultDto.fromJson` — when the API response includes a dedicated `artist` field (string), it is used directly and the combined `title` field is taken as the pure album title without splitting

### Tests
- 2 new tests in `discogs_api_client_test.dart`: dedicated `artist` field used directly without splitting; artist name with embedded ` - ` split on last separator; no regression on existing single-separator test

---

## [Unreleased — Phase 8C: Token input field shows format guidance (US-30)] — 2026-06-05

### Changed
- `DiscogsTokenSection` — token `TextField` now shows `helperText: 'Discogs personal access tokens are 40 characters'` and a `maxLength: 40` character counter (soft limit — `MaxLengthEnforcement.none` — so tokens longer than 40 chars still display their count rather than being truncated)

### Tests
- 1 new test in `discogs_token_section_test.dart`: helper text containing "40 characters" is visible in the disconnected token form

---

## [Unreleased — Phase 8B: Tappable help link on Discogs token setup screen (US-29)] — 2026-06-05

### Added
- `url_launcher: ^6.3.0` dependency
- `DiscogsTokenSection` — `discogs.com/settings/developers` URL is now rendered as a tappable `_HelpLink` widget; tapping opens the URL in the device's default browser via `launchUrl(mode: externalApplication)`; falls back to a snackbar if the browser cannot be opened
- `DiscogsTokenSection.urlLauncher` — optional injectable callback (`Future<bool> Function(Uri)`) for testing without platform channel setup

### Changed
- `DiscogsTokenSection` — removed `helperText` / `helperMaxLines` from `InputDecoration`; replaced with `_HelpLink` widget (touch target ≥ 48 dp, URL styled with `primary` colour and underline)
- `AndroidManifest.xml` — added `<intent>` with `scheme="https"` to `<queries>` block so `url_launcher` can resolve HTTPS browser intents on Android 11+

### Tests
- 2 new tests in `discogs_token_section_test.dart`: tapping help link calls injected launcher with correct `https://discogs.com/settings/developers` URI; returns false → snackbar shown

---

## [Unreleased — Phase 8A: Deep linking and named routes (US-28)] — 2026-06-05

### Added
- `go_router: ^17.0.0` dependency — GoRouter replaces `MaterialPageRoute` push navigation throughout the app
- `lib/app/router.dart` — full `GoRouter` config with `StatefulShellRoute.indexedStack` for the five tab branches; `AppRoutes` constants for every named path; typed path helpers `AppRoutes.searchRelease`, `AppRoutes.collectionDetail`, `AppRoutes.wishlistDetail`
- Android deep linking — `<intent-filter>` with `scheme="cratewise"` added to `AndroidManifest.xml` so custom-scheme URLs open the correct screen
- iOS deep linking — `CFBundleURLSchemes: [cratewise]` added to `Info.plist`

### Changed
- `CratewiseApp` — now uses `MaterialApp.router(routerConfig: appRouter)` instead of `MaterialApp(home: HomeShellScreen())`
- `HomeShellScreen` — converted from `StatefulWidget` to `StatelessWidget`; now accepts a `StatefulNavigationShell` and delegates tab-switching to `navigationShell.goBranch`; no longer creates the `AppDatabase` (each tab screen manages its own connection)
- `SearchScreen` — narrow-layout "tap result" now calls `context.push(AppRoutes.searchRelease(...))` instead of `Navigator.push(MaterialPageRoute(...))`
- `CollectionScreen` — list item tap calls `context.push(AppRoutes.collectionDetail(id))`; `_CollectionList` no longer carries the `repository` reference (detail is routed via GoRouter); `RouteAware` / `appRouteObserver` refresh-on-pop pattern retained, wired via `StatefulShellBranch.observers`
- `WishlistScreen` — same pattern: item tap calls `context.push(AppRoutes.wishlistDetail(id))`; `_WishlistList` no longer carries `repository`
- `SettingsScreen` — constructor simplified (removed unused `retryUseCase`/`thumbnailUseCase` params); "Import & Export" tile calls `context.push(AppRoutes.importExport)`, "Failed Actions" tile calls `context.push(AppRoutes.failedActions)`; `evictionService` injected from router builder so the Thumbnail Cache section always shows
- `ImportExportScreen` — all nine sub-screen navigations (`onImportCollection`, …, `onViewHistory`) now call `context.push(AppRoutes.*)` instead of `Navigator.push(MaterialPageRoute(...))`

### Tests
- Navigation tests in `collection_screen_test.dart` — updated to use `_makeCollectionRouter` / `_wrapNavigable` GoRouter helpers; "live refresh" tests drive navigation via `router.push` / `tester.pageBack()`; `observers: [appRouteObserver]` added to test router so `didPopNext` still fires
- Navigation tests in `wishlist_screen_test.dart` — same pattern (`_makeWishlistRouter` / `_wrapNavigable`)
- Navigation test in `search_screen_test.dart` — narrow-layout back-navigation test uses `_buildScreenWithRouter` which includes `/search/release/:releaseId` route
- Navigation tests in `import_export_screen_test.dart` — all 19 `pumpWidget` calls in navigation groups updated to `_buildSubjectWithRouter`; new helper creates a GoRouter at `/settings/import-export` with all sub-routes mapped to fake-use-case screen builders so `pumpAndSettle` settles correctly

---

## [Unreleased — Phase 7Z: Safe area applied correctly for scrollable screen content (US-27)] — 2026-06-04

### Changed
- `HomeShellScreen` — wide layout (iPad / NavRail) content area is now wrapped in `SafeArea(top: false)` so tab-screen scroll content clears the home indicator on tablets
- `CollectionDetailScreen` (`_CollectionDetailBody`) — narrow and wide scroll bodies are now wrapped in `SafeArea(top: false)` so content is not obscured by the home indicator on pushed routes
- `WishlistDetailScreen` (`_WishlistDetailBody`) — same SafeArea treatment as CollectionDetailScreen
- `ImportExportScreen` — body `LayoutBuilder` is now wrapped in `SafeArea(top: false)`
- `ImportExportHistoryScreen` (`_HistoryList`) — `ListView.separated` is now wrapped in `SafeArea(top: false)`
- `FailedActionsScreen` (`_ActionList`) — `ListView.separated` is now wrapped in `SafeArea(top: false)`

### Tests
- 5 new tests in `safe area` groups: `CollectionDetailScreen`, `WishlistDetailScreen`, `ImportExportHistoryScreen`, `FailedActionsScreen`, `ImportExportScreen` each verify a `SafeArea` with `top: false` is present in the loaded widget tree

---

## [Unreleased — Phase 7Y: CSV export is compatible with Excel on Windows (US-25)] — 2026-06-04

### Changed
- `TempCsvFileWriter` — written CSV files now start with a UTF-8 BOM (`U+FEFF` / `\xEF\xBB\xBF`) so Excel on Windows opens them with correct encoding for non-ASCII characters; `writeAsString` encodes the BOM as UTF-8 bytes automatically
- `CsvParser` — strips a leading `U+FEFF` BOM character before normalising content, so files with or without the BOM are imported correctly

### Tests
- 4 new tests in `csv_parser_test.dart` (`BOM handling` group): UTF-8 BOM is stripped before parsing; first header contains no BOM character; file without BOM parses correctly; BOM-only content returns empty success

---

## [Unreleased — Phase 7X: Discogs exports back off on rate limits (US-24)] — 2026-06-04

### Changed
- `ExecuteCollectionExportUseCase` — per-item `addToCollection` call now retried on `RateLimitedError` (up to `_kMaxItemRetries = 3`) waiting `_kRateLimitRetryDelay = 60 s` via injectable `delay`; when retries are exhausted the item counts as failed and the export continues with remaining rows; `delay` and `maxItemRetries` are constructor-injectable for fast test execution
- `ExecuteWishlistExportUseCase` — same retry logic for `addToWantlist`

### Tests
- 14 new tests across 2 files (+0 regressions):
  - `execute_collection_export_use_case_test.dart` — 7 new tests in `rate-limit retry` group: succeeds exported=1 after retry; delay called with 60 s duration; prior items not re-exported (total API calls verified); item fails when retries exhausted; export continues with remaining items; delay called `maxItemRetries` times before exhaustion; `ValidRow` saved for retried success
  - `execute_wishlist_export_use_case_test.dart` — 7 matching tests for wishlist

---

## [Unreleased — Phase 7W: Discogs import handles rate limits mid-pagination (US-23)] — 2026-06-04

### Changed
- `FetchCollectionImportPreviewUseCase` — pagination loop now retries each failed page on `RateLimitedError` (up to `_kMaxPageRetries = 3`), waiting `_kRateLimitRetryDelay = 60 s` between attempts via an injectable `delay` function; after exhausting retries returns `FetchPreviewRateLimitExhausted` (replaces `FetchPreviewRateLimited`); `delay` and `maxPageRetries` are constructor-injectable for fast test execution
- `FetchWishlistImportPreviewUseCase` — same retry logic; `FetchWishlistPreviewRateLimited` renamed to `FetchWishlistPreviewRateLimitExhausted`
- `CollectionImportPreviewScreen` — maps `FetchPreviewRateLimitExhausted` to the existing `_RateLimited` error state; error message updated to "Discogs rate-limited requests and all retries were exhausted. Please wait a minute and try again." — the existing **Try again** button acts as the retry-from-beginning option
- `WishlistImportPreviewScreen` — same message update

### Tests
- 14 new tests across 4 files (+0 regressions):
  - `fetch_collection_import_preview_use_case_test.dart` — 7 new tests in `rate-limit retry` group: succeeds after one 429 on page 1; retries same page after mid-pagination 429; final preview includes all pages; `delay` called with 60 s duration; delay called once per 429; `FetchPreviewRateLimitExhausted` returned when exhausted; delay count equals `maxPageRetries`
  - `fetch_wishlist_import_preview_use_case_test.dart` — 7 matching tests for wishlist

---

## [Unreleased — Phase 7V: Failed collection and wishlist writes are queued for retry (US-22)] — 2026-06-04

### Added
- `RetryAction.payload` — optional `String?` field that stores a JSON-encoded item snapshot; used by write-retry use cases to reconstruct the item that failed to persist. `RetryActions` DB table updated (schema v8, `addColumn` migration)
- `CollectionItem.toJson()` / `CollectionItem.fromJson()` / `CollectionItem.tryFromJson()` — JSON serialisation helpers
- `WishlistItem.toJson()` / `WishlistItem.fromJson()` / `WishlistItem.tryFromJson()` — JSON serialisation helpers
- `AddToCollectionStorageError` — new sealed result type; returned when `CollectionRepository.add` throws; retry action is queued before returning
- `AddToWishlistStorageError` — same for wishlist
- `RetryAddCollectionItemUseCase` — re-attempts a failed collection add: deserialises item from payload, runs duplicate check, calls `CollectionRepository.add`; removes action on success or `AlreadyExists`; increments attempt count on `StorageError` or `InvalidPayload`
- `RetryAddWishlistItemUseCase` — same for wishlist
- `FailedActionsScreen` — accepts `addCollectionUseCase` and `addWishlistUseCase`; shows **Retry** button for `addCollectionItem` / `addWishlistItem` actions; dispatches to new use cases on tap; snackbar messages cover success, already-exists, invalid-payload, and storage-error outcomes

### Changed
- `AddToCollectionUseCase` — wraps `_repository.add` in try/catch; on failure calls `_retryRepository.getPending()` to dedup, then records a new `addCollectionItem` action with the serialised item in `payload`; safe message includes item title (no token or secret)
- `AddToWishlistUseCase` — same pattern for wishlist
- `ReleaseDetailScreen._handleAdd` — handles new `AddToCollectionStorageError` result: resets add state to `idle`, shows "Could not save to collection — queued for retry." snackbar
- `ReleaseDetailScreen._handleAddToWishlist` — handles new `AddToWishlistStorageError` result

### Tests
- 67 new tests across 7 files:
  - `collection_item_serialization_test.dart` (new) — 5 tests: round-trip all fields, null fields, `tryFromJson` valid/malformed/missing
  - `wishlist_item_serialization_test.dart` (new) — 5 tests: same for wishlist
  - `add_to_collection_use_case_test.dart` — 9 new: `StorageError` result, retry recorded, correct action type / entityId / message / payload, no-retryRepo path, dedup, no token in message
  - `add_to_wishlist_use_case_test.dart` — 9 new: same for wishlist
  - `retry_add_collection_item_use_case_test.dart` (new) — 15 tests: success, already-exists, invalid-payload (×2), attempt-count increment, status-to-failed, storage-error (×4)
  - `retry_add_wishlist_item_use_case_test.dart` (new) — 15 tests: same for wishlist
  - `failed_actions_screen_test.dart` — 11 new: Retry button visible/hidden for addCollectionItem and addWishlistItem, execute called, all snackbar messages, friendly labels

---

## [Unreleased — Phase 7U: Locally-added items can be promoted to Discogs-linked status (US-21)] — 2026-06-04

### Changed
- `ExecuteImportCompleted` / `ExecuteWishlistImportCompleted` — new optional `linked` field (default `0`); counts items whose sync status was updated to `synced` during import
- `ExecuteCollectionImportUseCase` / `ExecuteWishlistImportUseCase` — `DuplicateCollectionRow` / `DuplicateWishlistRow` items are now processed with a single `getAll()` lookup to build a release-ID map; existing items with `syncStatus != synced` have their status updated to `synced` and count as `linked`; items already `synced` (or not found in local storage) are still skipped
- `CollectionImportPreviewScreen` / `WishlistImportPreviewScreen` — summary card label changed from "Already in collection / Already in wishlist" to **"Already linked"**; warning card updated to say items "will be linked to Discogs" (not "will be skipped"); `_ConfirmBar` now activates when `newCount > 0 || duplicateCount > 0` with dynamic label: "Import N records", "Link N existing items", or "Import N records + link M existing items"; import summary body shows "Linked to Discogs: N" row when `linked > 0`

### Tests
- 18 new tests across 4 files:
  - `execute_collection_import_use_case_test.dart` — 4 new: links `localOnly` item to `synced`, skips already-`synced` item, `ValidRow` for linked item, linked items count towards job `validItems`; 1 updated: duplicate-row skip reason renamed "Already linked to Discogs"
  - `execute_wishlist_import_use_case_test.dart` — same 4 new tests + 1 updated reason string
  - `collection_import_preview_screen_test.dart` — 7 new: "Already linked" label, "Link N existing items" button, "Import N + link M" combined label, enabled when only duplicates + use case, "Linked to Discogs" in summary, no "Linked to Discogs" when zero; 4 updated (warning card now checks "linked to Discogs" text)
  - `wishlist_import_preview_screen_test.dart` — same 6 new + 4 updated

---

## [Unreleased — Phase 7T: Failed cache writes are silently retried (US-20)] — 2026-06-04

### Changed
- `CacheRetryRecorder` — new `recordMetadataCacheWriteFailure(int releaseId)` method: unconditionally records a `refreshReleaseMetadata` retry action when a local metadata write fails (no `_isRetryable` gate — I/O failures are always retryable)
- `DiscogsReleaseDetailService._tryCache` — on save failure, now calls `_cacheRetryRecorder?.recordMetadataCacheWriteFailure(detail.id)` so a retry is queued silently; the detail load is still not blocked

### Tests
- 10 new tests across 2 files:
  - `cache_retry_recorder_test.dart` — 8 new tests in `recordMetadataCacheWriteFailure` group: records `refreshReleaseMetadata` action, correct entityId, entityType, status and attemptCount, deduplicates against existing `refreshReleaseMetadata` action (from API failure), safe error message, swallows repo errors
  - `discogs_release_detail_service_test.dart` — 2 new tests in `retry recording` group: records metadata retry when cache write fails; records thumbnail retry when thumbnail save fails (explicit I/O-failure coverage complementing the existing 404 test)

---

## [Unreleased — Phase 7S: Thumbnail cache storage limit and eviction policy (US-19)] — 2026-06-04

### Added
- `ThumbnailEntry` domain model — value object with `releaseId`, `lastModified`, `sizeBytes`; used by `ThumbnailRepository` to expose file-system metadata for eviction decisions
- `ThumbnailEvictionService` — stateless application service with `evictIfNeeded({int maxBytes})` (LRU eviction, default 200 MB limit), `currentSizeBytes()`, and `clearAll()`; constant `kDefaultThumbnailCacheLimitBytes = 200 MB` is the configurable default

### Changed
- `ThumbnailRepository` — three new methods: `totalSizeBytes()`, `listEntries()` (returns `List<ThumbnailEntry>`), `removeAll()`
- `LocalThumbnailRepository` — implements all three new methods using filesystem `FileStat` (file size + last-modified time for LRU ordering)
- `ThumbnailCacheService` — now accepts optional `ThumbnailEvictionService`; creates a default from its own repository if none supplied; calls `unawaited(evictionService.evictIfNeeded())` after every successful thumbnail save, so eviction runs silently in the background
- `SettingsScreen` — new optional `evictionService` parameter; when supplied, renders a `_ThumbnailCacheSection` tile (`Icons.image_outlined`) showing formatted cache size ("X.X MB" / "< 1 MB") and an enabled `Clear` button (disabled when size is 0)
- `HomeShellScreen` — creates `LocalThumbnailRepository` and `ThumbnailEvictionService` at shell level; passes `evictionService` to `SettingsScreen`
- All 8 fake/spy `ThumbnailRepository` test implementations updated to add the three new interface methods

### Tests
- 33 new tests across 4 files:
  - `local_thumbnail_repository_test.dart` — 11 new tests covering `totalSizeBytes` (empty, sum, after remove), `listEntries` (empty, count, releaseId, sizeBytes, lastModified, ignores non-thumb files), `removeAll` (no-op, removes all, size = 0 after)
  - `thumbnail_eviction_service_test.dart` (new file) — 13 tests: `currentSizeBytes`, `clearAll`, `evictIfNeeded` (under limit, at limit, oldest first, multiple entries, stops at limit, default constant, empty cache)
  - `thumbnail_cache_service_test.dart` — 3 new eviction-trigger tests: `evictIfNeeded` called after successful download; NOT called on cache hit; NOT called on failed fetch
  - `settings_screen_test.dart` (new file) — 6 tests: tile shown/hidden with/without eviction service, formatted size, "< 1 MB", Clear button enabled/disabled, Clear tap calls `removeAll` and updates subtitle

---

## [Unreleased — Phase 7R: Cached offline release detail shows complete data (US-18)] — 2026-06-04

### Changed
- `CachedReleaseMetadata` — `tracklist` field type changed from `List<String>` (titles only) to `List<ReleaseTrack>` (position + title + duration); `barcodes: List<String>` replaced by `identifiers: List<ReleaseIdentifier>` (type + value), preserving all identifier types (Barcode, Matrix / Runout, etc.), not just barcodes
- `AppDatabase` — `CachedReleases` table: `tracklist` column now uses `TrackListConverter` (JSON objects with position/title/duration); `barcodes` column replaced by `identifiers` column using `IdentifierListConverter` (JSON objects with type/value); schema bumped to v7 with a drop-and-recreate migration (cache data can always be re-fetched)
- `TrackListConverter` (new) — Drift `TypeConverter<List<ReleaseTrack>, String>` that serialises each track as `{"position":…,"title":…,"duration":…}`
- `IdentifierListConverter` (new) — Drift `TypeConverter<List<ReleaseIdentifier>, String>` that serialises each identifier as `{"type":…,"value":…}`
- `LocalCachedReleaseMetadataRepository` — updated `_rowToModel` and `_modelToCompanion` to use `tracklist` and `identifiers` columns with the new types
- `DiscogsReleaseDetailService._toCachedMetadata` — now saves `detail.tracklist` directly (preserving `ReleaseTrack` objects) and `detail.identifiers` directly (all identifier types, not only barcodes)
- `RetryMetadataRefreshUseCase._toMetadata` — same fix: maps DTO tracks to `ReleaseTrack` objects and DTO identifiers to `ReleaseIdentifier` objects
- `_cachedMetadataToDetail` in `release_detail_screen.dart` — now passes `m.tracklist` and `m.identifiers` directly; no longer synthesises `ReleaseTrack` objects with empty position/duration or wraps barcodes as fake identifiers

### Tests
- 10 new / updated tests across 3 files (+8 new tests overall):
  - `local_cached_release_metadata_repository_test.dart` — `_makeMeta` factory updated; `'round-trips tracklist'` replaced by `'round-trips full tracklist with position, title and duration'`; `'round-trips barcodes list'` replaced by `'round-trips full identifiers list with type and value'`; `'empty lists round-trip'` updated; `barcodes: []` → `identifiers: []` in `'empty lists'` test
  - `discogs_release_detail_service_test.dart` — `'cached metadata maps fields'` test updated (`barcodes` → `identifiers` with type check); new test `'cached metadata saves full tracklist with position and duration'`
  - `release_detail_screen_test.dart` — `_cachedKindOfBlue` fixture updated to use `List<ReleaseTrack>` and `List<ReleaseIdentifier>` (adds Matrix / Runout identifier); 8 new tests in `'offline cache fallback'` group:
    - Shows full tracklist titles from cache
    - Shows track positions from cache (A1, A2)
    - Shows track durations from cache (9:22, 9:46)
    - Shows all identifiers from cache (Barcode + Matrix / Runout type and value)
    - Shows notes from cache
    - Omits tracklist section when cache has no tracks
    - Omits identifiers section when cache has no identifiers

---

## [Unreleased — Phase 7Q: Collection item condition prompt after adding (US-17)] — 2026-06-04

### Changed
- `ReleaseDetailScreen._handleAdd` — after a successful add, now awaits `_showConditionPrompt(item)` before showing the "Added to your collection" snackbar; the snackbar fires after the sheet is dismissed so the prompt is the first thing the user sees
- `_showConditionPrompt` (new method) — shows `_ConditionPromptSheet` as a modal bottom sheet; if the user taps Save, calls `_collectionRepository.update` with the selected conditions; if the user taps Skip or swipes to dismiss, the item keeps its defaults silently
- `_ConditionPromptSheet` (new widget) — modal bottom sheet with two `DropdownButtonFormField` pickers (Media, Sleeve), defaulted to the item's current conditions; Save pops the sheet with the chosen values, Skip pops with null; includes a drag handle and subtitle reminding users they can update conditions any time from their collection
- `_ConditionDropdown` (new widget) — shared dropdown helper used by `_ConditionPromptSheet` for both the Media and Sleeve pickers; excludes `RecordCondition.notSet` from the picker list since the sheet is specifically for grading

### Tests
- 7 new / updated tests in `release_detail_screen_test.dart`:
  - `ReleaseDetailScreen — condition prompt` group (7 tests):
    - Condition prompt sheet appears after a successful add
    - Condition prompt does not appear for duplicates
    - Prompt shows the default `Very Good (VG)` label for both pickers
    - Tapping Skip closes the sheet and then shows the "Added to your collection" snackbar
    - Tapping Skip does not call `repository.update`
    - Tapping Save closes the sheet and then shows the snackbar
    - Tapping Save calls `repository.update` with the conditions selected in the dropdowns
  - Existing `'tapping button shows added snackbar'` test updated to dismiss the condition prompt sheet (via Skip) before asserting the snackbar; now uses `_TrackingCollectionRepository` and passes `collectionRepository` to the screen

---

## [Unreleased — Phase 7P: Rate-limit response headers used to back off proactively (US-16)] — 2026-06-04

### Changed
- `DiscogsApiClient` — accepts an optional `delay` parameter (`Future<void> Function(Duration)`) so tests can override the real `Future.delayed` without slowing the suite
- `DiscogsApiClient._get` and `_post` — call `_waitIfNeeded()` before sending the HTTP request and `_updateRateLimitState(response)` after a successful response; both paths are covered (all GET endpoints: search, release detail, collection/wishlist import, identity; all POST endpoints: collection/wishlist export)
- `_waitIfNeeded()` — if `_nextAllowedAt` is set and is still in the future, awaits the remaining delay then clears the field; clears before awaiting so only the very next concurrent request waits
- `_updateRateLimitState(response)` — reads `X-Discogs-Ratelimit-Remaining` header (lowercase); if the value is ≤ 0 (the default threshold), sets `_nextAllowedAt = now + 60 seconds` (the Discogs rate-limit reset window)

### Tests
- 6 new tests in `DiscogsApiClient rate-limit back-off` group:
  - No delay when the remaining header is absent
  - No delay when remaining is above the threshold
  - Delay is scheduled when remaining reaches 0 on a GET response
  - Delay duration is at least 59 seconds (≈ the 60-second reset window)
  - Delay fires exactly once then clears for subsequent calls
  - Delay also applies to the next POST request after a GET with remaining=0

---

## [Unreleased — Phase 7O: Discogs credentials saved atomically (US-15)] — 2026-06-04

### Changed
- `DiscogsTokenStorage.saveCredentials` — on any failure (write throw, read-back throw, or read-back mismatch), both `discogs_token` and `discogs_username` keys are now deleted before the `StorageError` is propagated; prevents a half-connected state where the token was written but the username write failed (or vice versa)
- `DiscogsConnectionService.loadStatus` — now reads both `loadToken()` and `loadUsername()` and returns `ConnectionStatus.disconnected()` unless both are non-null; a half-written credential pair is treated as disconnected so the user is prompted to reconnect rather than seeing a stale "Connected as @username" banner that silently fails on API calls

### Tests
- 4 new tests across 2 files:
  - `discogs_token_storage_test.dart` — `saveCredentials atomicity` group: verifies that (a) a partial write (username write fails) leaves neither key in storage, and (b) a read-back failure also results in both keys being deleted
  - `discogs_connection_service_test.dart` — `loadStatus half-connected guard` group: verifies disconnected is returned when token is present without username, and when username is present without token

---

## [Unreleased — Phase 7N: Revoked Discogs token detected and cleared automatically (US-14)] — 2026-06-04

### Added
- `TokenRevocationGuard` extension on `TokenStorage` (in `lib/domain/repositories/token_storage.dart`) — adds `clearIfRevoked(AppError)` which silently calls `deleteCredentials()` when the error is `InvalidTokenError` and no-ops for all other errors

### Changed
- `DiscogsSearchService.search()` — wraps the API call in a try-catch; calls `clearIfRevoked` on `InvalidTokenError` before rethrowing so the stored token is deleted on 401
- `DiscogsReleaseDetailService.fetchDetail()` — calls `clearIfRevoked` inside the existing `on AppError` catch block before rethrowing
- `BarcodeLookupUseCase.execute()` — calls `clearIfRevoked` inside the existing `on AppError` catch before returning `BarcodeLookupError`
- `FetchCollectionImportPreviewUseCase.execute()` — calls `clearIfRevoked` inside `on AppError` catch before returning `FetchPreviewError`
- `FetchWishlistImportPreviewUseCase.execute()` — same pattern
- `ExecuteCollectionExportUseCase` — per-row API `catch (_)` changed to `catch (e)`; calls `clearIfRevoked(e)` when `e is AppError` (covers 401 mid-export)
- `ExecuteWishlistExportUseCase` — same per-row change

### Tests
- 14 new tests across 7 test files (2 per file) — each verifies that `deleteCredentials()` IS called on 401 and is NOT called on `NetworkError` or other non-401 errors: `DiscogsSearchService`, `DiscogsReleaseDetailService`, `BarcodeLookupUseCase`, `FetchCollectionImportPreviewUseCase`, `FetchWishlistImportPreviewUseCase`, `ExecuteCollectionExportUseCase`, `ExecuteWishlistExportUseCase`
- `_SpyStorage` / `_SpyTokenStorage` classes added to each affected test file to track `deleteCredentials()` call counts

---

## [Unreleased — Phase 7M: Wide-screen navigation keeps the nav rail visible (US-13)] — 2026-06-04

### Added
- `SearchScreen` now renders a split-pane layout on screens ≥ 700 dp wide: a 320 dp search results column on the left and a full-height detail pane on the right
- `_NoSelectionPlaceholder` widget — shown in the right pane before any result is tapped
- Tapping a search result on a wide layout sets `_selectedResult` and renders `ReleaseDetailScreen` directly in the right pane (using `ValueKey` to rebuild when the selection changes); the nav rail in `HomeShellScreen` stays visible at all times
- On narrow layouts (< 700 dp), the existing `Navigator.push` behaviour is unchanged

### Changed
- `_ResultsList` now accepts `onResultTap: ValueChanged<ReleaseSearchResult>` instead of constructing `ReleaseDetailScreen` and calling `Navigator.push` internally; the `addToCollectionUseCase`, `addToWishlistUseCase`, and `cacheRepository` parameters are removed from `_ResultsList` (moved up to the state-level callback)
- `_selectedResult` is cleared when a new search query is submitted or the query is emptied, so the detail pane resets to the placeholder on each new search

### Tests
- 6 new tests in `search_screen_test.dart` (group: "SearchScreen wide layout"): placeholder shown before tap; placeholder shown when query is empty; tapping shows detail without Navigator push; detail pane shows correct artist/title; selecting different result updates pane; clearing search clears pane; new search clears pane
- Existing "back from detail" navigation test updated to use a 390×844 dp narrow viewport to preserve push-route coverage

---

## [Unreleased — Phase 7L: "Already in wishlist" indicator on release detail (US-12)] — 2026-06-04

### Added
- `ReleaseDetailScreen` now accepts a `wishlistRepository` constructor parameter (`WishlistRepository?`) — mirrors the existing `collectionRepository` parameter
- `_checkInitialWishlistStatus()` — runs on screen mount, calls `wishlistRepository.containsRelease()` against local storage and pre-sets `_addWishlistState` to `_AddState.duplicate` if the release is already wishlisted
- In the production code path, `LocalWishlistRepository` is now stored as `_wishlistRepository` so the initial check has a reference to it; the same instance is passed to `AddToWishlistUseCase`

### Changed
- `_addWishlistState` is initialized to `_AddState.duplicate` (showing "In Wishlist", disabled) on load when the release ID already exists in local wishlist storage — no network call required
- Adding a wishlist item and navigating back to the same `ReleaseDetailScreen` then navigating back again correctly shows "In Wishlist" on the next mount (check runs again from local storage)

### Tests
- 4 new tests in `release_detail_screen_test.dart` (group: "already in wishlist indicator"): shows In Wishlist on load when already in wishlist; In Wishlist button is disabled on load; shows Add to Wishlist on load when not in wishlist; shows In Wishlist on load in cached state when already in wishlist

---

## [Unreleased — Phase 7K: Wishlist search and filter (US-11)] — 2026-06-04

### Added
- `WishlistScreen` search field: pill-shaped `TextField` with `Icons.search` prefix and clear button — same visual style as the Collection list search field
- `_NoSearchResults` widget shown when the active filter matches no wishlist items, displaying the query text and a hint to try a different artist or title
- `_buildBody()` / `_buildLoadedList()` methods replace the inline `switch` in `build()`, keeping filter logic out of the state dispatcher

### Changed
- `WishlistScreen` now filters by artist and/or title as the user types — filtering is local, no network call, operates on already-loaded items
- A 300 ms debounce via `dart:async Timer` (`_debouncedQuery`) prevents re-filtering on every keystroke; the clear button cancels the pending timer and resets `_debouncedQuery` synchronously
- The `RefreshIndicator` wraps only the filtered list, not the no-results widget; the `_EmptyWishlistState` (empty collection) is still distinguished from `_NoSearchResults` (items exist but none match the query)
- Filter applies to both the list layout (phone) and the grid layout (iPad), since filtering happens upstream of `_WishlistList`

### Tests
- 8 new tests in `wishlist_screen_test.dart` (group: "search filter"): filters by artist; filters by title; shows no-results message when nothing matches; no-results message includes the query; clearing search restores full list; case-insensitive matching; list is not filtered before debounce fires; filter works in iPad GridView layout

---

## [Unreleased — Phase 7J: Collection list live-refreshes after adding items (US-10)] — 2026-06-04

### Added
- `lib/shared/route_observer.dart` — exports a single `appRouteObserver` (`RouteObserver<ModalRoute<dynamic>>`) instance registered with `MaterialApp.navigatorObservers`
- `lib/app/app.dart` — `appRouteObserver` added to `MaterialApp.navigatorObservers`

### Changed
- `CollectionScreen` now subscribes to `appRouteObserver` via the `RouteAware` mixin; `didPopNext` triggers a silent `_refresh()` every time a pushed route (e.g. `ReleaseDetailScreen`) is popped above the collection list
- Silent refresh keeps the existing items visible while the storage query runs — no full-screen spinner, no flicker; items update in place when the fetch completes
- The subscription is set up in `didChangeDependencies` (guarded by a null check on `ModalRoute.of`) and cancelled in `dispose` via `appRouteObserver.unsubscribe(this)`

### Tests
- 3 new tests in `collection_screen_test.dart` (group: "live refresh after navigation"): `getAll` is called again after a pushed route is popped; no loading spinner appears during the silent refresh (old items stay visible); new item added during the pushed route appears in the list after pop

---

## [Unreleased — Phase 7I: Collection list search and filter (US-09)] — 2026-06-04

### Changed
- `CollectionScreen` search field is now functional: items are filtered by artist and/or title as the user types
- Filtering is local — no network call; operates on the items already loaded in `_state`
- A 300 ms debounce is applied via `dart:async Timer`; `_debouncedQuery` drives the filter so rapid keystrokes do not re-filter on every character
- The clear button cancels the pending debounce and immediately resets both the controller and `_debouncedQuery`, restoring the full list without a delay
- A new `_NoSearchResults` widget is shown when the active filter matches no items, displaying the query text and a hint to try a different artist or title
- The filter applies to both the list layout (phone) and the grid layout (iPad), since filtering happens before `_CollectionList` receives its items

### Tests
- 8 new tests in `collection_screen_test.dart` (group: "search filter"): filters by artist; filters by title; shows no-results message when nothing matches; no-results message includes the query; clearing search restores full list; case-insensitive matching; list is not filtered before debounce fires; filter works in iPad GridView layout

---

## [Unreleased — Phase 7H: "Already in collection" indicator on release detail (US-08)] — 2026-06-04

### Changed
- `ReleaseDetailScreen` now checks local collection storage on mount and pre-sets the "Add to Collection" button to "In Collection" (disabled) when the release ID already exists in the collection — no network call required
- `ReleaseDetailScreen` gains an optional `collectionRepository` parameter for dependency injection; in production it shares the same `LocalCollectionRepository` instance already used by `AddToCollectionUseCase`
- The check also applies when the screen shows cached offline data (`_CachedLoaded` state), so the indicator is correct even without a network connection
- Navigating back to a release already added shows the correct "In Collection" state immediately, since each new screen instance re-runs the check against current local storage

### Tests
- 4 new tests in `release_detail_screen_test.dart` (group: "already in collection indicator"): shows "In Collection" on load when already in collection; "In Collection" button is disabled on initial load; shows "Add to Collection" when not in collection; shows "In Collection" in cached state when already in collection

---

## [Unreleased — Phase 7G: Cover images use thumbnails (US-07)] — 2026-06-04

### Changed
- Release Detail service now caches `uri150` (thumbnail) instead of the full-resolution `uri` when both are present in the Discogs images array — collection and wishlist list cards benefit immediately since they read from the local thumbnail cache
- `DiscogsReleaseDto` gains a `thumbUrl` field extracted from `imageMap['uri150']`; `coverUrl` (`uri`) is unchanged and still used for the hero image on the Release Detail screen
- `DiscogsReleaseDetailService._tryThumbnailCache` now accepts `(int releaseId, String? imageUrl)` and prefers `dto.thumbUrl` over `detail.coverUrl`; falls back to `uri` when `uri150` is absent
- Search result cards already used the `thumb` field (`uri150`) from the Discogs search API — no change required there

### Tests
- 2 new tests in `discogs_api_client_test.dart` (group: "fetchRelease"): parses `thumbUrl` from `uri150`; `thumbUrl` is null when `uri150` absent
- 2 new tests in `discogs_release_detail_service_test.dart` (group: "thumbnail URL selection"): uses `uri150` URL when available; falls back to `uri` when `uri150` absent

---

## [Unreleased — Phase 7F: Release detail shows artist and title from search context (US-06)] — 2026-06-04

### Changed
- **Release Detail loading skeleton** now shows the artist and title passed from the search result card immediately — no more blank placeholders while the API call is in flight
- **Release Detail app bar** uses the same `initialArtist`/`initialTitle` context during the loading state, so "Artist — Title" (or just "Title") appears in the app bar before the Discogs response arrives
- Once the full API response loads, the detail screen replaces the initial context with authoritative data (ANV, format details, etc.)
- `ReleaseDetailScreen` gains two optional parameters: `initialArtist` and `initialTitle`
- `_SkeletonBody` replaces its artist/title placeholder blocks with real `Text` widgets when context is provided
- Navigation from the search results list passes `item.artist` and `item.title` to `ReleaseDetailScreen`

### Tests
- 4 new tests in `release_detail_screen_test.dart` (group: "search context"): app bar shows "Artist — Title" from context while loading; skeleton shows artist and title text during loading; app bar shows only title when artist context is absent; authoritative API data replaces search context after load

---

## [Unreleased — Phase 7E: Release detail app bar shows album title (US-05)] — 2026-06-03

### Changed
- **Release Detail app bar** now shows **"Artist — Title"** once data has loaded (e.g. "Miles Davis — Kind Of Blue"), replacing the static "Release Detail" placeholder
- When only a title is available (no artist), the app bar shows the title alone
- When the release is shown from the offline cache (`_CachedLoaded`), the app bar uses the cached artist and title in the same format
- Loading and error states continue to show "Release Detail" as a placeholder
- `Text` widget in the app bar now sets `overflow: TextOverflow.ellipsis` and `maxLines: 1` so long titles truncate cleanly rather than overflowing

### Tests
- 4 new tests in `release_detail_screen_test.dart` (group: "app bar title"): combined artist+title format in loaded state; title-only when artist is absent; "Release Detail" placeholder in error state; combined format from offline cache

---

## [Unreleased — Phase 7D: Pull-to-refresh on key screens (US-04)] — 2026-06-03

### Added
- Pull-to-refresh (`RefreshIndicator`) on **Release Detail**, **Collection list**, **Collection Detail**, **Wishlist list**, and **Wishlist Detail** screens — all 5 acceptance criteria screens covered
- `_refresh()` method on each screen's state: reloads data without first clearing the existing content (distinct from `_retry()` / `_load()` which reset to a loading state)
- Release Detail: refresh failure while content is already loaded shows a `SnackBar` (friendly message — rate-limited, no internet, or generic) and keeps the loaded detail visible; refresh failure from an error state transitions to `_DetailError` as normal
- Collection list / Wishlist list: refresh failure while items are already visible shows a `SnackBar` and keeps the existing list; failure from a non-loaded state transitions to the full error state
- Collection Detail / Wishlist Detail: same snackbar-and-preserve pattern as the list screens
- `AlwaysScrollableScrollPhysics` added to all inner `ListView`, `GridView`, and `SingleChildScrollView` widgets that underlie the `RefreshIndicator`, ensuring pull-to-refresh triggers even when the content is shorter than the viewport
- 27 new tests across 5 test files (5–6 per screen): `RefreshIndicator` present on loaded state; PTR triggers the data-fetch again; PTR updates displayed content; PTR error keeps existing content visible; no `RefreshIndicator` in error/loading states

### Notes
- Snackbar messages for Release Detail refresh errors: `RateLimitedError` → "Too many requests — wait a moment and try again."; `NetworkError` → "No internet connection."; other → "Could not refresh. Try again."
- PTR is intentionally absent from the loading state (initial fetch in progress) and the error state (user should use the Retry button); it is also absent from the empty-collection/empty-wishlist state (no content to preserve)
- Test pattern: PTR tests call `tester.widget<RefreshIndicator>(...).onRefresh()` directly (bypasses the animation to avoid `pumpAndSettle` hanging on `AlwaysScrollableScrollPhysics` overscroll)

---

## [Unreleased — Phase 7C: Search results pagination (US-03)] — 2026-06-03

### Added
- `SearchResultPage` domain model (`lib/domain/models/search_result_page.dart`) carrying `items`, `currentPage`, `totalPages`, `totalResults`, and a `hasMore` getter
- `DiscogsSearchPageDto` (`lib/infrastructure/discogs/dto/discogs_search_result.dart`) parses the Discogs `pagination` object (`page`, `pages`, `items`) from both search and barcode endpoints
- `DiscogsApiClient.searchReleases` and `searchByBarcode` now accept `page` / `perPage` parameters (default 1 / 50) and return `DiscogsSearchPageDto` instead of a bare list
- `DiscogsSearchService.search` now accepts `int page = 1` and returns `SearchResultPage`
- `BarcodeLookupSuccess` now holds `SearchResultPage page` instead of a flat list; `BarcodeLookupUseCase.execute` accepts `int page = 1`
- `SearchScreen._ResultsList` is now a `StatefulWidget` with a `ScrollController`; a post-frame hook automatically fires `onLoadMore` when the content fits within the viewport (eager pre-fetch), and a scroll listener fires it again when the user scrolls within 300 px of the bottom
- `SearchScreen` state machine gains `isLoadingMore` / `paginationError` fields on `_Results`; pagination transitions are handled entirely within `_Results.copyWith` — no new top-level states needed
- Result count label (key `result-count`) shows "1–N of total" above the results list on both Search and Barcode scan screens
- Bottom loading spinner (key `pagination-loading`) shown while the next page is in-flight
- Inline retry button (key `pagination-retry`) shown when pagination fails with any `AppError` (rate-limit error shows "Rate limited — tap to retry"; other errors show "Failed to load more — tap to retry") — existing page 1 results remain visible
- `BarcodeScanScreen._ResultsList` receives the same pagination treatment (post-frame trigger, scroll listener, count label, spinner, retry button)
- 18 new tests: `SearchResultPage` model (5), `DiscogsApiClient` pagination fields (5), `DiscogsSearchService` pagination mapping (3), `BarcodeLookupUseCase` page forwarding (2), `SearchScreen` result-count and pagination UI (5), `BarcodeLookupSuccess` page field (2)

### Changed
- `DiscogsApiClient.searchReleases` and `searchByBarcode` return type changed from `List<DiscogsSearchResultDto>` to `DiscogsSearchPageDto`
- `DiscogsSearchService.search` return type changed from `Future<List<ReleaseSearchResult>>` to `Future<SearchResultPage>`
- `BarcodeLookupSuccess` field renamed from `results: List<ReleaseSearchResult>` to `page: SearchResultPage`; all callers and test doubles updated

---

## [Unreleased — Phase 7B: iOS token save reliability (US-02)] — 2026-06-03

### Added
- `SecureKeyValueStore` abstract interface in `lib/infrastructure/secure_storage/` — thin wrapper contract over the platform's secure storage; makes `DiscogsTokenStorage` fully unit-testable without platform channels
- `DiscogsTokenStorage` now performs a read-back verification after both `write` calls in `saveCredentials`; if either read returns a mismatched value the method throws `StorageError` — catches the iOS Keychain silent-write bug where `write()` returns without error but the value is never persisted
- `DiscogsTokenStorage` constructor now accepts `SecureKeyValueStore?` (replaces the old `FlutterSecureStorage?` parameter); production code defaults to `_FlutterSecureStorageAdapter` (private wrapper)
- 13 new unit tests in `test/infrastructure/secure_storage/discogs_token_storage_test.dart` covering: normal save + read-back, write throws, silent write failure, read-back throws, load returns null when absent, load throws on error, delete clears values, delete throws, `StorageError` never contains the token value

### Changed
- Debug log in `saveCredentials` no longer includes raw `$e.toString()`; now logs `runtimeType` and, when the exception is a `PlatformException`, the platform error `code` only — prevents any theoretical token leakage through exception messages

### Security
- `StorageError` is a const sealed class with no payload; it is structurally impossible for the thrown error to carry the token value

---

## [Unreleased — Phase 7A: HTTP request timeout (US-01)] — 2026-06-03

### Added
- `DiscogsApiClient` now enforces a 15-second request timeout on all outgoing HTTP calls (GET and POST)
- Timeout fires `TimeoutException` which is caught at the same level as `SocketException` and mapped to `NetworkError` — no loading state can remain active indefinitely
- `requestTimeout` constructor parameter (injectable) so tests can supply a short duration without real delay
- 2 new unit tests: timeout on GET (`fetchIdentity`) and timeout on POST (`addToCollection`)

### Security
- `TimeoutException` carries no token value; the resulting `NetworkError` is the same opaque typed error surfaced for all other network failures

---

## [Unreleased — Phase 6Q: Wishlist export preview UI] — 2026-06-03

### Added
- `WishlistExportPreviewScreen` with four states: `_Loading` (spinner), `_Ready` (preview summary + confirm bar), `_NotSupported` (explains CSV alternative), `_Error` (retry button)
- Summary card shows: total local wishlist items, ready to export count, already linked to Discogs count, cannot export count
- Notes card shown when there are already-synced or invalid items; already-synced wording uses "already in your Discogs wantlist and will be skipped" (wantlist-specific terminology)
- Disabled confirm bar with dynamic label ("Nothing to export" / "Export N record(s)"); button remains disabled until an execute use case is wired in
- `LayoutBuilder` wide layout ≥700dp: summary card and confirm bar side-by-side (iPad)
- `ImportExportScreen` wires the "Export Wishlist to Discogs" card to navigate to `WishlistExportPreviewScreen`; "Coming soon" badge removed from that card (Coming soon badge count: 5 → 4)
- 27 new screen widget tests and 3 navigation tests in `import_export_screen_test.dart`

### Security
- No tokens read or written in the preview screen
- `_NotSupportedState` displays only the capability reason string — never internal details or credentials

---

## [Unreleased — Phase 6P: Wishlist export preview builder] — 2026-06-02

### Added
- `WishlistExportPreview` domain model with `totalCount`, `eligibleCount`, `alreadySyncedCount`, and `invalidCount` computed getters
- `WishlistExportRow` sealed class with three subtypes: `EligibleWishlistExportRow` (valid release ID, not yet synced), `AlreadySyncedWishlistExportRow` (valid release ID, previously synced), `InvalidWishlistExportRow` (missing or invalid release ID, with safe reason string)
- `classifyWishlistItemForExport` top-level function: `discogsReleaseId <= 0` → invalid; `syncStatus == synced` → already synced; otherwise → eligible
- `CheckWishlistExportCapabilityUseCase` — always returns `WishlistExportNotSupported`; reason mentions CSV as an alternative; synchronous with no I/O
- `BuildWishlistExportPreviewUseCase` — checks capability first (skips repository when not supported); loads all wishlist items; classifies each into a row; catches repository errors and returns `WishlistExportPreviewError`
- 6 capability tests and 24 preview use-case tests (capability gate, empty wishlist, eligible/synced/invalid rows, mixed counts, repository error)

### Security
- `InvalidWishlistExportRow.reason` is a hardcoded display string — never a token, secret, or internal detail

---

## [Unreleased — Phase 6O: Execute collection export to Discogs] — 2026-06-02

### Added
- `DiscogsApiClient.addToCollection(username, releaseId, token)` — POST to `/users/{username}/collection/folders/1/releases/{releaseId}` (expects 201 Created); targets folder 1 (Discogs default "Uncategorized")
- `DiscogsApiClient._post(path, token)` helper method for POST requests with auth header
- `DiscogsApiClient._checkStatus` now accepts an optional `expectedStatus` parameter (default 200); POST uses 201
- `ExecuteCollectionExportUseCase` with four sealed result types: `ExecuteExportCompleted` (jobId, exported/skipped/failed counts), `ExecuteExportNotSupported`, `ExecuteExportNoToken`, `ExecuteExportFailed`
  - Step 1: capability gate — returns `ExecuteExportNotSupported` if not supported
  - Step 2: loads token and username from `TokenStorage` — returns `ExecuteExportNoToken` if absent or on error
  - Step 3: creates `ImportExportJob` record; iterates preview rows — POSTs each `EligibleExportRow` to Discogs, updates `syncStatus` to `synced` on success; skips `AlreadySyncedExportRow` and `InvalidExportRow`; records `ValidRow`/`SkippedRow`/`FailedRow` per item; updates job to completed/completedWithErrors on finish
- `CollectionExportPreviewScreen` gains three new states: `_Exporting` (spinner), `_ExportDone` (summary), `_NoToken` (friendly message)
- Confirm button is now enabled when `eligibleCount > 0` and an execute use case is wired in; tapping begins export and transitions through states
- `_ExportingBody` spinner widget, `_ExportSummaryBody` with Added to Discogs / Skipped / Failed counts and Done button, `_NoTokenState` widget
- Production `initState` self-creates `ExecuteCollectionExportUseCase` from all required dependencies; tests inject fakes
- 10 new API unit tests for `addToCollection` (201 success, correct URL and auth header, 401/403/429/500 error mapping, network error, 200 treated as unexpected)
- 35 new use-case tests covering capability gate, no token, successful export, partial failure, infrastructure failure, and security assertions
- Updated screen tests to 41 total (exporting state, export done state, execute transition states)

### Security
- Token and username are loaded at execution time and never stored in job records, row results, or error messages
- All user-facing error strings are hardcoded safe strings — no raw errors, no tokens
- `_NoTokenState` shows a friendly message without revealing what credentials are missing

---

## [Unreleased — Phase 6N: Collection export preview UI] — 2026-06-02

### Added
- `CollectionExportPreviewScreen` with four states: `_Loading` (spinner), `_Ready` (preview summary + confirm bar), `_NotSupported` (explains CSV alternative), `_Error` (retry button)
- Summary card shows: total local items, ready to export count, already linked to Discogs count, cannot export count
- Notes card shown when there are already-synced or invalid items, explaining what each category means
- Disabled confirm bar with dynamic label ("Nothing to export" / "Export N records"); enabled state wired in the next slice
- `LayoutBuilder` wide layout ≥700dp: summary card and row list side-by-side (iPad)
- `ImportExportScreen` wires the "Export Collection to Discogs" card to navigate to `CollectionExportPreviewScreen`; "Coming soon" badge removed from that card
- 31 new screen widget tests and 3 navigation tests in `import_export_screen_test.dart`

### Security
- No tokens read or written in the preview screen
- `_NotSupportedState` displays only the capability reason string — never internal details

---

## [Unreleased — Phase 6M: Collection export preview builder] — 2026-06-02

### Added
- `CollectionExportPreview` domain model with `totalCount`, `eligibleCount`, `alreadySyncedCount`, and `invalidCount` getters
- `CollectionExportRow` sealed class with three subtypes: `EligibleExportRow` (valid release ID, not yet synced), `AlreadySyncedExportRow` (valid release ID, previously synced), `InvalidExportRow` (missing or invalid release ID, with safe reason string)
- `classifyForExport` top-level function: `discogsReleaseId <= 0` → invalid; `syncStatus == synced` → already synced; otherwise → eligible
- `BuildCollectionExportPreviewUseCase` — checks capability first (skips repository when not supported); loads all collection items; classifies each; catches repository errors and returns `CollectionExportPreviewError`
- 24 new unit tests covering capability gate, empty collection, eligible/synced/invalid rows, mixed counts, repository error, and security assertions

### Security
- `InvalidExportRow.reason` is a hardcoded display string — never a token, secret, or internal detail

---

## [Unreleased — Phase 6L: Collection export capability check] — 2026-06-02

### Added
- `CheckCollectionExportCapabilityUseCase` with sealed result types `CollectionExportSupported` and `CollectionExportNotSupported`
- Always returns `CollectionExportNotSupported`; reason is a friendly user-facing string that mentions CSV as an alternative; synchronous with no I/O or network calls
- 6 unit tests: result type, non-empty reason, no token/secret wording, mentions CSV, synchronous, consistent across calls

---

## [Unreleased — Phase 6K: Confirm and save Discogs wishlist import] — 2026-06-02

### Added
- `ExecuteWishlistImportUseCase` with three result types: `WishlistImportCompleted` (jobId, added/skipped/failed counts), `WishlistImportNoToken`, `WishlistImportFailed`
  - Saves each `NewWishlistRow` as a `WishlistItem` via `WishlistRepository.add` with `WishlistPriority.medium` and `SyncStatus.localOnly`
  - Skips `DuplicateWishlistRow` and `InvalidWishlistRow` items, recording `SkippedRow` results for each
  - Records `ValidRow` on success or `FailedRow` on per-item exception
  - Creates and updates an `ImportExportJob` (running → completed / completedWithErrors)
- `WishlistImportPreviewScreen` gains `_Importing` and `_ImportDone` states; confirm button is now enabled
- `_ImportingBody` shows spinner with "Saving your wishlist…" message
- `_ImportSummaryBody` shows Added to wishlist / Skipped / Failed counts with a Done button
- 38 new tests covering use-case result paths, job record creation, skip/fail behavior, screen state transitions, and security assertions

### Security
- Token is loaded from `TokenStorage` at execution time; never stored in job records, row results, or error messages
- All snackbar and summary messages are hardcoded safe strings

---

## [Unreleased — Phase 6J: Wishlist import preview UI] — 2026-06-02

### Added
- `FetchWishlistImportPreviewUseCase` — loads token and username from `TokenStorage`; paginates `DiscogsApiClient.fetchWantlistPage`; passes all items to `BuildWishlistImportPreviewUseCase`; returns typed result: `WishlistImportPreviewReady`, `WishlistImportNoToken`, `WishlistImportRateLimited`, `WishlistImportNetworkError`, `WishlistImportError`
- `WishlistImportPreviewScreen` with six states: `_Loading`, `_Loaded`, `_NoToken`, `_RateLimited`, `_NetworkError`, `_Error`
- Summary card shows total wantlist items / new / duplicates / invalid counts
- Notes warning card shown when duplicates or invalid items are present
- Disabled confirm bar (execution added in the next slice)
- `LayoutBuilder` wide layout ≥700dp for iPad
- `ImportExportScreen` wires the "Import Wishlist from Discogs" card to navigate to `WishlistImportPreviewScreen`; "Coming soon" badge removed from that card
- 54 new tests covering all states, wide layout, security assertions, and 3 navigation tests in `import_export_screen_test.dart`

### Security
- Token is never shown or logged; only presence is checked
- `_NoTokenState` displays a connection prompt — no token value exposed
- No Discogs username or token appears in any user-facing widget text

---

## [Unreleased — Phase 6I: Wishlist import API + preview builder] — 2026-06-02

### Added
- `DiscogsApiClient.fetchWantlistPage(username, token, {page, perPage})` — paginated GET `/users/{username}/wants`; returns `DiscogsWantlistPageDto` with pagination metadata and list of `DiscogsWantlistItemDto`
- `DiscogsWantlistItemDto` — parses `releaseId`, `title`, `artist`, `year`, `label`, `catno`, `format`, `genres`, `thumbUrl`, `rating`, `notes` (notes treated as null when absent or empty string)
- `WishlistImportPreview` domain model with `totalCount`, `newCount`, `duplicateCount`, `invalidCount` getters
- `WishlistImportRow` sealed class with three subtypes: `NewWishlistRow`, `DuplicateWishlistRow`, `InvalidWishlistRow` (with safe reason string)
- `BuildWishlistImportPreviewUseCase` — classifies each DTO: `releaseId == 0` → invalid; blank title → invalid; already in local wishlist (by release ID) → duplicate; otherwise → new
- 24 new API unit tests and 28 new preview use-case tests (52 total)

### Security
- Token passed only as an HTTP `Authorization` header — never logged or stored beyond the call
- `InvalidWishlistRow.reason` is a hardcoded display string

---

## [Unreleased — Phase 6H: Confirm and save Discogs collection import] — 2026-06-02

### Added
- `ExecuteCollectionImportUseCase` with three result types: `CollectionImportCompleted` (jobId, added/skipped/failed counts), `CollectionImportNoToken`, `CollectionImportFailed`
  - Saves each `NewCollectionRow` as a `CollectionItem` via `CollectionRepository.add` with `RecordCondition.notSet` for media and sleeve and `SyncStatus.localOnly`
  - Skips `DuplicateCollectionRow` and `InvalidCollectionRow` items, recording `SkippedRow` results
  - Records `ValidRow` on success or `FailedRow` on per-item exception
  - Creates and updates an `ImportExportJob` (running → completed / completedWithErrors)
- `CollectionImportPreviewScreen` gains `_Importing` and `_ImportDone` states; confirm button is now enabled
- `_ImportingBody` shows spinner with "Saving your collection…" message
- `_ImportSummaryBody` shows Added / Skipped / Failed counts with a Done button
- 37 new tests covering use-case result paths, job record creation, skip/fail behavior, screen state transitions, and security assertions

### Security
- Token loaded at execution time; never stored in job records, row results, or error messages
- All summary and snackbar messages are hardcoded safe strings

---

## [Unreleased — Phase 6G: Collection import preview UI] — 2026-06-02

### Added
- `FetchCollectionImportPreviewUseCase` — loads token and username from `TokenStorage`; paginates `DiscogsApiClient.fetchCollectionPage`; passes all items to `BuildCollectionImportPreviewUseCase`; returns typed result: `CollectionImportPreviewReady`, `CollectionImportNoToken`, `CollectionImportRateLimited`, `CollectionImportNetworkError`, `CollectionImportError`
- `CollectionImportPreviewScreen` with six states: `_Loading`, `_Loaded`, `_NoToken`, `_RateLimited`, `_NetworkError`, `_Error`
- Summary card shows total Discogs items / new / duplicates / invalid counts
- Notes warning card shown when duplicates or invalid items are present
- Disabled confirm bar (execution added in the next slice)
- `LayoutBuilder` wide layout ≥700dp for iPad
- `ImportExportScreen` wires the "Import Collection from Discogs" card to navigate to `CollectionImportPreviewScreen`; "Coming soon" badge removed from that card
- 55 new tests covering all states, wide layout, security assertions, and navigation tests

### Security
- Token is never shown or logged; only presence is checked
- `_NoTokenState` displays a connection prompt — no token value or username exposed

---

## [Unreleased — Phase 6F: Collection import preview builder] — 2026-06-02

### Added
- `CollectionImportPreview` domain model with `totalCount`, `newCount`, `duplicateCount`, `invalidCount` getters
- `CollectionImportRow` sealed class with three subtypes: `NewCollectionRow`, `DuplicateCollectionRow`, `InvalidCollectionRow` (with safe reason string)
- `BuildCollectionImportPreviewUseCase` — classifies each `DiscogsCollectionItemDto`: `releaseId == 0` → invalid; blank title → invalid; already in local collection (by release ID) → duplicate; otherwise → new
- 28 new unit tests covering all classification paths, field mapping, duplicate detection, counts, and security assertions

### Security
- `InvalidCollectionRow.reason` is a hardcoded display string — never a token, secret, or internal detail

---

## [Unreleased — Phase 6E: Discogs collection import API method] — 2026-06-02

### Added
- `DiscogsApiClient.fetchCollectionPage(username, token, {page, perPage})` — paginated GET `/users/{username}/collection/folders/0/releases` (folder 0 = all releases); returns `DiscogsCollectionPageDto` with pagination metadata and list of `DiscogsCollectionItemDto`
- `DiscogsCollectionItemDto` — parses `releaseId`, `title`, `artist`, `year`, `label`, `catno`, `format`, `genres`, `thumbUrl` from Discogs collection response shape
- `DiscogsCollectionPageDto` with `items`, `page`, `pages`, `perPage`, `urls` fields
- 21 new unit tests covering successful parse, pagination metadata, error mapping (401, 429, 500, network), empty response, and multi-page detection

### Security
- Token passed only as an HTTP `Authorization` header — never logged, stored, or returned

---

## [Unreleased — Phase 6D: Import and Export screen shell] — 2026-06-02

### Added
- `ImportExportScreen` with two sections: Discogs actions (import/export collection and wishlist) and CSV file actions (export/import collection and wishlist)
- 8 action cards, each showing an icon, title, optional "Coming soon" badge, and chevron; tapping a Coming soon card shows a snackbar
- 2-column `SliverGrid` layout on screens ≥700dp (iPad); single-column `SliverList` on narrower screens
- Settings screen now has an "Import & Export" list tile that navigates to `ImportExportScreen`
- 15 new widget tests covering card render, Coming soon snackbar, wide grid layout, and Settings navigation

---

## [Unreleased — Phase 6C: Local import/export job storage] — 2026-06-02

### Added
- `ImportExportJobs` Drift table with columns for all `ImportExportJob` fields; `ImportExportJobTypeConverter` and `ImportExportStatusConverter` type converters
- `ImportExportRowResults` Drift table with columns for all `ImportExportRowResult` subtypes; `ImportExportRowResultTypeConverter`
- `LocalImportExportJobRepository` — Drift implementation of `ImportExportJobRepository`; `getRecent` orders by `startedAt` descending
- `LocalImportExportRowResultRepository` — Drift implementation of `ImportExportRowResultRepository`; `removeAllForJob` deletes by `jobId`
- Schema version bumped to 6; migration creates both new tables
- 51 new integration tests using `NativeDatabase.memory()` covering add/update/getById/getRecent/remove for jobs and addResult/getResults/removeAllForJob for row results, plus enum round-trip and security assertions

---

## [Unreleased — Phase 6B: Import/export repository contracts] — 2026-06-02

### Added
- `ImportExportJobRepository` abstract interface: `add`, `update`, `getById`, `getRecent(limit)`, `remove`
- `ImportExportRowResultRepository` abstract interface: `addResult`, `getResults(jobId)`, `removeAllForJob(jobId)`
- 28 new contract tests using in-memory fake implementations, covering add/read/update/delete semantics, `getRecent` ordering and limit, and `getResults` isolation by job ID

---

## [Unreleased — Phase 6A: Import/export domain models] — 2026-06-02

### Added
- `ImportExportJobType` enum with 8 values: `importCollectionFromDiscogs`, `importWishlistFromDiscogs`, `exportCollectionToDiscogs`, `exportWishlistToDiscogs`, `importCollectionFromCsv`, `exportCollectionToCsv`, `importWishlistFromCsv`, `exportWishlistToCsv`
- `ImportExportStatus` enum with 8 values: `notStarted`, `running`, `completed`, `completedWithErrors`, `failed`, `cancelled`, `partiallyCompleted`, `paused`
- `ImportExportJob` model with all job tracking fields (`id`, `jobType`, `status`, `startedAt`, `finishedAt`, `totalItems`, `processedItems`, `errorMessage`); `copyWith` with optional `clearFinishedAt` and `clearErrorMessage` flags
- `ImportExportRowResult` sealed class with three subtypes: `ValidRow` (itemId, label), `SkippedRow` (itemId, reason), `FailedRow` (itemId, safeMessage)
- 25 new unit tests covering enum labels, `copyWith` field preservation and clearing, `ImportExportRowResult` subtype checks, and security assertions (no token or secret fields on any model)

### Security
- No token, secret, or credential fields on any import/export model
- `FailedRow.safeMessage` is an explicit safe-string field by design

---

## [Unreleased — Phase 5R: Offline mode final polish] — 2026-06-02

### Changed
- Wishlist list shows a 2-column `GridView` on screens ≥700dp (iPad), matching Collection list
- Search screen `NetworkError` message now mentions that the collection and wishlist remain available offline
- Release Detail `NetworkError` message (when no cached data) now hints to visit the release online to save data for offline viewing
- Barcode scan `_ErrorState` icon colour corrected to `theme.colorScheme.error`; message now explains that an internet connection is needed for Discogs lookups
- `ReleaseDetailScreen` accepts an optional `ThumbnailRepository`; when provided and the screen falls back to cached metadata, the locally cached cover thumbnail is used instead of attempting a `Image.network` call (which fails offline)

### Security
- No tokens or secrets exposed in any new or updated error messages

---

## [Unreleased — Phase 5Q: Retry failed thumbnail cache action] — 2026-06-02

### Added
- `RetryThumbnailUseCase`: looks up cover URL from cached metadata, fetches via HTTP, saves to `ThumbnailRepository` on success, removes retry action; updates `attemptCount` + `lastAttemptedAt` + sets `status=failed` on any HTTP or network failure; result types: `Success`, `NoUrl`, `NetworkError`, `Failed`
- `FailedActionsScreen._ActionCard` now shows a "Retry" `TextButton` for `cacheThumbnail` actions when `thumbnailUseCase` is provided; dispatches to the correct use case per action type; friendly snackbar result messages
- `SettingsScreen` and `HomeShellScreen` now thread `RetryThumbnailUseCase` through the composition root using the shared `AppDatabase` and `LocalCachedReleaseMetadataRepository`

### Security
- No token used or stored — thumbnail fetch is a plain HTTP GET to the cover URL
- `NoUrl` does NOT increment `attemptCount` (missing URL is a permanent condition, not a transient failure)
- All snackbar messages are hardcoded safe strings — no raw errors, no tokens

---

## [Unreleased — Phase 5P: Retry failed metadata refresh] — 2026-06-02

### Added
- `RetryMetadataRefreshUseCase`: loads saved token, calls Discogs API, saves to metadata cache on success, removes retry action; updates `attemptCount` + `lastAttemptedAt` + sets `status=failed` on any API failure; swallows repo update errors; result types: `Success`, `NoToken`, `RateLimited`, `NetworkError`, `Failed`
- `FailedActionsScreen._ActionCard` now shows a "Retry" `TextButton` for `refreshReleaseMetadata` actions only; per-card loading spinner while in flight; shows friendly snackbar result message; reloads action list after retry
- `SettingsScreen` and `HomeShellScreen` now thread `RetryMetadataRefreshUseCase` through the composition root using the shared `AppDatabase`

### Security
- Token is never stored in or returned from `RetryMetadataResult`
- `NoToken` result does NOT increment `attemptCount` (user action required, not a transient failure)
- All snackbar messages are hardcoded safe strings — no raw errors, no tokens

---

## [Unreleased — Phase 5O: Failed Actions screen] — 2026-06-02

### Added
- `FailedActionsScreen`: lists all non-abandoned retry actions (pending + failed); shows friendly action type label, status chip (Queued/Failed), safe error message, attempt count, last tried date, and queued date; empty state "No failed actions — Everything is up to date."; error state with retry button; self-creates `LocalRetryActionRepository` when none injected
- Settings screen now shows a "Failed Actions" list tile that navigates to `FailedActionsScreen`

### Security
- `FailedActionsScreen` displays only `safeErrorMessage` text — never tokens, secrets, or internal details

---

## [Unreleased — Phase 5N: Record failed cache refresh actions] — 2026-06-02

### Added
- `RetryActionType.refreshReleaseMetadata` and `RetryActionType.cacheThumbnail` enum values
- `RetryActionEntityType.cachedRelease` enum value
- `CacheRetryRecorder` service: records pending retry actions for failed metadata refresh (retryable errors only: `NetworkError`, `RateLimitedError`, `DiscogsUnavailableError`) and failed thumbnail caching; deduplicates pending actions by release ID + action type; swallows its own errors
- `DiscogsReleaseDetailService` now accepts an optional `CacheRetryRecorder`; records metadata retry on retryable API failures; records thumbnail retry when fetch returns null for a non-empty cover URL

### Security
- Retry actions store only `safeErrorMessage` strings — never tokens, secrets, or raw API responses
- `CacheRetryRecorder` never propagates errors to callers

---

## [Unreleased — Phase 5M: Add failed action queue model] — 2026-06-02

### Added
- `RetryAction` domain model with fields: `id`, `actionType`, `entityType`, `entityId`, `safeErrorMessage`, `createdAt`, `lastAttemptedAt?`, `attemptCount`, `status`; includes `copyWith` with optional `clearLastAttemptedAt`
- `RetryActionType` enum: `addCollectionItem`, `updateCollectionItem`, `removeCollectionItem`, `addWishlistItem`, `updateWishlistItem`, `removeWishlistItem`
- `RetryActionEntityType` enum: `collectionItem`, `wishlistItem`
- `RetryActionStatus` enum: `pending`, `failed`, `abandoned`
- `RetryActionRepository` abstract interface with `add`, `getAll`, `getById`, `getPending`, `update`, `remove`
- `LocalRetryActionRepository` Drift implementation; `getPending` orders by `createdAt` ascending
- `RetryActions` Drift table; `RetryActionTypeConverter`, `RetryActionEntityTypeConverter`, `RetryActionStatusConverter` type converters
- Schema version bumped to 5; migration creates `retry_actions` table
- 30 new integration tests covering add/getAll/getById/getPending/update/remove, full enum round-trips, and security assertions
- Security: `safeErrorMessage` is an explicit safe string field; no token/secret/header fields on the model

---

## [Unreleased — Phase 5L: Show sync status in Collection and Wishlist details] — 2026-06-02

### Added
- `CollectionDetailScreen` now shows a "Status" row in the info section with friendly wording derived from `syncStatus`
- `WishlistDetailScreen` now shows a "Status" row in the info section with the same wording
- Wording: `localOnly` → "Saved on this device", `synced` → "Synced", `pending` → "Waiting to sync", `failed` → "Sync failed", `conflict` → "Needs review", `offline` → "Offline"
- 12 new widget tests (6 per detail screen) verifying each status label renders correctly

---

## [Unreleased — Phase 5K: Add sync status to local Collection and Wishlist items] — 2026-06-02

### Added
- `CollectionItem` and `WishlistItem` domain models now carry a `syncStatus: SyncStatus` field (optional, defaults to `SyncStatus.localOnly`)
- `CollectionItems` and `WishlistItems` Drift tables gain a nullable `syncStatus` column; existing rows read as `SyncStatus.localOnly`
- `LocalCollectionRepository` and `LocalWishlistRepository` mappers read and write `syncStatus`; null in existing DB rows is treated as `SyncStatus.localOnly`
- `AddToCollectionUseCase` and `AddToWishlistUseCase` now explicitly set `syncStatus: SyncStatus.localOnly` on newly created items
- Schema version bumped to 4; migration adds `syncStatus` column to both tables (nullable `ALTER TABLE ADD COLUMN`)
- 8 new integration/unit tests: 3 sync-status round-trip tests in each repository test and 1 default-value test in each use-case test

---

## [Unreleased — Phase 5J: Use cached thumbnails in local Collection and Wishlist views] — 2026-06-01

### Added
- `CollectionItemCard` and `WishlistItemCard` now accept an optional `ThumbnailRepository`; when a cached path is available they render `Image.file` instead of a placeholder, with `errorBuilder` fallback
- `CollectionScreen`, `CollectionDetailScreen`, `WishlistScreen`, and `WishlistDetailScreen` each accept an optional `ThumbnailRepository`; when not injected they self-create a `LocalThumbnailRepository`; the repository is threaded down to cards and detail screens (including via `_openDetail` navigation)
- `_CachedCoverImage` StatefulWidget (narrow + wide detail cover) in `CollectionDetailScreen` and `WishlistDetailScreen` replaces `Image.network` with a FutureBuilder-based cache lookup; `Image.file` used when path is found, placeholder shown otherwise
- `_LocalCoverThumbnail` StatefulWidget in `CollectionItemCard` and `WishlistItemCard` uses the same FutureBuilder pattern for list thumbnails
- 8 new widget tests covering null-path and non-null-path thumbnail repository behavior across all four screens

---

## [Unreleased — Phase 5I: Cache thumbnails after viewing release detail] — 2026-06-01

### Added
- `DiscogsReleaseDetailService` now accepts an optional `ThumbnailCacheService`; after a successful API fetch it calls `getOrFetch(releaseId, coverUrl)` via `_tryThumbnailCache`; failure is silently swallowed
- `ReleaseDetailScreen` now accepts an optional `ThumbnailCacheService` parameter; when not injected it self-creates one backed by `LocalThumbnailRepository`; the thumbnail service is forwarded to `DiscogsReleaseDetailService`
- 5 new unit tests for thumbnail caching in `DiscogsReleaseDetailService`: fetched after success, save failure swallowed, not called on API error, missing coverUrl safe, works without thumbnail service

---

## [Unreleased — Phase 5H: Thumbnail cache abstraction] — 2026-06-01

### Added
- `ThumbnailRepository` domain interface: `getLocalPath`, `save`, `remove`, `exists` keyed by release ID
- `LocalThumbnailRepository` infrastructure implementation storing files as `thumb_<releaseId>.jpg` under `<appDocumentsDir>/thumbnails/`; accepts injected `Directory` for testing
- `ThumbnailCacheService` application service: `getOrFetch(releaseId, imageUrl?)` returns local path (from cache or after download); returns null on null/empty URL, non-200 response, network error, or save failure; swallows all errors
- 9 unit tests for `ThumbnailCacheService` covering null/empty URL, cache hit, download + save, HTTP errors, network errors, save failure, correct URL forwarded
- 10 integration tests for `LocalThumbnailRepository` using a real temp directory covering null before save, exists, save/read/overwrite, remove, independent IDs

---

## [Unreleased — Phase 5G: Offline fallback for Release Detail screen] — 2026-06-01

### Added
- Release Detail screen now falls back to local cache when the Discogs API call fails for any reason (network error, rate limit, invalid/missing token, etc.)
- `_CachedLoaded` state added to the screen's state machine; maps `CachedReleaseMetadata` to `ReleaseDetail` for display via `_cachedMetadataToDetail`
- `_CachedDetailBody` + `_CachedBanner` widgets display cached content with a clearly labelled "Showing saved data · last updated [date]" banner
- `_cacheRepository` field stored in screen state so the same repository instance is used for both cache writes (after API success) and cache reads (on API failure)
- Add to Collection and Add to Wishlist buttons remain available when showing cached data
- App bar title populated from cached metadata when in cached state
- 10 new widget tests covering: banner shown, date displayed, title/artist from cache, error state when cache empty, all error types fall back, action buttons present, token not shown in banner

### Changed
- 5 existing error-state and retry tests updated to supply `_FakeCacheRepository(cachedMetadata: null)` so they resolve via the fake immediately rather than querying the file-based Drift DB

---

## [Unreleased — Phase 5F: Cache release metadata after loading release detail] — 2026-06-01

### Added
- `DiscogsReleaseDetailService` now accepts an optional `CachedReleaseMetadataRepository`; after a successful Discogs fetch, saves mapped metadata to the local cache
- Cache save failure is swallowed silently so it can never break the detail screen
- `ReleaseDetailScreen` accepts optional `cacheRepository` and wires it into the service it creates; when creating its own `AppDatabase`, it also creates a `LocalCachedReleaseMetadataRepository` automatically
- `SearchScreen` and `HomeShellScreen` thread `cacheRepository` through the screen hierarchy so the single `AppDatabase` in `HomeShellScreen` is used for all cache writes
- 6 new service-layer unit tests covering: saves on success, maps fields correctly, failure resilience, no-save-on-error, token not in cached metadata, works without cache repo

---

## [Unreleased — Phase 5E: Cached release metadata model and storage] — 2026-06-01

### Added
- `lib/domain/models/cached_release_metadata.dart` — `CachedReleaseMetadata` model with all release fields, lists (genres, styles, tracklist, barcodes), fetchedAt, cacheSource, syncStatus
- `lib/domain/repositories/cached_release_metadata_repository.dart` — `CachedReleaseMetadataRepository` interface with `getByReleaseId`, `save` (upsert), `remove`
- `CachedReleases` Drift table in `app_database.dart`; schema bumped to v3 with migration
- `SyncStatusConverter` TypeConverter in `app_database.dart`
- `lib/infrastructure/local_database/local_cached_release_metadata_repository.dart` — local implementation using `insertOnConflictUpdate` for upsert
- 15 integration tests in `test/infrastructure/local_database/local_cached_release_metadata_repository_test.dart`

---

## [Unreleased — Phase 5D: Wishlist explicitly local-first] — 2026-06-01

### Changed
- `_EmptyWishlistState` body text split into two lines: "Your wishlist is saved on this device and works without internet." + "Use the Search tab to find releases and add them." — makes local-first nature explicit
- `_WishlistErrorState` body text updated to "Could not load your wishlist from device storage." — clarifies it is a local storage error
- `_NotFoundBody` (wishlist detail) body text updated to "This item may have been removed from your device storage." — makes local-first nature explicit
- `_ErrorBody` (wishlist detail) body text updated to "Could not load this item from device storage." — clarifies it is a local storage error
- 5 new widget tests added to `test/presentation/screens/wishlist_screen_test.dart` in a `WishlistScreen — local-first` group
- 4 new widget tests added to `test/presentation/screens/wishlist_detail_screen_test.dart` in a `WishlistDetailScreen — local-first` group

---

## [Unreleased — Phase 5C: Collection Detail explicitly local-first] — 2026-06-01

### Changed
- `_NotFoundBody` body text updated to "This item may have been removed from your device storage." — makes local-first nature explicit
- `_ErrorBody` body text updated to "Could not load this item from device storage." — clarifies it is a local storage error
- 4 new widget tests added to `test/presentation/screens/collection_detail_screen_test.dart` in a `CollectionDetailScreen — local-first` group: loads without token, loads without network, not-found state mentions device storage, error state mentions device storage

---

## [Unreleased — Phase 5B: Collection list explicitly local-first] — 2026-06-01

### Changed
- Empty state body text in `CollectionScreen` now states "Your collection is saved on this device and works without internet" — makes offline-first nature explicit
- Added a second line "Use the Search tab to find releases and add them" to guide new users
- Error state message updated from "Could not load your collection." to "Could not load your collection from device storage." — clarifies the error source is local, not network
- 6 new widget tests added to `test/presentation/screens/collection_screen_test.dart` covering explicit local-first properties: loads without token, loads without network, empty state offline messaging, error state device-storage messaging

---

## [Unreleased — Phase 5A: Sync status domain model] — 2026-06-01

### Added
- `SyncStatus` enum in `lib/domain/models/sync_status.dart` with values: `localOnly`, `synced`, `pending`, `failed`, `conflict`, `offline`
- 2 unit tests in `test/domain/models/sync_status_test.dart`: value set coverage + switch exhaustiveness

---

## [Unreleased — Phase 4O: iPad barcode scanner layout] — 2026-06-01

### Changed
- `BarcodeScanScreen` now uses `LayoutBuilder` with `_kWideBreakpoint = 700.0`
- Wide layout (≥700dp, iPad): 360dp left panel (scan area 280dp tall, input field, scan button) + `VerticalDivider` + expanded right panel (results, empty, loading, error states)
- Narrow layout (<700dp, phones): original vertical column layout unchanged
- Scan area widgets (`_ScanAreaPlaceholder`, `_PermissionDeniedScanArea`, `_CameraScanArea`) now accept a `height` parameter (default 160) so the wide layout can request a taller preview

---

## [Unreleased — Phase 4N: iPhone barcode scanner] — 2026-06-01

### Added
- `NSCameraUsageDescription` in `ios/Runner/Info.plist` — required for iOS camera permission dialog

### Changed
- `_isAndroid` guard replaced by `_supportsScanner` (`Platform.isAndroid || Platform.isIOS`) — "Scan barcode" button now activates camera on iPhone and iPad in addition to Android
- `_AndroidScanArea` renamed to `_CameraScanArea` — widget is now used on both Android and iOS
- `_ScanAreaPlaceholder` hint text updated from "Camera preview coming soon" to "Tap 'Scan barcode' to open your camera"

---

## [Unreleased — Phase 4M: Android barcode scanner] — 2026-06-01

### Added
- `mobile_scanner: ^7.2.0` dependency
- Android camera permission (`android.permission.CAMERA`) in `AndroidManifest.xml`
- `_ScanAreaState` enum (`placeholder | scanning | permissionDenied`) controlling scan area widget
- `_AndroidScanArea` — 160dp live camera preview using `MobileScanner`; fires `onDetect` + `onPermissionDenied` callbacks
- `_PermissionDeniedScanArea` — replaces scan area when camera permission is denied; directs user to Settings

### Changed
- "Scan barcode" button now activates Android camera (no-op on iOS/iPadOS, unchanged)
- `_onBarcodeDetected`: fills barcode input with scanned value, closes scanner, triggers lookup
- `_onScannerPermissionDenied`: guarded against duplicate calls; switches scan area to permission denied state

---

## [Unreleased — Phase 4L: Connect manual barcode input to lookup] — 2026-06-01

### Changed
- `BarcodeScanScreen` wired to `BarcodeLookupUseCase`; fake result data removed
- `_onSearch` is now `async`; sets loading state before awaiting use case, guards with `mounted` check
- State machine expanded: `_Idle` / `_Loading` / `_HasResults` / `_NoResults` / `_NoToken` / `_RateLimited` / `_LookupError`

### Added
- `_LoadingIndicator` — `CircularProgressIndicator` centered while use case is pending
- `_NoResultsState` — "No releases found" with hint to check barcode number
- `_NoTokenState` — "Discogs account not connected"; directs user to Settings
- `_RateLimitedState` — "Too many requests"; friendly retry prompt
- `_ErrorState` — "Something went wrong"; check connection prompt
- `BarcodeScanScreen(useCase:)` optional parameter for test injection; defaults to `BarcodeLookupUseCase()` in `initState`
- 21 widget tests in `barcode_scan_screen_test.dart` (rewrote all 16 Phase 4K tests + 5 new state tests)

---

## [Unreleased — Phase 4K: Barcode scan screen UI] — 2026-06-01

### Added
- `BarcodeScanScreen` replaced with full `StatefulWidget` layout
- `_ScanAreaPlaceholder` — decorative 160dp container with scanner icon and "Camera preview coming soon" label
- Manual barcode `TextField` (`barcode-input`) with `OutlineInputBorder` and search action
- "Search" `FilledButton` (`search-barcode-button`) — triggers fake result lookup on non-empty input
- "Scan barcode" `OutlinedButton.icon` (`scan-barcode-button`) — placeholder for future camera integration; tap does nothing
- `_EmptyState` — idle state with QR icon, title "Scan or enter a barcode", and usage hint
- `_ResultsList` — `ListView.separated` of `ReleaseSearchResultCard`; shows artist, title, format, label, year, country, Discogs release ID
- 3 fake `ReleaseSearchResult` entries (Miles Davis – Kind Of Blue, multiple pressings) shown on any non-empty search
- Whitespace-only barcode treated as empty (stays idle)
- Keyboard `TextInputAction.search` submits same as button tap
- 16 widget tests in `barcode_scan_screen_test.dart`

---

## [Unreleased — Phase 4J: Barcode lookup use case] — 2026-06-01

### Added
- `DiscogsApiClient.searchByBarcode(barcode, token)` — searches `/database/search` with `barcode=` query parameter (distinct from `q=`; uses the Discogs barcode identifier field)
- `BarcodeLookupUseCase` with `execute(String barcode) → Future<BarcodeLookupResult>`
- `BarcodeLookupResult` sealed class: `BarcodeLookupSuccess(results)`, `BarcodeLookupNoResults`, `BarcodeLookupEmptyInput`, `BarcodeLookupNoToken`, `BarcodeLookupRateLimited`, `BarcodeLookupError(error)`
- Input validation: trims whitespace; returns `BarcodeLookupEmptyInput` when blank
- Token loaded safely via `TokenStorage`; `BarcodeLookupNoToken` returned when absent; token never logged or surfaced in error types
- 19 unit tests: 5 `DiscogsApiClient.searchByBarcode` tests + 14 `BarcodeLookupUseCase` tests

---

## [Unreleased — Phase 4I: Remove wishlist item] — 2026-06-01

### Added
- `WishlistDetailScreen` overflow `PopupMenuButton` (`detail-overflow-menu`) in AppBar when loaded
- "Remove from wishlist" `PopupMenuItem` opens `AlertDialog` confirmation; dialog states Discogs is not affected
- Cancel button (`cancel-remove-button`) dismisses dialog without calling `repository.remove`
- Confirm button (`confirm-remove-button`) calls `repository.remove(item.id)` and navigates back on success
- Remove failure shows snackbar "Could not remove item. Please try again." and stays on screen
- 9 widget tests in `wishlist_detail_screen_test.dart`: overflow menu visibility, remove option, dialog, Discogs mention, cancel, confirm, navigate back, error snackbar

---

## [Unreleased — Phase 4H: Edit wishlist item fields] — 2026-06-01

### Added
- `WishlistDetailScreen` AppBar actions when loaded: Edit Priority (`tune` icon), Edit Target Price (`sell_outlined` icon), Edit Notes (`edit_note` icon)
- `_EditPrioritySheet`: bottom sheet with `DropdownButtonFormField<WishlistPriority>`; saves via `repository.update`; success snackbar "Priority saved."
- `_EditTargetPriceSheet`: bottom sheet with numeric `TextFormField`; validates input as double; empty clears target price to null (shows "Not set"); inline validation error for non-numeric input; success snackbar "Target price saved."
- `_EditNotesSheet`: bottom sheet with multiline `TextFormField`; clearing text hides notes section on save; success snackbar "Notes saved."
- All three sheets show "Could not save…" error inline and keep sheet open on `repository.update` failure
- `WishlistItem.copyWith` gains `clearTargetPrice` bool parameter to allow clearing `targetPrice` to `null`
- 17 widget tests in `wishlist_detail_screen_test.dart`: edit buttons (3), edit priority (4), edit target price (5), edit notes (5)

### Changed
- `WishlistItem.copyWith` now uses `clearTargetPrice ? null : (targetPrice ?? this.targetPrice)` for the target price field

---

## [Unreleased — Phase 4G: Wishlist detail route and data] — 2026-06-01

### Added
- `WishlistDetailScreen`: loads a `WishlistItem` by ID from `WishlistRepository`; shows loading / not-found / error / loaded states; 2-column layout on screens ≥700dp
- Loaded view shows: cover image (full-width on narrow, 300dp column on wide), artist, title, label/catno combined, format, country, year, priority label, target price (or "Not set"), notes section (hidden when empty), and added/updated dates
- `WishlistScreen._WishlistList` passes `WishlistRepository` down; tapping any `WishlistItemCard` pushes `WishlistDetailScreen` with the item's ID and shared repository
- 24 widget tests in `wishlist_detail_screen_test.dart`: loading (2), not-found (2), error+retry (4), header (2), mandatory fields (5), optional fields (7), notes (3)
- 3 navigation tests added to `wishlist_screen_test.dart`: tap opens detail, data passes correctly, back navigation returns to list

### Changed
- `WishlistScreen._WishlistList` gains required `repository` param and wires `WishlistItemCard.onTap` to open `WishlistDetailScreen`

---

## [Unreleased — Phase 4F: Add to Wishlist button] — 2026-06-01

### Added
- `_AddActionsBar` widget: two-button bar in `ReleaseDetailScreen.bottomNavigationBar` showing "Add to Collection" (`FilledButton.icon`) and "Add to Wishlist" (`OutlinedButton.icon`) stacked vertically
- `_addWishlistState` field (`_AddState` enum) in `_ReleaseDetailScreenState` with idle/adding/added/duplicate states
- `_handleAddToWishlist()` method: calls `AddToWishlistUseCase`, shows snackbar ("Added to your wishlist" or "Already in your wishlist"), updates button state
- `AddToWishlistUseCase` threaded through `HomeShellScreen → SearchScreen → _ResultsList → ReleaseDetailScreen`
- 8 new widget tests for the wishlist button (present/absent, snackbars, label transitions, disabled state)

### Changed
- `ReleaseDetailScreen` gains optional `addToWishlistUseCase` param; falls back to `LocalWishlistRepository` sharing the owned `AppDatabase`
- `SearchScreen` gains optional `addToWishlistUseCase` param; threads to `ReleaseDetailScreen`
- `_AddToCollectionBar` replaced by `_AddActionsBar` (collection button behavior unchanged)

---

## [Unreleased — Phase 4E: add to wishlist use case] — 2026-06-01

### Added
- `AddToWishlistUseCase` with `execute(ReleaseDetail)` method
- `AddToWishlistResult` sealed class: `AddToWishlistSuccess(item)` and `AddToWishlistDuplicate`
- Duplicate prevention via `WishlistRepository.containsRelease`; empty string release fields coerced to null
- 18 unit tests covering success path, default field values (priority=medium, targetPrice=null, notes=null), empty-string coercion, and duplicate prevention

---

## [Unreleased — Phase 4D: connect wishlist list to storage] — 2026-06-01

### Added
- `WishlistScreen` converted to `StatefulWidget` with loading/empty/error/list states
- `_WishlistErrorState` widget with retry button
- `_WishlistList` extracted widget wrapping the `ListView.separated`
- 8 new widget tests covering loading state, error state, retry recovery, and list loading from repository

### Changed
- `WishlistScreen` parameter changed from `items: List<WishlistItem>?` to `repository: WishlistRepository?`; fake static data removed
- `HomeShellScreen` creates a `LocalWishlistRepository` sharing the owned `AppDatabase` and passes it to `WishlistScreen`

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
