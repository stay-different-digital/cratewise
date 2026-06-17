# Known Limitations — Phases 1 through 6

All known limitations recorded at the end of each implementation slice, in chronological order.
Items marked ✅ were resolved in a later slice. Items with no mark remain open.

**Beta importance key:** XL = must fix before beta · L = should fix · M = consider · S = defer post-beta  
**Story points:** 1 ≈ 2 h · 2 ≈ half day · 3 ≈ 1 day · 5 ≈ 2–3 days · 8 ≈ 1 week · 13 = needs breakdown

---

## Phase 1 — Technical Foundation

### Navigation & shell

- No deep linking. GoRouter is not wired up. `AppRoutes` constants are defined but unused — `MaterialApp.home` drives navigation. — **Beta: S · 8 SP**
- `IndexedStack` keeps all 5 screens alive. Fine for placeholders; will need review once screens have real state or heavy widgets. — **Beta: M · 3 SP**
- No named routing — both `releaseDetail` and `collectionDetail` use `MaterialPageRoute` directly throughout the app. — **Beta: S · 8 SP** *(included in GoRouter migration)*

### Platform

- No `SafeArea` in individual screens. The shell `Scaffold` handles safe area via `body`; per-screen `SafeArea` may be needed when screens have their own scroll views. — **Beta: M · 2 SP**

---

## Phase 2 — Discogs MVP

### 2A — Token input UI

- ✅ Token is in-memory only. Entering a token and navigating away discards it.
- The help text URL (`discogs.com/settings/developers`) is plain text; users can't tap to open it. Needs `url_launcher`. — **Beta: S · 1 SP**
- ✅ Validate button was a noop — becomes enabled when text is present but did nothing until the next slice.
- No input length or format hints. Discogs personal access tokens have a fixed format; a `maxLength` or inline hint could improve UX. — **Beta: S · 1 SP**

### 2B — Discogs API client

- ✅ `fetchIdentity` was the only endpoint; no search, release, or collection endpoints.
- Rate limit headers (`X-Discogs-Ratelimit-Remaining`) are not read — only the 429 status code is used. — **Beta: M · 3 SP**
- No request timeout configured on the HTTP client. — **Beta: XL · 2 SP**

### 2C — Token validation UI

- ✅ Token was held in `TextEditingController` (in-memory); closing the Settings screen discarded it.
- No HTTP request timeout — a stalled Discogs response holds the loading state indefinitely. — **Beta: XL · 2 SP** *(same fix as 2B)*
- The "token absent from error messages" test checks rendered `Text` widgets; a future error path using `RichText` directly would bypass the assertion. — **Beta: S · 1 SP**

### 2D — Secure token storage

- No HTTP request timeout — a stalled Discogs response holds the loading state indefinitely. — **Beta: XL · 2 SP** *(same fix as 2B)*
- `DiscogsTokenStorage` stores token and username as two separate `write` calls. A crash between the two leaves partially saved credentials — next `loadStatus` returns connected with the username but the token key is missing. — **Beta: M · 3 SP**
- `flutter_secure_storage` requires CocoaPods for iOS and has not yet adopted Swift Package Manager (cosmetic warning logged, functionality unaffected). — **Beta: S · 0 SP** *(cosmetic warning, no user impact)*

### 2E — Search screen (static)

- ✅ Fake results were always the same 5 releases regardless of query.
- ✅ Cover placeholder was a static icon; no image loading.
- ✅ No loading or error state on the search screen.
- ✅ No debounce — intentionally deferred.

### 2F — Search API method

- No pagination — only the first page of results is returned. — **Beta: L · 5 SP**
- Artist split on first ` - ` is wrong for releases whose artist name contains ` - ` (e.g., `"A - B - C"` parses as artist `A`, title `B - C`). — **Beta: S · 2 SP**
- ✅ `searchReleases` was not yet called from any screen.

### 2G — Search screen (live API)

- ✅ No debounce — each keyboard submit fired a full API call.
- No pagination — only the first page of results (20 items) is shown. — **Beta: L · 5 SP** *(same fix as 2F)*
- Cover images load synchronously with no caching (`cached_network_image` would be better). — **Beta: S · 3 SP**
- If a token is saved but has since been revoked, the user sees an error with no automatic disconnect. — **Beta: M · 3 SP**

### 2H — Debounce & dedup

- No in-flight request cancellation — if a slow API response arrives after the user changes the query, the stale result is discarded but the HTTP round-trip still completes. — **Beta: S · 3 SP**
- Only the first page of results (20 items) is shown — no pagination. — **Beta: L · 5 SP** *(same fix as 2F)*
- No caching — the same query typed again after clearing fires a fresh API call. — **Beta: S · 5 SP**

### 2I — Release detail placeholder

- Navigating from the wide (nav-rail) layout pushes a full-screen detail — the nav rail disappears. A nested `Navigator` per tab would fix this. — **Beta: M · 5 SP**
- `ReleaseDetailScreen` shows only the Discogs ID; artist/title from the search result are not passed through. — **Beta: L · 1 SP**

### 2J — Release detail API

- ANV (artist name variation, `anv` field) is ignored — the credited name may differ on some pressings. — **Beta: S · 2 SP**
- Format uses only the first `formats` entry; multi-format releases show only the primary format. — **Beta: S · 2 SP**
- Cover image uses full-size `uri`, not `uri150` thumbnail. — **Beta: L · 2 SP**

### 2K — Release detail screen

- ✅ Cover image used full-resolution `uri` from the Discogs API — can be slow on mobile.
- No pull-to-refresh; errors require navigating back and re-tapping the card. — **Beta: L · 3 SP**
- The app bar title is always "Release Detail" regardless of the loaded album title. — **Beta: L · 1 SP**
- Identifiers are shown as a flat list without filtering; releases with many matrix/runout entries may be noisy. — **Beta: S · 2 SP**

### 2L — Release detail states & iPad polish

- ✅ Skeleton loading body is always single-column regardless of screen width.
- ✅ Cover image still used full-resolution `uri`.
- Retry button resets to loading and re-fetches immediately; there is no back-off delay for rate-limited errors. — **Beta: S · 2 SP**

---

## Phase 3 — Collection MVP

### 3A — Collection data model

- `id` is an unvalidated `String`; UUID format is not enforced at the domain layer. — **Beta: S · 1 SP**
- `copyWith` cannot clear nullable fields to `null` (standard Dart limitation); a sentinel pattern would be needed if that use case arises. — **Beta: S · 2 SP**
- No `==`/`hashCode` on `CollectionItem` — equality checks in tests compare by reference. — **Beta: M · 2 SP**

### 3B — Local collection storage

- `app_database.g.dart` is a generated file — must re-run `dart run build_runner build` when the schema changes. — **Beta: S · 0 SP** *(developer workflow, no user impact)*
- `openAppDatabase()` uses `getApplicationDocumentsDirectory()` which requires the platform to be initialized; only safe to call from `main.dart`. — **Beta: S · 1 SP**

### 3C — Add to collection use case

- Default condition is `veryGood` — a guess; the UI should let users change it immediately after adding. — **Beta: M · 2 SP**
- `createdAt`/`updatedAt` use `DateTime.now()` with no clock abstraction, so tests can't verify exact timestamps. — **Beta: S · 1 SP**

### 3D — Add to collection button

- ✅ Each `ReleaseDetailScreen` instance created its own `AppDatabase` when no use case was injected.
- No proactive "already in collection" check on screen load — the button always starts as "Add to Collection" even if the item was added in a previous session. — **Beta: L · 3 SP**

### 3E — Collection list UI

- ✅ Fake data was hard-coded.
- Search field is decorative only — typing doesn't filter the list. — **Beta: L · 5 SP**

### 3F — Connect collection list to storage

- No live refresh: items added from `ReleaseDetailScreen` won't appear in the collection list until the screen is rebuilt. — **Beta: L · 3 SP**

### 3G — Collection detail route

- No named routing — `AppRoutes.collectionDetail` constant exists but uses `MaterialPageRoute` directly. — **Beta: S · 8 SP** *(included in GoRouter migration)*

### 3H — Collection detail data

- No live reload when items change elsewhere (e.g., added from `ReleaseDetailScreen` while detail is open). — **Beta: S · 3 SP**
- Cover image in collection detail uses `Image.network` — requires connectivity. — **Beta: M · 3 SP**
- Dates are formatted as `YYYY-MM-DD` with no `intl` localization. — **Beta: S · 3 SP**

### 3I — Edit conditions

- ✅ AppBar accumulated 4 icon buttons (edit conditions, notes, tags, storage) — a future slice should consolidate into a single edit flow or overflow menu.

### 3M — Offline collection view polish

- ✅ Collection list had no grid layout on iPad — added in this slice.

---

## Phase 4 — Wishlist & Barcode

### 4 — Wishlist

- `WishlistItem.copyWith` cannot clear nullable fields to `null` — the `clearTargetPrice` sentinel workaround was added, but the pattern is inconsistent with other models. — **Beta: S · 2 SP**
- Wishlist list has no search/filter field. — **Beta: L · 5 SP**
- Wishlist items have no "already in wishlist" check on screen load when adding from release detail. — **Beta: L · 3 SP**

### 4 — Barcode scanner

- The barcode scan area is a full-page overlay on phone; there is no in-app scan overlay (e.g., a viewfinder crosshair) on the results list while scanning is active. — **Beta: S · 3 SP**
- Manual barcode entry has no format validation — any string is sent to the Discogs barcode search. — **Beta: S · 2 SP**
- Barcode scanner on iPad uses the same phone layout for the narrow breakpoint (`<700dp`); the wide layout allocates a fixed 360dp left panel which may feel cramped on some iPad orientations. — **Beta: S · 2 SP**
- No flashlight/torch toggle in the camera scan area. — **Beta: S · 2 SP**
- Scanning is disabled on web and desktop (guarded by `Platform.isAndroid || Platform.isIOS`); there is no graceful fallback message on those platforms. — **Beta: S · 1 SP** *(out-of-scope platforms)*

---

## Phase 5 — Offline & Sync

### 5 — Cached release metadata

- Cache failure is silently swallowed — if saving metadata after a successful Discogs fetch fails, the next screen load will re-fetch from the network. — **Beta: M · 2 SP**
- The cached-banner UI shows "viewing saved data" with no timestamp indicating how old the cache is. — **Beta: S · 1 SP**
- `CachedReleaseMetadata` stores only a subset of release fields; the cached detail view is missing tracklist, identifiers, and notes that are in the full API response. — **Beta: M · 5 SP**

### 5 — Thumbnail cache

- Thumbnail cache stores files in `<appDocumentsDir>/thumbnails/` with no size limit or eviction policy — can grow unbounded over time. — **Beta: M · 3 SP**
- All thumbnail cache errors are swallowed; a failed cache write is silent with no retry recorded. — **Beta: S · 2 SP**
- `ThumbnailCacheService.getOrFetch` re-downloads from the network on every call if the local file doesn't exist yet, with no in-progress deduplication. — **Beta: S · 3 SP**

### 5 — Sync status

- `SyncStatus` is stored as a plain integer column; there is no migration guard if enum values are reordered. — **Beta: M · 2 SP**
- Items imported from Discogs are saved with `SyncStatus.synced`; items added manually (from search/barcode) are `localOnly`. There is no UI affordance to promote a `localOnly` item to `synced` without a full re-import. — **Beta: M · 3 SP**

### 5 — Failed action queue

- Retry actions are per action type (`refreshReleaseMetadata`, `cacheThumbnail`) only; a failed collection/wishlist write has no retry entry. — **Beta: M · 5 SP**
- The Failed Actions screen has no "retry all" button — each retry is per-card. — **Beta: S · 1 SP**
- `RetryAction` records have no TTL or automatic expiry; failed actions accumulate indefinitely unless cleared manually. — **Beta: S · 2 SP**
- There is no "clear all failed actions" option on the screen. — **Beta: S · 1 SP**
- Duplicate prevention for retry actions is keyed on `(entityId, actionType)` — a single release can have at most one pending metadata refresh and one thumbnail cache action at a time. — **Beta: S · 1 SP**

---

## Phase 6 — Import & Export

### 6A — Import/Export screen shell

- `SettingsScreen` is not directly widget-tested (it contains `DiscogsTokenSection` which requires platform channels); the Import & Export tile is covered only by manual navigation testing. — **Beta: S · 3 SP**
- The `SliverGrid` card extent is fixed at `mainAxisExtent: 96`; very long action titles in future localization could overflow. — **Beta: S · 1 SP**

### 6B — Discogs collection import API method

- `fetchCollectionPage` requires the caller to already know the username (obtained from `fetchIdentity` separately). — **Beta: S · 2 SP**
- No auto-pagination helper — the caller must call `fetchCollectionPage` once per page and concatenate results. — **Beta: M · 3 SP**

### 6C — Collection import preview builder

- The preview use case accepts an already-fetched list of DTOs; the caller is responsible for paginating. If the caller passes partial data (e.g., only the first page fetched before hitting a rate limit), the preview reflects only those items. — **Beta: M · 3 SP**
- No rate-limit awareness during the paginated fetch — large collections may silently truncate if a 429 interrupts pagination mid-way. — **Beta: M · 3 SP**

### 6 — Discogs collection export

- `CheckCollectionExportCapabilityUseCase` always returns `CollectionExportNotSupported` — Discogs write API for collection folders is not implemented. — **Beta: S · 0 SP** *(blocked by Discogs API — intentional)*
- No progress indicator showing per-item progress during a large collection export. — **Beta: S · 2 SP**
- No rate-limit backoff between per-item export API calls — large exports may hit Discogs 429 limits. — **Beta: M · 3 SP**

### 6 — Discogs wishlist export

- No rate-limit backoff between items — large wishlists may hit Discogs 429 limits. — **Beta: M · 3 SP**
- No per-item progress indicator during export. — **Beta: S · 2 SP**
- If `getById` or `update` fails when marking an exported item as `failed`, the sync status is silently left unchanged (the `FailedRow` is still recorded in the job). Intentional — a double-failure path shouldn't block the overall export loop. — **Beta: S · 0 SP** *(intentional design)*

### 6 — CSV export mappers

- Tags are pipe-joined (`|`) in CSV; the import validator accepts this encoding, but third-party tools opening the CSV will see raw pipe characters. — **Beta: S · 1 SP**
- No batch export method; callers map over items individually. — **Beta: S · 2 SP**
- The `csv` package does not add a BOM — this can cause Excel on Windows to misread non-ASCII characters in artist/title fields. — **Beta: M · 1 SP**

### 6 — CSV export to file

- The share sheet is fire-and-forget: if the user dismisses it without saving, the CSV remains in the temp directory but the success screen still shows (correct — the file was generated successfully). — **Beta: S · 0 SP** *(by design)*
- No "Share again" button on the export success screen. — **Beta: S · 1 SP**
- Exported CSV files accumulate in the temp directory; there is no cleanup mechanism. — **Beta: S · 2 SP**

### 6 — CSV import parser

- `CsvParseFailure` is only returned for catastrophic parse errors — the `csv` package's `allowInvalid: true` default means malformed CSV is parsed leniently rather than rejected outright. — **Beta: M · 2 SP**
- The parser does not validate that the column count in data rows matches the header count; short rows receive empty strings for missing columns. — **Beta: S · 1 SP**
- In-file duplicate detection uses the first occurrence of a release ID — if the first row fails validation, later rows with the same ID are still skipped. — **Beta: S · 2 SP**

### 6 — CSV import preview UI

- `CsvFilePickerService` reads the entire file into memory via `withData: true`; very large CSV files could be memory-intensive. — **Beta: S · 3 SP**
- The native file picker is not testable in widget tests; tests inject a fake `onPickFile` callback instead. — **Beta: S · 0 SP** *(by design)*

### 6 — Sync status on import/export

- If `getById` or `update` fails when marking an item's sync status as `failed` after a failed export, the sync status is silently left unchanged while the `FailedRow` is still recorded in the job. — **Beta: S · 0 SP** *(intentional design)*

### 6ZC — Import/export history screen

- The history list is capped at the 20 most recent jobs (`getRecent(limit: 20)`); no pagination. — **Beta: S · 3 SP**
- No way to delete individual history entries from this screen. — **Beta: S · 2 SP**
- The `completedWithErrors` status chip uses `secondaryContainer` which may appear similar to a success chip depending on the device's M3 color theme. — **Beta: S · 1 SP**

### 6Z — Import/export UI polish (final)

- iPad landscape layout is constrained to 560px only for centered error/empty/idle states; import and export preview bodies (with the side-by-side card layout) remain unconstrained and use the full width. — **Beta: S · 2 SP**
- The empty-source note in the Discogs import summary card appears even when the user has items in other sections of the page (e.g., empty Discogs collection but local collection has duplicates); this is intentional since the note is about the Discogs source being empty. — **Beta: S · 0 SP** *(intentional design)*

---

## Cross-cutting / Open items

These limitations span multiple phases or were never assigned to a specific slice.

- **No dependency injection framework.** There is no Riverpod (or equivalent) wiring; screens create their own `AppDatabase` instances in production and accept injected fakes in tests. This works but makes it hard to guarantee a single shared database instance across all screens. — **Beta: M · 8 SP**
- **No request timeout on Discogs HTTP calls.** A stalled network response can hold any loading state indefinitely with no user-visible timeout or cancel option. — **Beta: XL · 2 SP**
- **No search pagination.** All Discogs search screens (text search and barcode lookup) return only the first page (20 results). — **Beta: L · 5 SP**
- **No pull-to-refresh.** Error states on Release Detail, Collection, and Wishlist screens require navigating back and re-entering the screen to retry. — **Beta: L · 3 SP**
- **No localized date formatting.** Dates throughout the app are displayed as `YYYY-MM-DD` with no `intl` package integration. — **Beta: S · 3 SP**
- **No GoRouter / deep linking.** All navigation uses `Navigator.push` with constructor params; named routes and deep links are not supported. — **Beta: S · 8 SP**
- **iOS Keychain bug (open).** `SaveCredentials` on iOS can fail silently with a StorageError. A debug log was added to `DiscogsTokenStorage.saveCredentials` to surface the Keychain error code; the fix is pending a confirmed error code from user reproduction. — **Beta: XL · 3 SP**

---

## Platform dependency warnings

Warnings produced at build time that are not a current blocker but must be monitored before each release. See the release checklist for the standing check.

### Android — Kotlin Gradle Plugin (KGP) legacy API

**Warning:** Several Flutter plugins use the older Kotlin Gradle Plugin apply-style API instead of the `plugins {}` block required by AGP 8+. The warning reads: *"The following Kotlin source sets were configured but not matched by any Kotlin compilation"*.

- **Impact:** Build warning only; no runtime effect. Will become a build error when AGP drops compatibility for the legacy API.
- **Root cause:** Upstream Flutter plugins (e.g. `flutter_secure_storage`, `sqflite`) have not yet migrated their Gradle configuration.
- **Workaround:** None needed today. The warning can be suppressed per-module if it becomes noisy, but that hides future errors.
- **Upstream tracking:** Monitor each affected plugin's GitHub releases. When the plugin ships a KGP-migrated version, bump the dependency.
- **Expected fix:** When upstream plugins publish KGP-compatible releases (anticipated with their next major version bumps).

### iOS — `flutter_secure_storage` does not support Swift Package Manager (SPM)

**Warning:** Xcode 15+ prefers SPM-based dependencies. `flutter_secure_storage` still uses CocoaPods only.

- **Impact:** Build warning; CocoaPods integration continues to work. Will become a blocker if Apple enforces SPM-only distribution or if Flutter removes CocoaPods support.
- **Root cause:** `flutter_secure_storage` upstream has an open issue for SPM support.
- **Workaround:** Continue using CocoaPods (`pod install` is part of the build pipeline).
- **Upstream tracking:** https://github.com/mogol/flutter_secure_storage/issues — watch for an SPM-compatible release.
- **Expected fix:** When `flutter_secure_storage` publishes an SPM-compatible release.
