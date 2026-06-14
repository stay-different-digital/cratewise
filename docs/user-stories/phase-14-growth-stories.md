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
