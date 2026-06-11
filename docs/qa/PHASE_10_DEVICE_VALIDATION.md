# Phase 10: Device Validation Checklist

Status date: 2026-06-11

This is the manual QA checklist for Roadmap V2 Phase 10.
It must be executed on physical hardware:

- [ ] Android phone (model: ____________, OS version: ______)
- [ ] iPhone (model: ____________, iOS version: ______)
- [ ] iPad (model: ____________, iPadOS version: ______)

Tester: ____________
Date per device: ____________

## How to use this checklist

1. Build and install a debug or profile build on the device (`flutter run -d <device>`).
2. Work through every section below per device. Mark each item pass/fail.
3. Log every failure in the Findings log at the bottom.
4. After all devices are done, convert findings into user stories using the
   template at the bottom and add them to `docs/user-stories/`.

Phase 10 is done when all three devices have a completed checklist and no
open blocking issues remain.

## Prerequisites

- A valid Discogs personal access token (from discogs.com/settings/developers).
- A Discogs account with at least a few collection and wantlist items (for import tests).
- A few physical records with EAN-13, UPC-A (12), and EAN-8 barcodes.
- A prepared CSV file exported from a previous session (for import tests).
- Airplane mode available (for offline tests).

## Section A: First launch and setup (all devices)

Simulator pre-pass done 2026-06-11 on the iPhone 17 Pro simulator (iOS 26),
driven by `integration_test/qa_section_a_test.dart` plus `simctl`
(screenshots in `/tmp/qa_shots/`). Simulator results below as [S-…];
physical-device boxes stay open.

- [ ] App installs and launches without crash. [S-pass]
- [ ] App icon renders correctly (no alpha artefacts on iOS, adaptive icon on Android).
      [S-FAIL → finding #1: default Flutter icon; generator never run. Fixed
      2026-06-11 by running `dart run flutter_launcher_icons`; re-verify.]
- [ ] Light mode renders correctly; dark mode renders correctly (toggle device theme). [S-pass]
- [ ] All five tabs are reachable; navigation state survives tab switches.
      [S-pass — search query retained across tab switch]
- [ ] No content hidden behind notch, Dynamic Island, status bar, or home indicator
      (safe areas on every scrollable screen). [S-pass on screens seen]
- [ ] Settings: token field masks input by default; show/hide toggle works. [S-pass]
- [ ] Token help link opens discogs.com in the external browser.
      [S-partial: link present and styled; external open not driven]
- [ ] Pasting an invalid token shows a friendly error (no raw API error, no token echoed).
      [S-pass — real 401 from api.discogs.com → "Token not recognised. Check
      your token and try again."; token string appears in no Text widget]
- [ ] Pasting a valid token validates and shows the connected state with masked token.
      [S-blocked: needs a real token — manual]
- [ ] Removing the token works; app returns to disconnected state. [S-pass at UI level]
- [ ] Kill and relaunch the app: token connection state is remembered (secure storage).
      [S-partial: relaunch is crash-free, but see finding #2; token
      persistence needs a real token — manual]

## Section B: Search and release detail (all devices)

- [ ] Search returns results while typing (debounced, no request per keystroke).
- [ ] Rapidly changing the query never shows results for an old query (in-flight cancellation).
- [ ] Repeating a recent query shows results instantly (cache), then refreshes silently.
- [ ] In airplane mode, a recently searched query shows cached results with the
      "Showing saved results" banner.
- [ ] Result count ("1–N of total") and infinite scroll pagination work.
- [ ] Tapping a result opens release detail; artist/title visible immediately during load.
- [ ] App bar shows "Artist — Title" once loaded; long titles truncate with ellipsis.
- [ ] Tracklist, formats (multi-format releases show all entries), identifiers,
      and notes render correctly.
- [ ] "Add to Collection" works; condition prompt sheet appears; saving conditions works.
- [ ] "Add to Wishlist" works; both buttons show "In Collection"/"In Wishlist" when
      the release is already saved.
- [ ] Pull-to-refresh works on release detail.
- [ ] In airplane mode, a previously viewed release shows the full cached detail
      with the cached banner (stale styling after 30 days).
- [ ] Dates everywhere display in the device's locale format (check by switching
      device language/region).

## Section C: Collection and wishlist (all devices)

- [ ] Collection list loads from local storage; works in airplane mode.
- [ ] Search/filter field filters by artist and title; clear button resets.
- [ ] Adding a release from search appears in the collection list without manual
      refresh (live refresh on return).
- [ ] Collection detail: edit media/sleeve condition, notes, tags, and storage
      location via the edit sheets; changes persist after kill + relaunch.
- [ ] Removing an item asks for confirmation and states Discogs is unaffected.
- [ ] Wishlist: same checks — list, filter, detail, edit priority/target price/notes, remove.
- [ ] Pull-to-refresh works on all list and detail screens.
- [ ] Cached cover thumbnails appear in lists in airplane mode.

## Section D: Barcode scanning (all devices — core Phase 10 deliverable)

- [ ] Camera permission is requested on first scan; denying shows the
      permission-denied state, not a crash.
- [ ] Camera preview starts; viewfinder bracket overlay is visible.
- [ ] Flashlight toggle appears (when the device has a torch), switches torch
      on/off, and the icon reflects the state.
- [ ] Scanning an EAN-13 barcode fills the input and triggers the lookup.
- [ ] Scanning a UPC-A (12-digit) barcode works.
- [ ] Manual entry: non-numeric input shows "This doesn't look like a barcode";
      wrong length shows the 8/12/13 digits message; Search stays disabled.
- [ ] A barcode with no Discogs match shows the friendly no-results state.
- [ ] Scanning in low light with torch on works.
- [ ] Re-scanning a recent barcode shows cached results instantly.

## Section E: Import, export, and history (one device minimum, spot-check others)

- [ ] Discogs collection import: preview shows total/new/duplicate counts;
      confirm imports; summary shows added/skipped/failed.
- [ ] Discogs wishlist import: same flow works.
- [ ] Imported items show sync status "synced"; locally added duplicates get linked.
- [ ] Discogs collection/wishlist export: preview, per-item progress bar
      ("Exporting item N of M…"), and summary work.
- [ ] CSV export: share sheet opens; exported file opens in a spreadsheet app;
      "Share Again" works from the success screen.
- [ ] CSV import: file picker opens; preview shows valid/skipped/failed; confirm imports.
- [ ] History screen: entries listed with status chips; "Load more" pagination works;
      swipe-to-delete with undo works.
- [ ] Failed Actions screen (Settings): Retry, Retry All, and Clear All work.

## Section F: Deep linking

- [ ] Opening `cratewise://` from another app (notes app link) opens the app.
- [ ] Back from a deep-linked screen goes to the logical parent, not out of the app.

## Section G: iPad layout review (iPad only)

- [ ] Portrait and landscape both render correctly; rotation does not lose state.
- [ ] Wide layout (≥700dp): navigation rail is used instead of bottom bar.
- [ ] Search uses the split-pane layout: results left, detail right, rail stays visible.
- [ ] Selecting a result updates the right pane without pushing a route.
- [ ] Barcode scanner uses the wide two-panel layout (camera left ~40%, results
      right ~60%); camera stays live after a scan.
- [ ] Collection and wishlist use the 2-column grid in wide layout.
- [ ] Release/collection/wishlist detail use the 2-column wide layout.
- [ ] Split View / Slide Over: app remains usable at 1/2 and 1/3 width
      (narrow layout should kick in below 700dp).
- [ ] Centered error/empty states are width-constrained (no full-width stretching
      in landscape).
- [ ] Text scaling: increase system text size to maximum; no clipped or
      overlapping text on the main screens.
- [ ] Hardware keyboard: typing in search and token fields works; return key submits.

## Section H: Stability and resource checks (all devices)

- [ ] App survives backgrounding mid-search, mid-import, and mid-scan.
- [ ] No visible memory pressure or device heat during a 10-minute browse session.
- [ ] Thumbnail cache size in Settings shows a plausible value; Clear works.
- [ ] Rate limiting: perform ~10 quick searches in a row; app backs off gracefully
      with the friendly rate-limit message and retry countdown, never a raw error.

## Findings log

| # | Device | Section | Severity (blocker/major/minor) | Description | Screenshot |
|---|--------|---------|--------------------------------|-------------|------------|
| 1 | iPhone 17 Pro sim | A | major | App icon was the default Flutter logo — `flutter_launcher_icons` was never run after `assets/icon/app_icon.png` was added on 2026-06-04. Fixed same day (`dart run flutter_launcher_icons`); verify on all three physical devices. | /tmp/qa_a2_icon.png |
| 2 | iPhone 17 Pro sim | A | major | Cold launch does not consistently open the Search tab: consecutive relaunches landed on Wishlist, then Scan, then Settings (sticky), with the nav-bar indicator animating in from the adjacent tab. `router.dart` has `initialLocation: AppRoutes.search` and no restoration scope, so the cause is unknown. → **US-53** in `docs/user-stories/phase-10-device-validation-stories.md`. | /tmp/qa_a11_relaunch.png |
| 3 | iPhone 17 Pro sim | A | minor | Token helper text truncates with an ellipsis on a 402dp-wide phone: "Discogs personal access tokens are 40 char…". → **US-54** in `docs/user-stories/phase-10-device-validation-stories.md`. | /tmp/qa_shots/a6_token_masked.png |
| 4 | iPhone 17 Pro sim | A | minor | In the dark-mode screenshot an unidentified glyph appeared at the right end of the search bar that is absent in light mode (no query entered, so it is not the clear button). Recheck. | /tmp/qa_a3_dark.png |

## Converting findings to user stories

Use the existing format from `docs/user-stories/beta-user-stories-s.md`.
Number new stories starting at US-53.

```markdown
### US-NN: <short title>

**Beta: <M or S> · <SP> SP**

> As a <user>,
> I want <behaviour>,
> so that <value>.

**Acceptance criteria:**
- <criterion>
- <criterion>

**Found during:** Phase 10 device validation, <device>, finding #<n>.
```

Severity mapping: blocker → fix before Phase 11; major → Beta M priority;
minor → Beta S priority (defer to post-beta).
