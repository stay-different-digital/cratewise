# Changelog

All notable changes to Cratewise are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The detailed pre-1.0 development history (134 incremental entries) lives in
[docs/archive/CHANGELOG_DEV_HISTORY.md](docs/archive/CHANGELOG_DEV_HISTORY.md).

---

## [1.1.0] — 2026-11-16

Search and navigation release (phase 17, sprint 1). The barcode scanner is
gone; its place in the main menu goes to collection statistics.

### Added

- **Sort search results by year (US-133)** — Relevance, Newest first or
  Oldest first, next to the filter chips. Sorting happens at Discogs, so
  scrolling to later pages keeps the order.
- **Vinyl only (US-142)** — a chip in Search that hides CD, cassette and
  digital ("File") releases. Releases that combine vinyl with another format
  stay. The choice is remembered on the device.
- **From a release to its label (US-134)** — the label name in the release
  info is a link to all the label's releases, newest first, with the usual
  in-collection and wishlist icons.
- **Statistics tab (US-140)** — collection statistics are a main-menu tab and
  refresh every time you open it.
- **Fresh search with one tap (US-139)** — tapping Search again while on the
  results clears the search box; filter and sort stay.
- **Filter by format type (US-143, US-147)** — the collection and wishlist
  filters show one chip per format type (Vinyl, CD, File…) instead of one per
  format variant. Saved filters keep working.

### Changed

- **Minimum iOS version is now 15.0 (US-138)** — current Xcode no longer
  builds for iOS 13/14. iPhones and iPads on iOS 13 or 14 keep version 1.0.4.
- **No "Set condition" sheet when adding to the collection (US-141)** — the
  record is added straight away with condition Very Good; change it later
  from the collection item.

### Removed

- **Barcode scanner (US-135 – US-138)** — the Scan tab, the scanner screen,
  manual barcode lookup, the `mobile_scanner` dependency and the camera
  permission on Android and iOS. The feature was rarely used.

### Fixed

- **Android network permission (US-137)** — the app now declares `INTERNET`
  itself. It previously came only through the scanner's ML Kit dependency.
- **Search filter chip lost on focus** — picking Label (or Artist / Release)
  and then tapping into the empty search box reset the chip to All.
- **Search messages on short screens** — the empty and error messages scroll
  instead of overflowing in the iPad search pane.
- **Statistics "By format"** — a record whose first format has no
  description no longer shows its full format text as a category.

## [1.0.4] — 2026-10-23

Robustness release from the phase 16 code review (US-124 – US-132).

### Fixed

- **App upgrade from very old installs (US-125)** — upgrading a database from
  schema v1–v4 crashed with "duplicate column"; all upgrade paths v1 → v12 are
  now covered by migration tests.
- **Pending Discogs deletions (US-124)** — a record already removed on Discogs
  (404) no longer stays in the list forever; deletions recorded without an
  instance id now look it up instead of failing on every sync.
- **Importing several copies of one release (US-129)** — a Discogs import now
  links or imports each copy separately instead of collapsing them into one.
- **Discogs rate limits (US-126)** — one shared API client, so the back-off
  after a 429 (honouring `Retry-After`) applies across the whole app.
- **Cover downloads (US-128)** — time out after 15 s and ignore non-image
  responses (e.g. captive portals).

### Security

- **CSV export (US-127)** — cells that a spreadsheet would run as a formula
  (`=`, `+`, `-`, `@`) are prefixed with `'`; Cratewise strips the prefix
  again on import.

### Changed

- Collection and wishlist import/export preview screens share one
  implementation each (US-130, −40 % code).
- Unexpected errors in use cases are logged instead of silently reported as
  network or save errors (US-132); unused scaffolding folders removed and a
  second database connection at startup dropped (US-131).

## [1.0.3] — 2026-07-07

### Added

- **DJ fields (US-121)** — collection items now carry optional DJ metadata:
  BPM, musical key, energy level (1–5), and gig crates. Edit them from the
  collection detail screen, filter on them in the filter sheet (BPM range,
  key, energy, gig crate), and sort the collection list by BPM, key, or
  energy with a new sort menu; items without a value sort last. CSV
  export/import carries the four new columns; older CSV files and saved
  filters keep working. DJ fields are local-only and are never written to
  Discogs.

### Fixed

- Version display format unified as `version.buildNumber` via one shared
  helper, shown in the onboarding footer and the About tile.
- iOS Release build configuration pointed at the wrong bundle identifier;
  restored to `app.cratewise`.

---

## [1.0.2] — 2026-06-19

### Added

- **Advanced collection filters** — tap the filter icon in the Collection tab
  to open a facet-based filter sheet. Filter by decade, format, label, genre,
  style, media condition, sleeve condition, tag, storage location, sync status,
  and cover presence. Active filters are shown in a bar below the toolbar with
  a one-tap clear option. A badge on the filter button shows the active filter
  count.
- **Advanced wishlist filters** — same filter sheet experience in the Wishlist
  tab: decade, format, label, genre, style, priority, sync status, target price,
  and cover presence.
- **Saved searches & filter sets** — save any Discogs search query, collection
  filter set, or wishlist filter set with a custom name. Load, rename, or delete
  saved items from the new Saved Searches screen (accessible from Settings or
  from the bookmark icon in each surface's toolbar). Last-used timestamp is
  tracked automatically.

---

## [1.0.1] — 2026-06-19

### Added

- **Collection statistics screen** — tap the chart icon next to the search
  bar in the Collection tab to see a full breakdown of your collection:
  total records, unique artists and labels, decade distribution, format
  distribution, and counts of items missing a cover or year. Responsive
  layout: phone shows a single column, iPad (≥700 dp) shows sections
  side-by-side.
- **Genre and style distributions** — when Discogs metadata is cached
  locally for a release, its genres and styles are counted and shown as
  ranked bar charts in the statistics screen. No extra API calls; purely
  from the on-device cache.

---

## [1.0.0] — 2026-06-19

First public release of Cratewise — a local-first vinyl collection app for
collectors and DJs, for Android, iPhone, and iPad.

### Added

**Search & discover**
- Search the Discogs database with live results, infinite-scroll pagination,
  debounced input, and cached recent searches that show instantly and refresh
  in the background.
- Release detail pages with tracklist, identifiers, credited artist names,
  all format entries, and cover art; split-pane layout on wide screens.

**Barcode scanning**
- Camera barcode scanning (Android and iOS) with viewfinder overlay and
  flashlight toggle; scanned codes resolve against Discogs.
- Manual barcode entry with format validation (8/12/13-digit).

**Collection & wantlist**
- Local collection: add from search or scan, grade media/sleeve condition
  (with a prompt right after adding), notes, tags, storage location, and
  removal with confirmation. Search and filter within the collection.
- Local wantlist: priorities, target prices, notes; same search and filter.
- "Already in collection/wantlist" indicators on release pages.
- All data stored on-device (SQLite); works fully offline, no account needed.

**Discogs sync (optional)**
- Connect with a personal access token, stored only in the platform's secure
  storage (Keychain / Android Keystore), removable at any time. Revoked
  tokens are detected and cleared automatically.
- Import your Discogs collection and wantlist with a preview (new /
  duplicate / invalid) before anything is saved; existing local items are
  linked instead of duplicated.
- Export local items to your Discogs collection and wantlist with per-item
  progress; rate limits are respected with automatic back-off and retries.

**CSV import & export**
- Export collection and wantlist to CSV (Excel-compatible, UTF-8 BOM) via
  the system share sheet.
- Import from CSV with validation and a preview of what will be added,
  skipped, or rejected.
- Import/export history with status, counts, pagination, and swipe-to-delete
  with undo.

**Offline resilience**
- Viewed releases are cached (metadata + thumbnails) and shown with a
  data-age banner when offline; thumbnail cache is size-capped (LRU,
  clearable from Settings).
- Failed writes and cache refreshes queue for retry — individually, in bulk,
  or cleared entirely; stale entries are purged automatically.

**Platform integration**
- Deep linking via `cratewise://` with named routes for every screen.
- iPad-aware layouts throughout: navigation rail, two-pane and grid layouts,
  landscape and Split View support.
- Branded app icon and splash screen; dates in the device's locale format;
  safe-area handling for notches and home indicators.

**Settings**
- Discogs connection management, import/export hub, failed-actions queue,
  thumbnail cache control, send-feedback email with version prefilled, and
  an About section with version and open-source licences.

### Security

- Discogs tokens are never logged, never shown in error messages, and never
  leave the device except to authenticate requests to api.discogs.com.
- All network traffic is HTTPS to the Discogs API only; no analytics, no
  ads, no crash reporting, no third-party data sharing.

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
