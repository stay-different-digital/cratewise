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

**Status (2026-06-17): implemented (UI + state only).** Added a reusable
`SearchFilter { all, release, artist, label }` enum
(`lib/domain/models/search_filter.dart`, with a `chipLabel` getter) for US-85 to
reuse. `SearchScreen` holds `SearchFilter _filter = SearchFilter.all` and renders
a `_SearchFilterChips` `Wrap` of three `FilterChip`s
(`Key('search-filter-chip-{release,artist,label}')`) between the search
`TextField` and the results body in the shared `searchPane`, so the row shows in
both the narrow and the wide (320dp pane) layouts and in the idle state. Single-
choice: selecting one deselects the others; tapping the active chip returns to
All (no chip selected). **Deliberately inert** — the filter is not threaded into
`_onSubmit`/`_service.search`, so results are unchanged; query scoping, re-run-
on-change, and filter-keyed cache are US-85. Barcode scanning is unaffected (the
chips live only on `SearchScreen`, not `BarcodeScanScreen`). 6 new widget tests
(chips render, All default, single-select, deselect-to-All, narrow layout, no
re-search on chip tap); suite 2401 → 2407, all green.

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

**Status (2026-06-17): implemented.** Plumbed `SearchFilter` through all three
layers: `DiscogsApiClient.searchReleases` gained a `SearchFilter filter` param
and maps the text to `q` (All) / `release_title` / `artist` / `label`, always
keeping `type=release`; `DiscogsSearchService.search` forwards it; `SearchScreen`
passes `_filter` into `_onSubmit`, `_searchInBackground`, and `_loadMore`, tracks
`_lastFilter` so the skip-guard also compares the filter, and re-runs the current
search from the chip `onSelected` handler. Clearing the field resets the scope to
All. `SearchQueryCache.normalizeKey` now takes an optional `SearchFilter` and
prefixes the key (`'${filter.name}:<text>'`) so All vs Artist for the same text
don't collide; the barcode cache keeps the default All scope.
Pagination/background-refresh use the originating filter. 7 new/updated tests
(api-client per-filter params, service forwarding, filter-scoped cache key, chip
re-issues the search, pagination preserves the filter, no cross-filter cache
collision); suite 2407 → 2414, all green. **Live-API note:** the
`release_title`/`artist`/`label` field filters are documented Discogs
`/database/search` params but were not verified against the live API from this
environment — worth a quick manual check on device.

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

**Status (2026-06-16): implemented.** `WishlistDetailScreen` gained an optional
`AddToCollectionUseCase` (self-constructed from the shared `AppDatabase` via
`LocalCollectionRepository` in the non-injected path) and an "Add to collection"
app-bar action (`Key('add-to-collection-button')`, leftmost/most prominent).
Tapping it builds a minimal `ReleaseDetail` from the item — preferring the
loaded Discogs `_releaseDetail` when present, so the move never blocks on a
fetch — and runs the existing `AddToCollectionUseCase`. **Add-first/remove-on-
success:** on `AddToCollectionSuccess` or `AddToCollectionDuplicate` the wishlist
item is removed and the screen pops with a snackbar ("Moved to your collection."
/ "Already in your collection — removed from wishlist."); on
`AddToCollectionStorageError` the wishlist entry is left intact with a
non-destructive message. A wishlist-remove failure *after* a successful add is
surfaced ("…could not remove it from the wishlist. Please remove it manually.")
rather than left silent. The move is local-only — it never records a Discogs
wantlist tombstone. 6 new widget tests (button present, success move, fields
carried, add-failure intact, duplicate-no-dupe, no-tombstone); suite 2395 → 2401,
all green. Opt-in "also remove from my Discogs wantlist" during the move remains
a possible later follow-up.

---

### US-87: Replace the personal contact email with the Cratewise team address

**1 SP · S5 (release hygiene, pre-launch)**

> As the maintainer preparing Cratewise for the stores,
> I want every contact/feedback reference to use the dedicated
> **hellowerecratewise@gmail.com** address instead of my personal
> **hellowerecratewise@gmail.com**,
> so that user feedback, privacy enquiries, and store-review correspondence go to
> a project mailbox rather than a personal inbox, and nothing personal is shipped
> in the public listing or the app.

**Background:** The app and its release/store docs currently point users at the
personal address `hellowerecratewise@gmail.com` — in the in-app **Send feedback** button
(`send_feedback_tile.dart`), the hosted privacy policy and the privacy doc, the
store listing contact field, the store-review notes, the beta triage doc, and the
marketing site footer/contact. A dedicated team address
(`hellowerecratewise@gmail.com`) has been created, so every reference should be
switched over before the privacy policy is hosted and the store forms are filed
(Phase 11/13 [Fred] items). This is a pure find-and-replace of a single, stable
string — no behaviour change beyond the destination of a `mailto:`.

**Acceptance criteria:**
- Every occurrence of `hellowerecratewise@gmail.com` in the app, docs, and marketing
  site is replaced with `hellowerecratewise@gmail.com`. Known occurrences (verify
  none have been added since):
  - `lib/presentation/widgets/send_feedback_tile.dart` — the
    `feedbackEmailAddress` constant (drives the in-app Send feedback `mailto:`).
  - `docs/store/PRIVACY_POLICY.md` and `site/src/privacy.md` — "Questions about
    this policy".
  - `docs/store/STORE_LISTINGS.md` — the "Contact email" field (two places).
  - `docs/release/STORE_REVIEW.md` — App Review contact note.
  - `docs/beta/FEEDBACK_TRIAGE.md` — the Send-feedback channel row.
  - `site/src/index.njk` (contact line) and `site/src/_layouts/base.njk` (footer
    `mailto:`).
- The in-app Send feedback button opens a `mailto:` to the new address with the
  existing subject/body (version + platform prefilled) unchanged; the snackbar
  fallback message names the new address.
- No occurrence of the old address remains anywhere in the repo except immutable
  history (git log / CHANGELOG entries that record past state are not rewritten).
  `grep -ri "hellowerecratewise@gmail.com"` over the working tree (excluding
  `graphify-out/`, `.git/`) returns nothing.
- The new mailbox is confirmed to exist and receive mail before the privacy
  policy is re-hosted and the store forms are filed ([Fred]).
- Tests stay green. The existing `send_feedback_tile_test.dart` asserts against
  the `feedbackEmailAddress` constant (not the literal), so updating the constant
  needs no test change — but the suite must still pass.

**Investigation notes:**
- 9 occurrences across 8 files at time of writing (see the list above); all are
  the same literal string, so a single careful replace covers them. Re-grep
  before finishing in case new docs reference it.
- The only code reference is the `feedbackEmailAddress` constant in
  `send_feedback_tile.dart`; everything else is Markdown/Nunjucks docs and the
  static site. The widget reads the constant, and the test references the
  constant symbol, so behaviour and tests follow automatically.
- Do **not** touch the `graphify-out/` knowledge-graph artifacts or
  `~/.claude/...` memory; those regenerate and are out of scope.
- The marketing site (`site/`) is a separate static build — confirm whether it
  needs a re-deploy after the change (likely yes, alongside the privacy-policy
  hosting in Phase 11).
- CHANGELOG / commit history that mentions the old address as a historical fact
  should be left as-is (don't rewrite history); only live, user-facing references
  change.
- Precedents: US-59/US-60/US-61 (privacy policy + store listings that carry the
  contact email), US-64 (the in-app Send feedback tile and its constant).
- Roadmap fit: Phase 11/13 release readiness — replacing a personal address with
  a project mailbox before going public.

**Status (2026-06-17): implemented.** Replaced `hellowerecratewise@gmail.com` with
`hellowerecratewise@gmail.com` across all 8 live files: the
`feedbackEmailAddress` constant (`send_feedback_tile.dart`), the privacy policy
(`docs/store/PRIVACY_POLICY.md` + `site/src/privacy.md`), the store listings
(`docs/store/STORE_LISTINGS.md`, two places), the store-review note
(`docs/release/STORE_REVIEW.md`), the beta triage doc
(`docs/beta/FEEDBACK_TRIAGE.md`), and the marketing site
(`site/src/index.njk` contact line + `site/src/_layouts/base.njk` footer
`mailto:`). The Send feedback button now opens a `mailto:` to the new address
with subject/body unchanged; the snackbar fallback names the new address. The
only code reference was the constant, and `send_feedback_tile_test.dart` asserts
against the constant symbol, so no test change was needed — full suite green
(2414). The old address now remains only in immutable history (git/CHANGELOG)
and in this story's own description of the migration. **[Fred]** before going
public: confirm the new mailbox receives mail, and re-deploy the marketing site
alongside the privacy-policy hosting (Phase 11).

---

### US-88: Flesh out the project README with complete project information

**2 SP · S5 (docs / contributor onboarding)**

> As a developer (or a recruiter, contributor, or future me) opening the repo,
> I want the root `README.md` to give a complete, accurate picture of what
> Cratewise is, how it's built, and how to run/test/build it,
> so that anyone can understand and work on the project without spelunking
> through `docs/` or the source first.

**Background:** The root `README.md` is currently a thin 79-line file: a one-line
description, the platform list, a Getting Started block, and run/test commands.
The project itself is far richer — a clean-architecture Flutter 3.44 / Dart 3.12
app with a Discogs integration, Drift (SQLite) local storage, ~2414 tests, a
graphify knowledge graph, and an extensive `docs/` tree (architecture, api,
product/roadmap, security, qa, release, store, user-stories). None of that is
discoverable from the README. This story brings the README up to the standard of
a good open-source/portfolio project README so it stands on its own as the
front door to the repo. It is **documentation only** — no code or behaviour
changes.

**Acceptance criteria:**
- The README opens with the project name, a concise one–two sentence description,
  and the existing Discogs trademark disclaimer ("uses the Discogs API but is not
  affiliated with / endorsed by Discogs") kept verbatim.
- It covers, at minimum, these sections (order/styling at the implementer's
  discretion, but all present):
  - **What it is / features** — a short feature list (search, barcode scan,
    collection + wishlist, Discogs import/export, CSV import/export, offline-first
    local storage, thumbnail caching, sync-status, failed-action retry).
  - **Platforms** — Android phones, iPhone, iPad (desktop/web out of scope) — keep
    the existing note.
  - **Tech stack & architecture** — Flutter 3.44 / Dart 3.12, clean architecture
    (domain / application / infrastructure / presentation), Drift/SQLite,
    GoRouter; link to `docs/architecture/` rather than duplicating it.
  - **Project structure** — a brief `lib/` layer overview and a pointer to the
    `docs/` tree (one line per top-level docs area).
  - **Getting started** — prerequisites (Flutter SDK ≥ the pinned version,
    CocoaPods for iOS) and the existing `flutter pub get` / `flutter run` flow.
  - **Running tests & checks** — `dart format .`, `flutter analyze`,
    `flutter test` (note the ~2414-test suite), plus the iOS/Android build
    commands already in the file.
  - **Discogs setup** — that a personal access token is entered in-app under
    Settings (link `docs/api/DISCOGS_API.md` if useful); **never** include a real
    token.
  - **Knowledge graph (graphify)** — a short note that `graphify-out/` holds a
    queryable graph and how to use it (mirrors `CLAUDE.md`).
  - **Contributing / conventions** — branch + commit conventions, "run format +
    analyze + test before committing", and the `graphify update .` step after
    code changes.
  - **License / status** — the project's license (or "proprietary / all rights
    reserved" if none) and current version (`1.0.0+1` from `pubspec.yaml`) /
    release status; link the privacy policy and store listings under `docs/`.
- All facts are **accurate and verified against the repo** at write time — the
  Flutter/Dart versions match `pubspec.yaml`/CI, the test count is current (or
  phrased approximately, e.g. "2400+ tests"), and every referenced `docs/` path
  actually exists.
- The README contains **no secrets** — no Discogs token, API keys, or `.env`
  contents — and uses the team contact address `hellowerecratewise@gmail.com`
  (US-87) if a contact line is included, never the old personal address.
- Internal links use repo-relative paths and resolve (no dead links); commands
  shown are copy-pasteable and correct.
- Markdown renders cleanly on GitHub (headings, fenced code blocks, lists); a
  short table of contents is optional but nice for a long README.

**Investigation notes:**
- Source of truth for facts: `pubspec.yaml` (name `cratewise`, description, version
  `1.0.0+1`, `sdk: ^3.12.0`), the `docs/` subdirectories listed above, the
  environment notes (Flutter 3.44; CocoaPods via Homebrew; iOS builds need
  `GIT_CONFIG_VALUE_0=all` from a bare shell — decide whether that belongs in the
  README or stays a local note), and `CLAUDE.md` for the graphify workflow.
- Keep the existing run/test/build command blocks — they are already correct;
  reorganise rather than rewrite.
- Don't duplicate large docs into the README; **link** to `docs/architecture/`,
  `docs/product/ROADMAP_V2.md`, `docs/store/PRIVACY_POLICY.md`, etc.
- A screenshot/hero image is a nice-to-have but optional and out of scope unless
  assets already exist under `docs/design/` or `site/`.
- Precedents: US-58/US-59/US-60/US-61 (release + store docs the README should
  link to), US-87 (use the team contact address), `CLAUDE.md` (graphify section).
- Roadmap fit: Phase 14 polish / project presentation — a strong front door for
  the repo ahead of open-sourcing or sharing.

**Status: implemented.** Rewrote the root `README.md` (79 → ~210 lines) with all
required sections: features, platforms, tech stack & clean-architecture overview
(linking `docs/architecture/`), `lib/` layer map + a one-line-per-area `docs/`
tree, getting started (Flutter SDK + CocoaPods prereqs, run flow), tests/checks
(`dart format`/`analyze`/`test`, ~2400+ suite, build commands), Discogs in-app
token setup (link `docs/api/DISCOGS_API.md`, no secrets), the graphify workflow,
contributing/commit conventions, and license/status (`1.0.0+1`,
proprietary/all-rights-reserved — no `LICENSE` file exists). Facts verified
against `pubspec.yaml` (name `cratewise`, version `1.0.0+1`, `sdk: ^3.12.0`),
the live `docs/` dirs, and the test suite; the empty `lib/core/` & `lib/features/`
scaffold dirs were deliberately omitted in favour of the real layers per
`ARCHITECTURE.md`. Contact uses `hellowerecratewise@gmail.com` (US-87); all
internal links are repo-relative and resolve. Docs-only — no code/tests touched.

---

### US-89: Publish the CHANGELOG on the Cratewise (11ty) website

**3 SP · S5 (web / release communication)**

> As a user or prospective user visiting the Cratewise site,
> I want a **Changelog** page that shows what's new in each release,
> so that I can see the app's progress without digging through the GitHub repo.

**Background:** The marketing/privacy site under `site/` is an Eleventy (11ty v3)
static site deployed to GitHub Pages (`.github/workflows/deploy-pages.yml`, served
from `https://<owner>.github.io/Crate/`). It currently has only a landing page
(`index.njk`) and the privacy policy (`privacy.md`), both using
`_layouts/base.njk`. The release notes live in the repo-root `CHANGELOG.md`
(consolidated into the `[1.0.0]` entry per US-69) but are not surfaced on the
site. This story adds a **Changelog page** generated from the **single source of
truth** — the root `CHANGELOG.md` — so the site and the repo never drift. The
main wrinkle is that Eleventy only reads from `site/src`, while `CHANGELOG.md`
lives at the repo root, so the build must pull it in.

**Acceptance criteria:**
- The site has a `/changelog/` page rendered through `base.njk`, with a title and
  description, listed in the site nav (header and/or footer in `base.njk`).
- The page content is generated from the repo-root `CHANGELOG.md` — **not a
  hand-maintained copy**. The root file stays the single source of truth; any
  on-site copy is generated at build time and is git-ignored (or clearly marked
  generated). Editing the changelog means editing only the root file.
- The Markdown renders to proper HTML (headings, lists, links, the version
  sections) consistent with the site's styling.
- Internal links remain correct under the GitHub Pages path prefix (the build
  runs `--pathprefix=/Crate/` via `HtmlBasePlugin`); links inside the changelog
  that point at repo files (e.g.
  `docs/archive/CHANGELOG_DEV_HISTORY.md`) either resolve to the GitHub repo
  (absolute URL) or are handled so they don't 404 on the site.
- `npm run build` in `site/` (and `npx @11ty/eleventy --pathprefix=/Crate/` as CI
  runs it) produces `_site/changelog/index.html` with the changelog content.
- The deploy workflow **actually redeploys when the changelog changes**: its
  `on.push.paths` filter currently only watches `site/**`, so add `CHANGELOG.md`
  (and the sync mechanism's inputs) to the trigger, otherwise a changelog edit
  won't publish.
- No secrets and no broken Discogs-disclaimer; the existing pages and styling are
  unaffected.

**Investigation notes:**
- Eleventy config (`site/eleventy.config.js`) is ESM, `dir.input = src`,
  `output = _site`, `layouts = _layouts`, with `HtmlBasePlugin` and a CI
  `--pathprefix`. Pages declare `layout: base.njk` + `title` in front matter (see
  `privacy.md`).
- Two viable mechanisms — pick one and note the trade-off:
  1. **Prebuild copy (recommended):** an npm `prebuild` script in
     `site/package.json` copies `../CHANGELOG.md` → `site/src/changelog.md`,
     prepending the `layout: base.njk` / `title` / `permalink: /changelog/` front
     matter. Eleventy then renders it as a normal Markdown page (Markdown→HTML for
     free). Git-ignore the generated `site/src/changelog.md`. CI runs `npm ci`
     before the build, so a `prebuild`/`build` script hook runs automatically.
  2. **Global data + template:** `src/_data/changelog.js` reads `../../CHANGELOG.md`
     via `node:fs` and a `changelog.njk` renders it through a markdown-it filter
     (add the filter to the config). No generated file, but you must wire up
     Markdown rendering yourself.
- The header/footer nav lives in `base.njk`; add the Changelog link there so it
  appears site-wide.
- Mind the CI `paths` trigger (above) — it is the easy thing to forget and the
  reason a changelog update would silently not deploy.
- Precedents: US-59/privacy hosting (the same site + Pages workflow), US-69 (the
  consolidated root `CHANGELOG.md` this consumes).
- Roadmap fit: Phase 14 — release communication on the public site.

**Status: implemented.** Added a `/changelog/` page generated from the repo-root
`CHANGELOG.md` (single source of truth). Mechanism: an Eleventy global-data file
`site/src/_data/changelog.js` reads `../../../CHANGELOG.md` and rewrites
repo-relative Markdown links (e.g. `docs/archive/CHANGELOG_DEV_HISTORY.md`) to
absolute `https://github.com/itris/Crate/blob/master/...` URLs so they don't 404
under the Pages path prefix; `site/src/changelog.njk` (layout `base.njk`,
`permalink: /changelog/`) renders that string through a new `markdown` filter
(markdown-it, added to `eleventy.config.js` + declared in `package.json`).
**Note — the originally-recommended prebuild-copy / `eleventy.before` approach
was rejected:** Eleventy scans the input dir *before* the `eleventy.before`
event, so a file written then is absent from the same build, and CI runs
`npx @11ty/eleventy` directly (not `npm run build`) on a clean checkout, so it
would never appear. The global-data + filter approach renders in one pipeline
pass with no generated file (nothing to git-ignore). Added the Changelog link to
the header + footer nav in `base.njk`, an `addWatchTarget("../CHANGELOG.md")`
for `--serve`, and `CHANGELOG.md` to the deploy workflow's `on.push.paths` so
changelog edits redeploy. Verified a clean `npx @11ty/eleventy --pathprefix=/Crate/`
writes `_site/changelog/index.html` with rendered headings, the rewritten
dev-history link, and `/Crate/changelog/`-prefixed nav.

---

### US-90: Publish the README (project overview) on the Cratewise (11ty) website

**3 SP · S5 (web / project presentation — follow-up to US-89)**

> As someone evaluating Cratewise from the website,
> I want a page that presents the project overview from the README,
> so that I can read what the app is and how it's built without going to GitHub.

**Background:** Follow-up to US-89, reusing the same root-Markdown→Eleventy
mechanism for the repo-root `README.md`. Best sequenced **after US-88** (which
fills the README out), so there is worthwhile content to publish. A README is
developer-facing and contains repo-relative links and dev instructions, so this
story must decide how much of it belongs on a public site and how to handle links
that only resolve inside the repo.

**Acceptance criteria:**
- The site has a project-overview page (e.g. `/about/` or `/readme/`) rendered
  through `base.njk`, linked in the site nav, generated from the repo-root
  `README.md` as the single source of truth (same generated-not-hand-edited rule
  as US-89).
- The Markdown renders cleanly and matches site styling.
- **Repo-relative links and dev-only content are handled** so the public page
  isn't full of dead links: either rewrite relative links (e.g. `docs/...`,
  source paths) to absolute GitHub URLs at build time, or publish a suitable
  subset/“About” framing of the README rather than the raw developer instructions.
  The chosen approach is documented in the page or build script.
- Path-prefix-safe under `--pathprefix=/Crate/`; `npm run build` produces the new
  page; the deploy workflow's `paths` filter includes `README.md` so README edits
  redeploy.
- Contact references use `hellowerecratewise@gmail.com` (US-87); no secrets; the
  Discogs disclaimer remains.

**Investigation notes:**
- Reuse the US-89 mechanism (prebuild copy or `_data` + markdown-it). If using the
  prebuild-copy approach, this is a second copy step (`../README.md` →
  `site/src/about.md` with front matter) plus a link-rewriting pass.
- Decide README-vs-About scope with US-88's author: the full dev README may be
  more than a marketing site wants; an "About / project overview" excerpt may read
  better for a public audience. Keep the repo `README.md` as the source either way.
- Link rewriting is the main work: relative links like `docs/architecture/` or
  `lib/...` 404 on the Pages site; map them to
  `https://github.com/<owner>/Crate/blob/master/...` or strip them.
- Precedents: US-89 (the mechanism + CI trigger), US-88 (the README content),
  US-87 (contact address).
- Roadmap fit: Phase 14 — project presentation on the public site.

**Status: story only — not implemented.**

---

### US-91: Fix the failing GitHub Pages build (Jekyll vs the Eleventy Actions workflow)

**2 SP · S5 (CI / release — release-blocking: the public site does not deploy)**

> As the maintainer publishing the Cratewise site,
> I want the GitHub Pages deployment to succeed using our Eleventy build,
> so that the privacy policy (and the planned changelog/README pages) actually go
> live instead of failing on every push.

**Background:** The Pages build is currently failing with:

```
GitHub Pages: jekyll v3.10.0
Theme: jekyll-theme-primer
Source: /github/workspace/.
github-pages 232 | Error: Invalid scheme format: 'phase2 - Prompt 5'
```

This is the **legacy Jekyll "deploy from a branch" builder scanning the whole
repo root** — not our intended build. The repo already ships an Eleventy site
under `site/` with a GitHub Actions workflow
(`.github/workflows/deploy-pages.yml`) that builds `site/_site` and publishes via
`actions/deploy-pages`. Because the Pages **Source** is still set to "Deploy from
a branch", GitHub runs Jekyll over `/github/workspace/.`, picks up unrelated
Markdown (there is no `_config.yml`, so it scans everything), and crashes on the
archived prompt files under `docs/archive/prompts/used/` whose names/headings
contain a colon (e.g. `phase2 - Prompt 5D: …`). Jekyll plugins
(`jekyll-relative-links` / `jekyll-titles-from-headings`) treat the text before
the colon as a URI scheme; `phase2 - Prompt 5` contains spaces, so Addressable
raises `Invalid scheme format`. The fix is to make Pages use our Eleventy
workflow and to harden the repo so a stray Jekyll build can't run.

**Acceptance criteria:**
- The public site (`https://<owner>.github.io/Crate/`) **deploys successfully** —
  no `Invalid scheme format` error — and the privacy page (and existing pages)
  render correctly under the `/Crate/` path prefix.
- GitHub Pages **Build and deployment → Source** is set to **GitHub Actions**, so
  the existing `deploy-pages.yml` (Eleventy → `actions/deploy-pages`) is the only
  builder and the implicit Jekyll branch build no longer runs over the repo root.
  *(Repo Settings change — **[Fred]**; the rest of this story makes the repo
  resilient regardless.)*
- Defensive hardening so a Jekyll build can never fail the repo again, even if the
  setting is changed back: add a repo-root `.nojekyll` file (and confirm the
  Eleventy artifact `site/_site` is unaffected). With `.nojekyll`, the legacy
  builder serves files as-is and skips the Jekyll processing that crashes.
- The crash trigger is neutralised: either the `.nojekyll` above is sufficient, or
  the archived prompt filenames/headings under `docs/archive/prompts/used/` that
  contain a colon are renamed/escaped so no tool parses them as a `scheme:path`
  URI. (Prefer `.nojekyll`; renaming ~30 archive files is optional hardening.)
- A push to `master` (or a manual `workflow_dispatch`) results in a **green Pages
  deployment**, verified in the Actions tab and by loading the live URL.
- No change to app code or tests; the Eleventy site content is otherwise
  unchanged.

**Investigation notes:**
- The log is the proof: `github-pages 232`, `jekyll v3.10.0`,
  `Source: /github/workspace/.`, theme `jekyll-theme-primer` — all hallmarks of
  the default branch-based Jekyll build, which our Eleventy setup is meant to
  replace.
- Root cause is the **Pages Source setting**, not the Eleventy config. The
  workflow `deploy-pages.yml` already builds correctly with
  `npx @11ty/eleventy --pathprefix=/Crate/`; it just isn't the active deployment
  source.
- There is no `_config.yml` at the root, so Jekyll scans the entire tree
  (including `docs/`), which is how it reaches the archived prompt files.
- The offending files: `docs/archive/prompts/used/phase2 - Prompt 5*.md` (and
  siblings) — colons in the filename/first heading. Addressable's scheme
  validation rejects a "scheme" containing spaces.
- `.nojekyll` is the standard, low-risk guard against the legacy builder; it lives
  at the repo root for branch builds. The Actions artifact path is `site/_site`.
- Cross-reference US-89/US-90: once the changelog/README pages are added, this
  same (Actions) deployment carries them; getting the deployment correct here
  unblocks those.
- Precedents: US-59 (privacy hosting on this site), the existing
  `deploy-pages.yml` workflow.
- Roadmap fit: Phase 11/14 release readiness — the public site must build before
  launch.

**Status (2026-06-17): partially implemented — repo guard done; Pages Source
switch pending [Fred].** Added an empty `.nojekyll` at the repo root. Under the
legacy "deploy from a branch" Jekyll builder this disables Jekyll processing
entirely, so the build can no longer crash on the colon-containing archived
prompt filenames under `docs/archive/prompts/used/` (`Invalid scheme format:
'phase2 - Prompt 5'`). This neutralises the failure. **Still required from
[Fred]:** switch GitHub Pages **Build and deployment → Source** to **GitHub
Actions** so the existing Eleventy workflow (`deploy-pages.yml`) is the actual
builder — otherwise Pages serves the raw repo root (no error, but not the real
site). The Eleventy artifact (`site/_site`, published via Actions) is unaffected
by the root `.nojekyll`. Renaming the ~30 colon-containing archive files was left
undone as optional hardening — `.nojekyll` covers the failure. No app code or
tests touched.

---

### US-92: Upgrade GitHub Actions off the deprecated Node.js 20 runtime

**1 SP · S5 (CI maintenance)**

> As the maintainer of the CI/CD pipelines,
> I want the GitHub Actions we depend on bumped to versions that run on Node.js
> 24,
> so that the builds stop emitting the Node 20 deprecation warning and don't
> break when GitHub removes the Node 20 runtime.

**Background:** Both workflows currently log a deprecation warning, e.g.:

```
Node.js 20 is deprecated. The following actions target Node.js 20 but are being
forced to run on Node.js 24: actions/checkout@v4.
```

GitHub is removing the Node 20 runtime from Actions runners (see
`https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/`).
Actions are currently being *force-run* on Node 24, which works for now but will
break once Node 20 support is dropped. The pinned actions just need bumping to a
major version whose JS runtime is Node 24. This is pure CI hygiene — no app code,
no behaviour change.

**Acceptance criteria:**
- No workflow run emits the "Node.js 20 is deprecated" warning anymore.
- Every first-party action pinned to a Node-20 major is bumped to the current
  major that runs on Node 24. Known usages to review/bump:
  - `.github/workflows/deploy-pages.yml`: `actions/checkout@v4`,
    `actions/setup-node@v4`, `actions/upload-pages-artifact@v3`,
    `actions/deploy-pages@v4`.
  - `.github/workflows/flutter-ci.yml`: `actions/checkout@v4` (two jobs),
    `subosito/flutter-action@v2`.
- For each action, the chosen tag is the latest stable major (e.g.
  `actions/checkout@v5`, `actions/setup-node@v5`) verified to use Node 24 — don't
  guess version numbers; check each action's releases. Third-party actions
  (`subosito/flutter-action`) are bumped only if they actually trigger the
  warning / are on Node 20; otherwise note that they're fine.
- Both workflows still pass end-to-end after the bump: the Flutter CI
  (format/analyze/test/build jobs) and the Pages deploy run green, with no
  behavioural change to what they do.
- No unrelated changes (don't restructure the workflows; just version bumps and,
  if a bumped action renamed inputs, the minimal input fixes its changelog
  requires).

**Investigation notes:**
- The warning currently names `actions/checkout@v4`, but the same Node-20 issue
  applies to the other first-party actions on older majors — bump them together so
  the warning doesn't simply reappear from a different action next run.
- `actions/checkout` and `actions/setup-node` moved to Node 24 at v5; the Pages
  actions (`upload-pages-artifact`, `deploy-pages`) and `upload-artifact` have
  newer majors too — confirm the current major per action's release notes rather
  than assuming.
- Check `subosito/flutter-action`'s latest release notes; if v2 still targets
  Node 20, bump to the version that doesn't (or pin a newer ref). If it's already
  fine, record that so a reviewer doesn't chase it.
- This is independent of US-91 (which is about the Pages *source*/Jekyll problem);
  the two can land separately, but both touch `deploy-pages.yml`, so coordinate to
  avoid a conflict.
- Verify by opening the run logs after the change and confirming the deprecation
  warning is gone from both workflows.
- Roadmap fit: Phase 11/14 — keep CI/CD green and future-proof ahead of release.

**Status (2026-06-17): implemented.** Bumped every first-party action pinned to
a Node-20 major to its Node-24 major, verified against each action's releases /
`action.yml` `runs.using`:
- `deploy-pages.yml`: `actions/checkout@v4→v5`, `actions/setup-node@v4→v5`,
  `actions/upload-pages-artifact@v3→v5` (composite; v5 bundles upload-artifact v7
  on Node 24), `actions/deploy-pages@v4→v5` (`runs.using: node24` confirmed).
- `flutter-ci.yml`: `actions/checkout@v4→v5` (both jobs).
`subosito/flutter-action@v2` was **left as-is**: it is a composite action (runs
shell, not a Node runtime), which is why the deprecation warning never named it.
No first-party `@v4`/`@v3` Node-20 pins remain. No app code or tests touched;
verify the warning is gone in the next run logs. Out-of-scope note discovered:
`flutter-ci.yml` triggers on `main`/`develop` but the repo's default branch is
`master`, so that workflow may not run on pushes — worth a separate fix.

---

### US-93: Rename the GitHub repository from `Crate` to `cratewise`

**2 SP · S5 (repo / release hygiene)**

> As the maintainer,
> I want the GitHub repository renamed from `Crate` to `cratewise`,
> so that the repo URL matches the product name and the GitHub Pages site is
> served from a `/cratewise/` path that lines up with the brand.

**Background:** The repository is currently named `Crate` (owner `itris`, i.e.
`https://github.com/itris/Crate`, Pages at `https://itris.github.io/Crate/`),
while the product, package, and everything user-facing is **Cratewise**. Renaming
the repo to `cratewise` aligns the two. GitHub renames are mostly seamless — it
auto-redirects the old URL and existing clones keep working via the redirect — but
a few places **hard-code the repo name** and must be updated, the most important
being the GitHub Pages **path prefix** (`/Crate/`), which is case-sensitive and
will 404 the site if it doesn't match the new repo name.

**Acceptance criteria:**
- The GitHub repository is renamed to `cratewise` (**[Fred]** — repo Settings →
  rename; only the owner can do this). Confirm the new canonical name/casing
  (`cratewise`) since the Pages path prefix must match it exactly.
- The GitHub Pages path prefix is updated to the new name everywhere it is
  hard-coded, so the published site resolves under
  `https://itris.github.io/cratewise/`:
  - `.github/workflows/deploy-pages.yml` — `--pathprefix=/Crate/` → the new
    prefix, and the explanatory comment.
  - `site/eleventy.config.js` — the comment referencing
    `https://<user>.github.io/Crate/`.
- All hard-coded repo/Pages URLs in docs are updated to the new path:
  - `docs/store/STORE_LISTINGS.md` — privacy policy URL
    `https://itris.github.io/Crate/privacy/`.
  - `docs/release/STORE_PUBLISHING_GUIDE.md` — the verify step URL.
  - Any `https://github.com/itris/Crate/...` links (e.g. in the README/CONTRIBUTING
    once US-88/US-90 add them) point at the new repo URL. (GitHub redirects the old
    one, but links should be canonical.)
- The `.github/ISSUE_TEMPLATE/*.md` "about" lines ("Request a new feature for
  Crate" / "Report a bug in Crate") read "Cratewise".
- The local clone's `origin` remote is updated to the new URL
  (`git remote set-url origin …`) — optional, since GitHub redirects, but tidy.
  The local working-directory path (`/Users/fred/Projects/Crate`) is independent
  of the GitHub name and does **not** have to change.
- After the rename + path-prefix change, the Pages site **deploys and loads** at
  the new URL (coordinates with US-91, which fixes the build itself), and the
  privacy policy page resolves at `…/cratewise/privacy/`.
- No occurrence of the old `/Crate/` Pages path or `itris/Crate` URL remains in
  live config/docs (git history excepted). The product copy "Record Crate" in
  `STORE_COPY_OPTIONS.md` is prose, not the repo name — leave it.

**Investigation notes:**
- The high-risk item is the **path prefix**: GitHub Pages project sites serve from
  `/<repo>/`, the prefix is case-sensitive, and a mismatch silently 404s every
  asset. Update `deploy-pages.yml` and re-verify the live site.
- GitHub auto-creates a redirect from `itris/Crate` → `itris/cratewise`, so old
  clones, links, and the existing remote keep working; updating them is hygiene,
  not a hard requirement.
- Decide the exact casing with the rename: `cratewise` (lowercase, as requested)
  vs `Cratewise`. Whatever is chosen, the Pages path prefix and all URLs must
  match it exactly.
- Known hard-coded references found at write time: `deploy-pages.yml` (pathprefix
  + comment), `site/eleventy.config.js` (comment), `docs/store/STORE_LISTINGS.md`,
  `docs/release/STORE_PUBLISHING_GUIDE.md`, `.github/ISSUE_TEMPLATE/feature_request.md`
  and `bug_report.md`. Re-grep at implementation time in case US-88/89/90 added
  more.
- Sequencing: do this together with or right after US-91 (Pages build fix) since
  both touch the Pages deployment; updating the path prefix while the build is
  still broken won't surface a working site.
- Precedents: US-59/US-89/US-91 (the Pages site + workflow), US-60/US-61 (store
  listings carrying the privacy URL).
- Roadmap fit: Phase 11/14 — brand/repo alignment before going public.

**Status: story only — not implemented.**
