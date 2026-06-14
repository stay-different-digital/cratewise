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
