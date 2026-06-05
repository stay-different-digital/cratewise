# Cratewise — Session Primer

**Date:** 2026-06-05  
**Test count:** 2141/2141 passing  
**Last completed phase:** 8H (US-35)

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
| 8A–8H | US-28–35 | GoRouter deep linking, tappable help URL, token format hint, artist dash parsing, ANV display, multi-format entries, rate-limit retry countdown button, collection detail live-reload on pop |

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
| **US-36** | **Dates displayed in the device's locale format** | **3** | All user-visible dates use `intl` package with device locale. Affects collection/wishlist added/updated dates, import/export job dates, cached-data banner date. Release year (plain int) unaffected. |
| US-37 | Barcode scan area shows a viewfinder frame | 3 | Rectangular overlay on camera preview; bracket corners; adapts to phone/iPad sizes |
| US-38 | Manual barcode entry validates format | 2 | Numeric-only, 8/12/13 digit length check; inline error; search button disabled while invalid |
| US-39 | Barcode scanner uses wide two-panel layout on iPad | 2 | ≥700dp: camera left, results right; left panel proportional, not fixed 360dp |
| US-40 | Camera scan area has flashlight toggle | 2 | Torch on/off button; icon reflects state; torch off on deactivate; graceful if no torch |
| US-41 | Cached release detail banner shows data age | 1 | Banner always shows date without truncation; >30-day data uses warning colour |
| US-42 | Failed action queue entries expire after configurable period | 2 | TTL (default 30 days) auto-deletes `failed` entries on launch; `pending` entries exempt |

**Recommended next task: US-36 (3 SP)** — locale-aware date formatting.

### US-36 implementation notes
- Add `intl: ^0.20.x` to `pubspec.yaml` (check current Flutter-bundled version first)
- Search for all hardcoded date formatting in the codebase: `DateFormat`, `toString()`, ISO 8601 strings in UI widgets. Key locations to check:
  - Collection detail: added/updated date rows
  - Wishlist detail: added/updated date rows
  - Import/export history screen: job `startedAt`/`finishedAt`
  - Cached release detail banner: "last updated [date]" string in `ReleaseDetailScreen`
- Replace with `DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date)` or equivalent
- Tests: inject a fixed `DateTime` and assert the formatted string matches `intl`'s output for a known locale; do NOT assert a hardcoded "Jan 15, 2026" string since locale varies

---

## How to continue

1. Read `AGENTS.md` (security rules and coding conventions — required reading before any PR)
2. Read relevant docs in `docs/product`, `docs/architecture`, `docs/user-stories`
3. Pick up US-36 and implement
4. Run `flutter test --no-pub` after each change; run `dart format .` before reporting complete
5. Update `CHANGELOG.md` with a new `## [Unreleased — Phase 8I: ...]` entry
6. Update `memory/project_phase_progress.md` and `memory/MEMORY.md`
