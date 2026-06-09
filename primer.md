# Cratewise — Session Primer

**Date:** 2026-06-09  
**Test count:** 2168/2168 passing  
**Last completed phase:** 8M (US-40)

---

## What has been built

### App overview
Cratewise is a Flutter vinyl record collection manager with local-first storage (Drift/SQLite), Discogs API integration, barcode scanning, CSV import/export, and offline fallback. Target: Android + iOS, phone + iPad.

### Phase summary (all complete, all tests green)

| Phase | User Story | Summary |
|-------|-----------|---------|
| 1–2 | — | Token input, Discogs API client, search, release detail |
| 3 | — | Local collection (Drift), add/edit/remove items, collection list + detail |
| 4 | — | Wishlist, barcode scanner (mobile_scanner), iPad layout |
| 5 | — | Sync status, metadata cache, thumbnail cache, failed action queue, retry use cases, offline fallback |
| 6 | — | Import/export domain + UI: Discogs collection/wishlist import+export, CSV import+export, history screen |
| 7A–7Z | US-01–27 | HTTP timeout, iOS Keychain guard, search pagination, pull-to-refresh, app bar titles, search context on detail, uri150 thumbnails, "In Collection/Wishlist" indicators, collection/wishlist search+filter, collection live-refresh (RouteObserver), split-pane search on iPad, token revocation auto-clear, atomic credential save, rate-limit header back-off, condition prompt on add, full cached offline detail, thumbnail eviction (200 MB LRU), silent cache retry, Discogs-link promotion on import, failed-write retry queue, mid-pagination rate-limit retry, per-item export rate-limit retry, CSV BOM for Excel, safe area on all scrollable screens |
| 8A–8I | US-28–36 | GoRouter deep linking, tappable help URL, token format hint, artist dash parsing, ANV display, multi-format entries, rate-limit retry countdown button, collection detail live-reload on pop, locale-aware date formatting (intl) |

### Key architecture points
- **Router:** GoRouter (`lib/app/router.dart`), `StatefulShellRoute.indexedStack` for 5 tabs. `AppRoutes` constants for all paths.
- **RouteObserver:** `appRouteObserver` in `lib/shared/route_observer.dart`. Registered on the Collection branch navigator only (in `router.dart`'s `StatefulShellBranch.observers`). Used by `CollectionScreen` (list live-refresh) and `CollectionDetailScreen` (detail live-reload) via `RouteAware` mixin.
- **Database:** Drift `AppDatabase`, schema v8. Tables: CollectionItems, WishlistItems, CachedReleases, RetryActions, ImportExportJobs, ImportExportRowResults.
- **Security invariants (AGENTS.md — never violate):** Never hardcode/log/show Discogs tokens. Store only via `flutter_secure_storage`. No raw errors in user-facing strings.

---

## Current working-tree state

All changes since Phase 5 (thumbnails) are **uncommitted**. The git history ends at "cache cover thumbnails after viewing release details" (commit `62e4e2f`). The working tree contains all Phase 5–8H changes across ~100+ files, all unstaged. No commits have been made during the AI-assisted sessions.

Files currently showing as modified in `git status` (a subset — most are from earlier phases):
- `lib/presentation/screens/collection_detail_screen.dart` — Phase 8H (RouteAware live-reload)
- `lib/presentation/screens/collection_screen.dart` — Phase 8A (GoRouter)
- `lib/presentation/screens/wishlist_detail_screen.dart` — Phase 7Z (SafeArea)
- `lib/presentation/screens/wishlist_screen.dart` — Phase 8A (GoRouter)
- `lib/presentation/widgets/collection_item_card.dart` — Phase 7-era changes
- `lib/presentation/widgets/wishlist_item_card.dart` — Phase 7-era changes
- Corresponding test files for all of the above

**To verify all tests still pass:** `flutter test --no-pub`

---

## What is currently blocked

Nothing is technically blocked. There are no known failing tests, no broken builds, no unresolved merge conflicts.

The one structural note: `WishlistDetailScreen` does NOT have live-reload on pop (US-35 was scoped to Collection detail only, and the Wishlist branch has no `appRouteObserver` in its `StatefulShellBranch`). This is intentional — extending it would require a second route observer instance.

---

## Remaining user stories (US-36 onwards)

All from `docs/user-stories/beta-user-stories-s.md`. Listed in order, with story points:

| # | Story | SP | Summary |
|---|-------|----|---------|
| ~~US-36~~ | ~~Dates displayed in the device's locale format~~ | ~~3~~ | **Done (Phase 8I).** intl 0.20.2; `formatDate`/`formatDateTime` in `lib/shared/utils/date_format_utils.dart`; 5 screens updated; 2149 tests. |
| ~~US-37~~ | ~~Barcode scan area shows a viewfinder frame~~ | ~~3~~ | **Done (Phase 8J).** `_ViewfinderOverlay`/`_ViewfinderPainter` in `barcode_scan_screen.dart`; 2151 tests. |
| ~~US-38~~ | ~~Manual barcode entry validates format~~ | ~~2~~ | **Done (Phase 8K).** `_validateBarcode` + `_canSearch` + `_onInputChanged` listener; inline `errorText`; Search button disabled while invalid; 2162 tests. |
| ~~US-39~~ | ~~Barcode scanner uses wide two-panel layout on iPad~~ | ~~2~~ | **Done (Phase 8L).** `Expanded(flex:2)` left + `Expanded(flex:3)` right; `_isWide` tracked in `LayoutBuilder`; camera stays live after scan in wide mode; 2166 tests. |
| ~~US-40~~ | ~~Camera scan area has flashlight toggle~~ | ~~2~~ | **Done (Phase 8M).** `_CameraScanArea` → `StatefulWidget`; `MobileScannerController` owned + disposed; `_TorchToggleButton` overlaid top-right; hidden when `TorchState.unavailable`; 2168 tests. |
| US-41 | Cached release detail banner shows data age | 1 | Banner always shows date without truncation; >30-day data uses warning colour |
| US-42 | Failed action queue entries expire after configurable period | 2 | TTL (default 30 days) auto-deletes `failed` entries on launch; `pending` entries exempt |

**Recommended next task: US-41 (1 SP)** — cached release detail banner shows data age (>30 days → warning colour).

### US-37 implementation notes
- Draw a centered rectangular overlay on the camera preview in `BarcodeScanScreen`
- Use `CustomPaint` or a `Stack` with positioned decorative corner brackets (white/green lines, not a filled box)
- Overlay should adapt to both the narrow (phone) scan area and the wide (iPad) scan area; the scan area widget already uses a `height` parameter
- No new package required — `CustomPainter` in Flutter can draw the brackets natively
- Tests: widget test that the overlay `Key` is present when the camera is active (not just when in placeholder state)

---

## How to continue

1. Read `AGENTS.md` (security rules and coding conventions — required reading before any PR)
2. Read relevant docs in `docs/product`, `docs/architecture`, `docs/user-stories`
3. Pick up US-36 and implement
4. Run `flutter test --no-pub` after each change; run `dart format .` before reporting complete
5. Update `CHANGELOG.md` with a new `## [Unreleased — Phase 8I: ...]` entry
6. Update `memory/project_phase_progress.md` and `memory/MEMORY.md`
