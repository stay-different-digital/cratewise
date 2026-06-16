# Phase 14 Growth — User Stories

Post-1.0 stories from the Phase 14 candidate list in
`docs/product/ROADMAP_V2.md` and from beta feedback.
Numbering continues from the Phase 13 stories (US-68 … US-71).

---

### US-72: Local deletions can be propagated to Discogs

**5 SP · S4 (feature request, post-1.0)**

**Status (2026-06-13): implemented in 6 slices** (commits `US-72 slice 1…5`).
Collection instance_id capture; PendingDiscogsDeletion tombstone model +
Drift storage (schema v10); opt-in "also remove from Discogs" checkbox in
the collection/wishlist delete dialogs; Discogs DELETE endpoints;
ExecutePendingDeletionsUseCase (back-off, tombstone cleanup); a
PendingDeletionsScreen with preview-and-confirm + per-item progress, reached
from the Import & Export hub; and collection re-import classifies a
tombstoned release as a conflict (kept off Discogs) instead of re-importing.
**Remaining (symmetry follow-up):** the wishlist *import* preview did not yet
surface re-import conflicts (only the collection import did). Tracked and
resolved as **US-79** below — a `ConflictWishlistRow` mirroring the collection
path.

> As a user who curates my collection in Cratewise,
> I want the option to remove a record from my Discogs collection when I delete it locally,
> so that exporting keeps Discogs in step with my real collection instead of only ever growing it.

**Acceptance criteria:**
- The Discogs `instance_id` returned when adding a release to a collection (and captured during import) is stored on the local item, so the specific collection entry can be addressed later.
- Deleting a local item that is linked to Discogs (`syncStatus == synced`) records a tombstone instead of vanishing without trace.
- The export preview gains a "to remove from Discogs" category listing tombstoned items, alongside the existing ready/linked/invalid categories — nothing is deleted remotely without the same preview-and-confirm flow as additions.
- Executing the export calls `DELETE /users/{username}/collection/folders/{folder_id}/releases/{release_id}/instances/{instance_id}` per tombstoned item, with the same rate-limit back-off and per-item progress as additions, and clears the tombstone on success.
- Remote deletion is opt-in: the local delete dialog keeps its current default ("Your Discogs collection is not affected") and offers the propagation as a choice, or the preview lets the user exclude deletions — deleting on Discogs must never be a surprise.
- The wantlist gets the same treatment (`DELETE /users/{username}/wants/{release_id}` — no instance id needed there).
- Tombstones survive app restarts and appear sensibly in import previews (an item deleted locally but still on Discogs must not silently re-import as "new" — it should surface as a conflict the user resolves).
- Unit and widget tests cover: tombstone creation, preview category, per-item deletion with back-off, opt-out, and the re-import conflict case.

**Found during:** Beta QA (2026-06-12, pre-beta tester finding): deleting
release #193467 locally and re-exporting did not remove it from Discogs and
showed nothing in "ready to export". Triaged per
`docs/beta/FEEDBACK_TRIAGE.md` as working-as-designed (export is add-only;
the delete dialog says Discogs is unaffected), reclassified as this S4
feature request.

**Investigation notes:**
- The API client (`lib/infrastructure/discogs/discogs_api_client.dart`) has
  only `addToCollection` and `addToWantlist` write methods today.
- `instance_id` is currently discarded: the add response body is ignored,
  and the import DTO does not map it. Both paths need to capture it, plus a
  schema migration to store it (and the tombstone table).
- Roadmap fit: Phase 14 "Two-way sync improvements between local data and
  Discogs" — this story is the deletion half of that.

---

### US-79: Wishlist re-import surfaces pending-removal conflicts

**1 SP · S4 (US-72 symmetry follow-up, post-1.0)**

> As a user who deleted a wantlist record locally and chose to remove it from
> Discogs too,
> I want re-importing my Discogs wantlist to flag that record as pending removal
> instead of silently adding it back,
> so that the import never undoes a deletion I asked for — exactly as the
> collection import already does.

**Background:** US-72 shipped the full deletion-sync flow, but only the
*collection* import classifies a tombstoned release as a conflict. The wishlist
import still ran the old new/duplicate/invalid classification, so a wantlist
item that was deleted locally and is awaiting removal from Discogs would
re-import as "new" on the next wantlist import — silently undoing the pending
deletion. The deletion itself is recorded and executed correctly
(`DeletionEntityType.wishlist` tombstones, `ExecutePendingDeletionsUseCase`);
only the re-import preview lacked the conflict category.

**Acceptance criteria:**
- A new `ConflictWishlistRow` mirrors `ConflictCollectionRow`: a wantlist item
  that is still on Discogs but has a pending-deletion tombstone
  (`DeletionEntityType.wishlist`) is classified as a conflict, ahead of the
  duplicate/new checks, and is never imported automatically.
- `BuildWishlistImportPreviewUseCase` accepts an optional
  `PendingDiscogsDeletionRepository` and uses it for the tombstone check; when
  none is supplied (tests, or no deletions feature), classification is
  unchanged.
- `WishlistImportPreview` exposes a `conflictCount` getter.
- Executing the import skips conflict rows with a clear, token-free reason
  ("Deleted locally — kept off Discogs") and counts them as skipped, matching
  the collection behaviour.
- The wishlist import preview screen shows a "Pending removal" count and a
  note explaining the items will not be re-imported, consistent with the
  collection preview's wording and styling.
- Production wiring passes a `LocalPendingDiscogsDeletionRepository` to the
  builder; the collection path already does this.
- Unit and widget tests cover: conflict classification (with and without a
  deletion repository), `conflictCount`, the execute skip case, and the
  preview screen surfacing the conflict count.

**Found during:** Documented follow-up from US-72 (the collection/wishlist
symmetry gap recorded in this file). No new QA report — closing the known gap
so deletion-sync is symmetric across collection and wantlist.

---

### US-80: Search results show collection / wishlist membership at a glance

**3 SP · S4 (feature request, post-1.0)**

**Status (2026-06-14): implemented.** `ReleaseSearchResultCard` gained
`inCollection`/`onWishlist` flags rendering trailing `library_music` (primary)
and `favorite` (tertiary/accent) icons, each with a `Semantics` label and
tooltip; neither flag renders nothing (no layout shift). `SearchScreen` and
`BarcodeScanScreen` resolve membership once per refresh from local storage
(`getAll()` → `Set<int>` of release ids, synchronous `.contains` per card —
never a per-card async lookup) and degrade to "no icons" on a storage error.
The Search branch gained a `searchRouteObserver`; `SearchScreen` re-resolves
membership via `RouteAware.didPopNext` when returning from a release detail
screen. Covered by widget tests for the card (all four icon combinations,
semantics, tooltips) and both screens (membership, per-result-set lookup,
refresh on return, storage-error degradation).

> As a user browsing Discogs search results,
> I want each result to show — with an icon on the right — whether that release
> is already in my collection or on my wishlist,
> so that I can tell at a glance what I already have or want without opening
> each release.

**Acceptance criteria:**
- Each `ReleaseSearchResultCard` shows a trailing status area, beside the
  existing `#id`, with:
  - a "in collection" icon (`Icons.library_music`, primary colour) when the
    release's Discogs id is in the local collection, and
  - a "on wishlist" icon (`Icons.favorite`, accent colour) when it is on the
    local wishlist.
- A release that is in **both** shows **both** icons side by side; a release in
  neither shows **no** icon (no empty placeholder, no layout shift).
- Each icon carries a `Semantics` label and tooltip ("In your collection" /
  "On your wishlist") so the state is available to screen readers, not colour
  alone.
- Membership is resolved from local storage only — no extra Discogs calls — and
  is loaded **once per result set**, not per card: the screen fetches the set of
  collection release ids and the set of wishlist release ids and the card
  receives two booleans. A 50-result page must not fire 100 async lookups.
- The indicators update when the user returns to search after adding the
  release elsewhere (e.g. from the release detail screen): membership is
  re-resolved on the search route regaining focus (`RouteAware.didPopNext`,
  the same mechanism as the collection list live-refresh, US-10), with no
  full-screen spinner.
- The same treatment applies to the barcode-scan results list, which reuses
  `ReleaseSearchResultCard`.
- Works in both the phone list layout and the iPad split-pane search layout.
- Membership lookup is robust: a storage error while loading the sets degrades
  gracefully to "no icons" rather than failing the search results.
- Unit and widget tests cover: in-collection only, on-wishlist only, in both,
  in neither, the per-result-set (not per-card) lookup, the refresh on return,
  the barcode results variant, and the storage-error degradation.

**Investigation notes:**
- `ReleaseSearchResultCard`
  (`lib/presentation/widgets/release_search_result_card.dart`) currently has no
  trailing status zone; the right column ends at the `#id` row.
- `SearchScreen` (`lib/presentation/screens/search_screen.dart`) does not yet
  receive `CollectionRepository`/`WishlistRepository` directly (it has the add
  use cases and the cache repository). They are available in `HomeShellScreen`,
  which already constructs the Local repositories, so wiring them down matches
  the existing pattern.
- The membership check should reuse the established efficient pattern (one set
  load, synchronous lookup) rather than per-item `containsRelease`, mirroring
  the import-linking work in US-21. A lightweight `Set<int> releaseIds()` on
  each repository (Drift `SELECT discogs_release_id`) is the cleanest source.
- The "already in collection / wishlist" detail-screen indicators (US-08 /
  US-12) establish the precedent and icon language to stay consistent with.
- Roadmap fit: Phase 14 UX polish — surfacing local state in the discovery
  flow.

---

### US-81: Remove a release from collection / wishlist on the release detail screen

**3 SP · S4 (feature request, post-1.0)**

> As a user viewing a release I reached from search (or barcode),
> I want to remove that release from my collection or wishlist right there on the
> detail screen,
> so that I can undo an add without hunting for the item in the Collection or
> Wishlist tab.

**Background:** The release detail screen already tells me when a release is
already saved — the Add buttons flip to a disabled "In Collection" / "In
Wishlist" state (US-08 / US-12). But that state is a dead end: the only way to
remove the release is to leave the search flow, open the Collection or Wishlist
tab, find the item, and delete it there. This story makes the detail screen's
saved-state actionable so add and remove are symmetric in one place. The actual
deletion (local, plus the optional propagate-to-Discogs path) is already solved
by US-72 — this story reuses it from a new entry point.

**Acceptance criteria:**
- When a release is already in the collection, the detail screen offers a clear
  "Remove from Collection" action; likewise "Remove from Wishlist" when it is on
  the wishlist. The existing disabled "In Collection" / "In Wishlist" indicator
  is no longer a dead end.
- Removing asks for confirmation and reuses the **same delete dialog as the
  Collection / Wishlist detail screens (US-72)**: the default keeps Discogs
  untouched ("Your Discogs collection is not affected"), with the opt-in "also
  remove from Discogs" choice that records a pending-deletion tombstone. Wording,
  styling, and the collection-needs-`instance_id` / wishlist-needs-only-release-id
  distinction stay consistent with US-72.
- On success the detail screen returns the relevant button to its "Add" state
  (idle) and shows a confirmation snackbar, so the user can immediately re-add if
  they removed by mistake. The other button (collection vs wishlist) is
  unaffected.
- A storage failure during removal shows a non-destructive error (snackbar) and
  leaves the saved state unchanged — nothing is silently lost.
- Removal works from the live `_Loaded` state and the offline `_CachedLoaded`
  state, matching how the Add buttons already behave in both.
- Returning to the search results after removing re-resolves the membership
  icons (US-80) so the collection/wishlist icon disappears — the existing
  `RouteAware.didPopNext` refresh already covers this once removal is wired up.
- Unit and widget tests cover: the remove action appearing only when saved, the
  confirm dialog, successful removal resetting the button to "Add", the
  opt-in-Discogs tombstone path, the storage-error case, and both the live and
  cached states.

**Investigation notes:**
- `ReleaseDetailScreen`
  (`lib/presentation/screens/release_detail_screen.dart`) already receives
  `CollectionRepository` / `WishlistRepository` and tracks the saved state via
  `_AddState.duplicate` (`_checkInitialCollectionStatus` /
  `_checkInitialWishlistStatus`). The add handlers are `_handleAdd` /
  `_handleAddToWishlist`; a remove path would sit alongside them.
- Removal needs the **local item id**, not the Discogs release id:
  `CollectionRepository.remove` / `WishlistRepository.remove` take the
  `CollectionItem.id` / `WishlistItem.id` string, but the detail screen only has
  `releaseId`. The interfaces expose `containsRelease(int)` and `getAll()` but no
  lookup-by-release-id. Resolve the item via `getAll()` + firstWhere (mirroring
  US-80's getAll-derived approach) or add a small `getByReleaseId(int)` —
  prefer the former to avoid touching the ~44 repository test fakes.
- The delete-with-optional-Discogs-propagation flow already exists on
  `CollectionDetailScreen` / `WishlistDetailScreen` (US-72): the confirmation
  dialog, the opt-in checkbox, the `PendingDiscogsDeletion` tombstone
  (`DeletionEntityType.collection` needs the captured `instance_id`,
  `wishlist` needs only the release id). Reuse that logic rather than
  re-implementing it; consider extracting the shared dialog so the three entry
  points stay in sync.
- US-08 / US-12 (in-collection / in-wishlist indicator) and US-72
  (deletion-sync) are the direct precedents; US-80 established the membership
  refresh-on-return that makes the search list reflect the removal.
- Roadmap fit: Phase 14 UX polish — symmetric add/remove in the discovery flow.

**Status (2026-06-14): implemented.**

- `ReleaseDetailScreen` now takes an optional `PendingDiscogsDeletionRepository`
  (owned-db branch falls back to `LocalPendingDiscogsDeletionRepository`) and
  exposes a `Remove from Collection` / `Remove from Wishlist` overflow menu
  (`Key('detail-remove-menu')`) in the app bar whenever the release is saved
  (`_inCollection` / `_onWishlist`, derived from `_AddState.added`/`duplicate`).
  This reuses the app's established US-72 remove pattern (the Collection /
  Wishlist detail screens put removal in an app-bar overflow menu) rather than
  re-purposing the disabled "In Collection" / "In Wishlist" bottom-bar
  indicator — keeping that indicator's behaviour (and its tests) unchanged while
  making removal reachable from the same screen.
- The local item id is resolved on demand via `getAll()` + a linear scan on
  `discogsReleaseId` (the getAll-derived approach from US-80), avoiding a new
  `getByReleaseId` method across the ~44 repository fakes. If the item is already
  gone, the button silently resets to "Add"; if `getAll()` throws, a
  non-destructive snackbar is shown and the saved state is preserved.
- The confirm dialog is inlined per the existing precedent (each detail screen
  inlines its own): collection uses the `instance_id` opt-in
  (`DeletionEntityType.collection`, "Also remove from my Discogs collection",
  else "Your Discogs collection is not affected."); wishlist uses the
  synced-by-release-id opt-in (`DeletionEntityType.wishlist`, "Also remove from
  my Discogs wantlist", else "Your Discogs account is not affected."). On success
  the relevant `_AddState` resets to `idle` and a "Removed from your collection /
  wishlist" snackbar appears; the other button is untouched.
- Works in both the live `_Loaded` and offline `_CachedLoaded` states. Returning
  to search re-resolves the US-80 membership icons via the existing
  `RouteAware.didPopNext`.
- Tests: 13 new widget tests in `release_detail_screen_test.dart` cover the menu
  appearing only when saved (collection-only / both), reset-to-Add + snackbar on
  removal, cancel preserving state, the opt-in collection (instance id) and
  wishlist (release-id, no instance) tombstones, default removal recording no
  tombstone, the unsynced-wishlist no-propagate case, the remove-failure and
  resolve-failure non-destructive paths, and removal from the cached state.
  Suite 2370 → 2383, all green; analyze introduces no new issues.

---

### US-82: Clear local collection and wishlist from Settings

**3 SP · S3 (feature request, post-1.0)**

> As a user who has switched to a different Discogs account (or just wants a
> clean slate),
> I want a "Clear collection" and "Clear wishlist" option in Settings,
> so that the records tied to my old token don't linger after I connect a
> different account.

**Background:** Cratewise stores the collection and wishlist locally and keeps
them even when the Discogs token changes — connecting a new token only swaps the
stored credentials (`DiscogsTokenStorage.saveCredentials` / `deleteCredentials`,
US-15), it does not touch the local item tables. So after switching accounts the
app still shows the previous account's records, which is confusing and arguably
wrong: those items belong to a collection the user is no longer connected to.
Today the only way to clear them is to remove items one at a time (US-72 /
US-81). There is no bulk "start over" affordance. Settings already has a
destructive-action precedent — the thumbnail-cache "Clear" tile
(`_ThumbnailCacheSection`) — so a "Local data" section is a natural home for
this.

**Acceptance criteria:**
- Settings has a clearly labelled section (e.g. "Local data") with separate
  **"Clear collection"** and **"Clear wishlist"** actions, each showing how many
  items will be removed (e.g. "Clear collection (42 items)") and disabled/hidden
  when that list is already empty.
- Each action requires an explicit confirmation dialog that states the count and
  is unambiguous that it is **local-only and irreversible** ("This permanently
  removes all N items from this device. Your Discogs account is not affected.").
  Reuse the US-72 dialog wording/tone.
- Clearing is **local-only by default and does NOT propagate to Discogs.** This
  is deliberate and the key distinction from US-72/US-81: when a user is
  switching accounts, the token may already point at a different account, so
  recording `PendingDiscogsDeletion` tombstones could delete records from the
  *wrong* account. Clearing must not create tombstones. (If we later want an
  opt-in "also remove from Discogs" path it would be a separate story and only
  while the original token is still connected.)
- Any pending Discogs-deletion tombstones for the cleared entity are also
  discarded as part of the clear (there is nothing left to propagate), so the
  Pending Deletions screen (US-72) does not show orphaned entries.
- On success the relevant list is empty everywhere it is shown (Collection /
  Wishlist tabs live-refresh on return via the existing `RouteAware.didPopNext`,
  US-10/US-35), and a confirmation snackbar reports how many items were removed.
- A storage failure during the clear shows a non-destructive error and leaves the
  data intact — partial/ambiguous state is avoided (prefer a single transactional
  delete over a per-item loop).
- The two actions are independent: clearing the collection leaves the wishlist
  untouched and vice versa. Neither touches the stored Discogs token, cached
  release metadata, thumbnails, or the import/export history.
- Unit and widget tests cover: the count label, the confirm dialog, successful
  clear emptying the list, the no-tombstone guarantee, tombstone cleanup, the
  empty-list disabled state, the storage-error non-destructive case, and
  collection/wishlist independence.

**Investigation notes:**
- `CollectionRepository` / `WishlistRepository`
  (`lib/domain/repositories/`) expose only `remove(String id)` — there is **no
  bulk `deleteAll()`**. Add one to each interface and its Drift implementation
  (`delete(collectionItems).go()` in a transaction) rather than looping
  `getAll()` + `remove`, so the clear is atomic and fast. `RetryActionRepository`
  /`LocalRetryActionRepository.deleteAll()` (US-44) is the existing precedent for
  a bulk-delete interface method — follow its shape, including adding the
  `deleteAll()` stub to the repository test fakes (this is the main test-surface
  cost; ~the same fakes touched by US-44/US-80).
- For the tombstone cleanup, `PendingDiscogsDeletionRepository`
  (US-72) needs a way to drop all tombstones for an entity type — check whether a
  bulk delete already exists there or add one alongside `deleteAll()`.
- Settings UI: mirror `_ThumbnailCacheSection` in
  `lib/presentation/screens/settings_screen.dart` — a section that loads the
  counts in `initState` (`getAll().length`, or a cheaper `count()` if added),
  shows two `ListTile`s with a destructive-styled action, an `AlertDialog`
  confirmation, a `_clearing` busy flag, and a snackbar. `HomeShellScreen` wires
  the repositories down (it already constructs the shared `AppDatabase` and
  passes repos to the tabs).
- **Consider the account-switch trigger directly:** the originating pain is
  switching tokens. A nice follow-up (separate story, note it) is to detect a
  token change in `DiscogsConnectionService` / the token section and *offer*
  "You've connected a different account — clear the previous collection and
  wishlist?" rather than relying on the user to find the Settings action. Keep
  US-82 scoped to the manual Settings action; the prompt-on-switch is US-83+.
- Precedents: US-72 (deletion dialog + tombstones — and why we must NOT create
  them here), US-44 (`deleteAll()` bulk-delete interface pattern), US-15 (token
  swap leaves local data untouched — the root cause), US-19 (thumbnail-cache
  "Clear" tile in Settings — the UI precedent).
- Roadmap fit: Phase 14 UX polish / account hygiene — making account switching
  leave a clean, correct local state.

**Status (2026-06-16): implemented.** Added a "Local data" section to
`SettingsScreen` with "Clear collection" / "Clear wishlist" tiles that show the
item count and disable when empty. Each clear asks for confirmation (reusing the
US-72 "Discogs account is not affected" wording) and is **local-only** — it
discards any pending tombstones for that entity (`deleteAllByType`) and never
creates new ones, so switching accounts can't delete from the wrong Discogs
account. Bulk `deleteAll()` was added to `CollectionRepository` /
`WishlistRepository` (single transactional delete, following the US-44
`RetryActionRepository.deleteAll()` precedent) and `deleteAllByType()` to
`PendingDiscogsDeletionRepository`; the `deleteAll()` stub was added to all
repository test fakes. Storage failures are non-destructive (count unchanged,
error snackbar). 12 new tests (suite 2383 → 2395, all green). Follow-up noted in
the investigation notes — prompt-on-account-switch — remains unscoped.

---

### US-83: Remove the static "Cratewise" header to reclaim screen space

**2 SP · S4 (feature request, post-1.0)**

> As a user on the main tabs (Search, Collection, Wishlist, Settings),
> I want the app to stop showing a fixed "Cratewise" title bar at the top of
> every screen,
> so that the wasted band of chrome is given back to content — especially on
> small phones where vertical space is scarce.

**Background:** The four main tabs are rendered inside `HomeShellScreen`, whose
`Scaffold` has a static `AppBar(title: const Text('Cratewise'))` (both the
narrow and wide layouts). The title never changes and earns nothing — I already
know which app I'm in — but it costs a full `kToolbarHeight` (~56dp) band on
every tab. On a phone in the record shop that's a chunk of list or search
results I can't see. This is purely a layout/real-estate fix: drop the header
and reclaim the space.

**Acceptance criteria:**
- The persistent "Cratewise" title bar no longer appears on any of the main
  tabs; the freed ~56dp goes to tab content.
- Content that was below the app bar now respects the **status bar / notch** —
  it must not render underneath it. Wrap the body in `SafeArea` (top: true) on
  both the narrow and wide layouts so the first item isn't clipped by the system
  status bar.
- The wide (≥700dp) layout still works: removing the shell app bar must not break
  the nav rail / divider / content `Row`, and the rail's own top alignment stays
  correct under the status bar.
- Per-screen contextual app bars are **unaffected**: the detail screens
  (release / collection / wishlist detail), import/export, and CSV preview
  screens keep their own app bars (they show context like "Artist — Title" and,
  crucially, the back button). This story only removes the *shell's* static
  header on the top-level tabs, not navigation chrome on pushed routes.
- Non-visible "Cratewise" strings stay untouched: the `MaterialApp.title` in
  `app.dart` (the OS task-switcher / accessibility app label) and the About
  dialog's `applicationName` are not headers and must remain.
- Each tab still reads correctly without the bar: Search has its own pill search
  field, Collection and Wishlist have their search fields and content, Settings
  is a titled list — confirm none of them depended on the shell title for
  orientation. If a tab looks adrift without any heading, prefer a lightweight
  in-body heading over re-introducing a full app bar (decide per tab; default is
  no heading).
- Widget tests: assert the "Cratewise" `AppBar` title is gone from
  `HomeShellScreen` in both layouts, that tab content is wrapped in a `SafeArea`,
  and that the existing nav rail / bottom nav behaviour is unchanged. Detail-screen
  app-bar tests must stay green (they assert their own titles).

**Investigation notes:**
- The header lives only in `HomeShellScreen.build`
  (`lib/presentation/screens/home_shell_screen.dart`): `AppBar(title: const
  Text('Cratewise'))` at the wide-layout `Scaffold` (~line 27) and again at the
  narrow-layout `Scaffold` (~line 42). Removing both `appBar:` arguments is the
  core change.
- The narrow layout's body is `navigationShell` directly and the wide layout
  already wraps content in `SafeArea(top: false, child: navigationShell)` —
  because the app bar previously handled the top inset. With the app bar gone,
  the top inset is no longer handled, so the narrow body needs
  `SafeArea(child: navigationShell)` and the wide layout's `SafeArea(top: false…)`
  must become `SafeArea(…)` (top: true) so the status bar no longer overlaps
  content.
- Check each branch screen for an assumption that a parent `Scaffold`/`AppBar`
  exists. The tab screens are branches of the `StatefulShellRoute.indexedStack`
  (US-28); if any tab renders its own `Scaffold` without an app bar it already
  handles its own insets and may need no change — verify Search / Collection /
  Wishlist / Settings individually.
- Confirm the only *visible* "Cratewise" header is the shell's: `grep` shows
  `app.dart` (`MaterialApp.title`) and `about_section_tile.dart`
  (`applicationName`) as the other occurrences — both intentionally kept.
- Precedent: US-13 (wide-screen nav rail) and US-27 (safe-area correctness for
  scrollable content) are the layout stories this touches; keep their behaviour
  intact.
- Roadmap fit: Phase 14 UX polish — reclaiming vertical space on the primary
  screens.

**Status: done.** Removed both `appBar:` arguments from `HomeShellScreen`
(narrow and wide `Scaffold`s); the narrow body is now `SafeArea(child:
navigationShell)` and the wide layout's `SafeArea(top: false, …)` became
`SafeArea(child: navigationShell)` (top: true) so tab content claims the freed
status-bar inset. The four tabs build no `Scaffold`/`AppBar` of their own, so
nothing else needed changing; per-screen contextual app bars and the non-visible
`MaterialApp.title` / About-dialog `applicationName` strings are untouched.
Updated `widget_test.dart` to assert the "Cratewise" header is gone and the body
is wrapped in a `SafeArea`. Full suite green (2383 tests).

---

### US-84: Search filter chips (Release / Artist / Label) below the search box

**2 SP · S5 (feature request, post-1.0)**

> As a user on the Search tab,
> I want a row of filter buttons — Release, Artist, Label — under the search
> box,
> so that I can narrow what I'm searching for instead of always matching every
> field at once.

**Background:** The Search tab currently has a single pill text field that
searches everything (the API call is hardwired to a general `q` query — see the
follow-up US-85 for the behaviour). This story adds the **filter affordance**:
a row of selectable chips directly under the search field offering **Release**,
**Artist**, and **Label**. With nothing selected the app searches **"All"**,
which is the **default** — so the feature is purely additive and the current
behaviour is preserved until a chip is chosen. This story is scoped to the
**UI + selected-filter state**; making the selection actually change the Discogs
query is the explicit follow-up (US-85), so US-84 can ship and be reviewed on
its own.

**Acceptance criteria:**
- A horizontal row of filter controls appears **between the search field and the
  results body** in `SearchScreen` (the `Column` whose first child is the
  `TextField` `Padding` and second is `Expanded(child: _buildBody(...))`). Use
  Material `FilterChip`/`ChoiceChip` styling consistent with the app theme.
- The choices are **Release**, **Artist**, **Label**, plus the implicit **All**
  (no chip selected). All is the **default** on first open and after the field
  is cleared. Selecting is single-choice (mutually exclusive); tapping the
  active chip again deselects back to All.
- The selected filter is held in screen state (e.g. an `enum SearchFilter { all,
  release, artist, label }` defaulting to `all`) and the active chip is visibly
  highlighted. Changing the selection updates the UI immediately.
- The filter row is visible whenever the Search tab is shown, including the empty
  / idle state (so the user can pick a filter before typing) and in both the
  narrow and the wide (≥700dp) layouts — in the wide layout it sits in the 320dp
  search pane, not the detail pane.
- Selecting a filter in this story **does not yet change search results** — the
  query still runs as it does today. The visible behaviour change (scoping the
  query, re-running on filter change, cache correctness) is delivered by
  **US-85**. (Implementer's choice: ship US-84 and US-85 together if convenient,
  but keep the commits/AC separable.)
- The chips don't crowd out content: on a small phone the search field + chip row
  must still leave the results list usable; chips wrap or scroll rather than
  overflow.
- Widget tests: the three chips render under the search field; All is the default
  (no chip selected) on open; selecting a chip highlights it and deselects the
  others; tapping the active chip returns to All; the row shows in both layouts
  and in the idle state.

**Investigation notes:**
- The insertion point is the `searchPane` `Column` in
  `lib/presentation/screens/search_screen.dart` (build, ~line 338): add a third
  child (a `Wrap`/`SingleChildScrollView` of `FilterChip`s) between the
  `TextField` `Padding` and the `Expanded(child: _buildBody(...))`. Because
  `searchPane` is reused for both narrow and wide layouts, the chips appear in
  both for free.
- Add a `SearchFilter _filter = SearchFilter.all;` field to `_SearchScreenState`
  and a `setState` on chip tap. Keep this story's change inert w.r.t. searching —
  do **not** thread `_filter` into `_onSubmit`/`_service.search` here; that is
  US-85's job. (If shipping both at once, US-85's notes cover the plumbing.)
- Define `SearchFilter` somewhere reusable (its own small file under
  `domain/models/` or alongside the search service) since US-85 and the API layer
  will also need it.
- Consider the barcode-scan entry path: barcode lookups (US-…/`searchByBarcode`)
  are release-only by nature; confirm the filter row is either hidden or
  irrelevant for barcode-originated results and doesn't imply it filters a
  barcode scan.
- Precedents: the Collection/Wishlist tabs already use in-body filter/sort
  controls — match their chip styling and placement conventions for consistency.
- Roadmap fit: Phase 14 search UX — giving users control over match scope.

**Status: story only — not implemented.**

---

### US-85: Scope the Discogs query to the selected search filter

**3 SP · S5 (feature request, post-1.0 — follow-up to US-84)**

> As a user who has selected a search filter (Release, Artist, or Label),
> I want the search to match **only** that field,
> so that filtering actually changes my results — e.g. selecting Artist returns
> records by that artist rather than every release that merely mentions the text.

**Background:** US-84 adds the Release / Artist / Label chips and the selected-
filter state but deliberately leaves search behaviour unchanged. This follow-up
makes the selection *do something*: the active filter scopes the Discogs query.
Today `DiscogsApiClient.searchReleases` hardcodes `type: 'release'` and puts the
text in the general `q` parameter, so every field is matched. Discogs'
`/database/search` endpoint also accepts **field-scoped** parameters
(`release_title`, `artist`, `label`) which narrow the match while still returning
release-shaped results — so we can keep the existing `ReleaseSearchResult` cards
and add-to-collection/wishlist flow unchanged. When the filter is **All** (the
default), behaviour is exactly as it is today (general `q`).

**Acceptance criteria:**
- With **All** selected (default), search behaves exactly as before — general
  `q` query, `type=release` — so there is no regression for users who never touch
  the chips.
- With **Release** selected, the query text is matched against the release title
  (`release_title=<text>`); **Artist** matches the artist field (`artist=<text>`);
  **Label** matches the label field (`label=<text>`). Results remain
  release-shaped and the existing result cards/detail/add flows are unchanged.
- Changing the active filter **re-runs the current search immediately** for the
  text already in the box (it must not require editing the text). Clearing the
  text resets to the idle/empty state and the filter back to All (per US-84).
- Pagination ("load more") and the background cache-refresh continue to use the
  **same filter** as the originating search — page 2 of an Artist search is still
  an Artist search.
- The search result cache is **keyed by filter as well as text**, so an "All"
  search for "blue" and an "Artist" search for "blue" don't collide and don't
  return each other's results. (The cache currently keys on the normalised query
  string only.)
- Errors, rate-limit handling, "no results", and the cached-results banner all
  behave the same under a filter as under All.
- Unit tests: the service/client send the correct Discogs parameter per filter
  (`q` vs `release_title` / `artist` / `label`) with `type=release`; cache keys
  differ by filter. Widget tests: changing the chip re-issues the search; load-
  more preserves the filter; All matches today's behaviour.

**Investigation notes:**
- Plumb the filter through three layers:
  1. `DiscogsApiClient.searchReleases` (`lib/infrastructure/discogs/discogs_api_client.dart`,
     ~line 60) currently always sends `{'q': query, 'type': 'release', …}`. Add a
     filter parameter and build `queryParameters` accordingly: All →
     `q`; Release → `release_title`; Artist → `artist`; Label → `label`. Keep
     `type: 'release'` in every case so the response shape stays
     `DiscogsSearchPageDto` and `_toResult` is unchanged. **Verify against the
     live Discogs API** that `release_title`/`artist`/`label` on
     `/database/search` behave as expected (they are documented field filters; a
     quick manual check during implementation avoids a surprise).
  2. `DiscogsSearchService.search` (`lib/application/services/discogs_search_service.dart`,
     ~line 22) forwards the filter to the client; signature gains an optional
     `SearchFilter filter = SearchFilter.all`.
  3. `SearchScreen` passes `_filter` (from US-84) into `_onSubmit`,
     `_searchInBackground`, and `_loadMore`, and triggers a re-search in the chip
     `onSelected` handler (re-run `_onSubmit(_controller.text.trim())` with the
     new filter). Note `_onSubmit` currently early-returns when
     `trimmed == _lastQuery` and results are fresh — that guard must also compare
     the filter, or a filter change with identical text will be ignored. Track a
     `_lastFilter` alongside `_lastQuery`.
- **Cache correctness is the main trap.** `SearchQueryCache.normalizeKey(query)`
  (`lib/application/services/search_query_cache.dart`) keys on the text only.
  Fold the filter into the key (e.g. `'${filter.name}:${query.trim().toLowerCase()}'`)
  so filtered and unfiltered searches for the same text don't overwrite or shadow
  each other. The screen calls `SearchQueryCache.normalizeKey(trimmed)` directly,
  so update both the helper signature and its call sites.
- Reuse the `SearchFilter` enum defined in US-84; do not duplicate it.
- Edge: an empty `q`/field value should behave as today (no search). Confirm
  Discogs requires a non-empty value for the field params too.
- Precedents: US-84 (the chip UI + filter state this consumes); the existing
  `searchByBarcode` method shows the same `type: 'release'` + field-param pattern
  (`barcode=…`) already in use, so field-scoped search is an established shape in
  this client.
- Roadmap fit: Phase 14 search UX — completing the filter feature so the chips
  actually scope results.

**Status: story only — not implemented.**

---

### US-86: Move a release from wishlist to collection ("Add to collection" on the wishlist detail screen)

**3 SP · S5 (feature request, post-1.0)**

> As a user viewing an item on the wishlist detail screen,
> I want an "Add to collection" action right there,
> so that when I finally buy a record I can move it into my collection in one
> tap instead of removing it from the wishlist and re-finding it in search to
> add it.

**Background:** The wishlist detail screen (`WishlistDetailScreen`) lets me edit
priority, target price, and notes, and remove the item — but there is **no way to
add the item to my collection**. The natural lifecycle of a wantlist entry is
"want it → bought it → own it", so the missing step is the most important one.
Today the only path is: remove from wishlist, go to Search, find the release
again, open it, and add to collection — tedious and error-prone. This story adds
an **"Add to collection"** action on the wishlist detail screen that **moves**
the item: it is added to the collection and, on success, removed from the
wishlist (you don't want it any more — you have it). The add itself reuses the
existing `AddToCollectionUseCase`, and the wishlist removal reuses the existing
local-removal path.

**Acceptance criteria:**
- The wishlist detail screen shows a clear **"Add to collection"** action when an
  item is loaded (a prominent button in the body and/or an app-bar action,
  consistent with the screen's existing edit/remove affordances).
- Tapping it adds the release to the collection using the same
  `AddToCollectionUseCase` the search / release-detail flow uses, so the new
  collection item carries the release's artist/title/label/catno/format/country/
  year/cover and the standard `localOnly` sync status, default conditions, and
  retry-on-storage-error behaviour.
- **On a successful add, the item is removed from the wishlist** and the screen
  pops back, with a confirmation snackbar (e.g. "Moved to your collection"). The
  Collection and Wishlist tabs reflect the change on return (they already refresh
  via the existing `RouteAware.didPopNext`, US-80/US-35).
- **Order and atomicity:** add to the collection **first**; only remove from the
  wishlist if the add succeeded. If the add fails (`AddToCollectionStorageError`),
  the wishlist item is **left intact** and a non-destructive error is shown — the
  user never loses the wantlist entry to a failed move.
- **Already-in-collection case:** if the release is already in the collection
  (`AddToCollectionDuplicate`), treat the move as effectively done — the wishlist
  entry is redundant, so still remove it from the wishlist and report it clearly
  (e.g. "Already in your collection — removed from wishlist"). Do not create a
  duplicate collection item.
- **Discogs propagation is local-only by default** and mirrors the *default* of
  the existing wishlist remove flow (US-72): moving does **not** automatically
  record a Discogs wantlist deletion tombstone, and the collection add is
  local-first like every other add. (An opt-in "also remove from my Discogs
  wantlist" during the move could be a later follow-up; keep US-86 scoped to the
  local move so it is safe and predictable.)
- If a wishlist remove fails *after* a successful add, surface it without losing
  state: the item is in the collection and a message explains it could not be
  removed from the wishlist (so the user can remove it manually) — avoid a silent
  inconsistent state.
- Unit/widget tests cover: the button appears on a loaded item; a successful add
  removes the wishlist item, pops, and shows the snackbar; the add-failure path
  leaves the wishlist item intact; the already-in-collection path removes from
  wishlist without a duplicate; and no Discogs tombstone is created by default.

**Investigation notes:**
- `WishlistDetailScreen`
  (`lib/presentation/screens/wishlist_detail_screen.dart`) does not currently
  receive an `AddToCollectionUseCase` or a `CollectionRepository`. Add an
  `AddToCollectionUseCase? addToCollectionUseCase` constructor param (and the
  collection repo wiring for the non-injected path) following the pattern in
  `release_detail_screen.dart`, which already constructs the use case from the
  shared `AppDatabase`. `HomeShellScreen` wires repos/use-cases down to the tabs.
- `AddToCollectionUseCase.execute` takes a **`ReleaseDetail`**
  (`lib/application/use_cases/add_to_collection_use_case.dart`). The screen
  already loads a nullable `_releaseDetail` via
  `DiscogsReleaseDetailService.getCachedOrFetch` (US-76), but it can be null
  offline / uncached. The use case reads only `id`, `artist`, `title`, `label`,
  `catno`, `format`, `country`, `year`, `coverUrl` — **all of which the
  `WishlistItem` already has** — so build a minimal `ReleaseDetail` from the item
  (preferring the richer `_releaseDetail` when present) rather than blocking the
  move on a network fetch. (Alternatively, add an `execute`-from-item overload to
  the use case; prefer the local-build approach to avoid changing the use-case
  contract.)
- For the wishlist removal, reuse the existing local path: `_repository.remove(
  item.id)` then `Navigator.pop()` — the same call `_removeItem` already makes
  (`wishlist_detail_screen.dart:269`). Do **not** route the move through
  `_confirmRemove`'s opt-in tombstone branch; the default move is local-only.
- The duplicate guard already exists in the use case
  (`containsRelease` → `AddToCollectionDuplicate`); map that result to the
  "already in collection — removed from wishlist" branch.
- Precedents: US-08/US-12 (add-to-collection / add-to-wishlist flows and the
  `AddToCollectionUseCase`), US-72/US-81 (wishlist removal path and the
  local-only-vs-Discogs distinction), US-80 (tabs refresh on return). This story
  is the inverse-direction sibling of US-81 (which removes a saved item from the
  detail screen) — here we *promote* a wishlist item into the collection.
- Roadmap fit: Phase 14 UX polish — completing the wantlist→collection lifecycle.

**Status: story only — not implemented.**
