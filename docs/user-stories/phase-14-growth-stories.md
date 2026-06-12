# Phase 14 Growth — User Stories

Post-1.0 stories from the Phase 14 candidate list in
`docs/product/ROADMAP_V2.md` and from beta feedback.
Numbering continues from the Phase 13 stories (US-68 … US-71).

---

### US-72: Local deletions can be propagated to Discogs

**5 SP · S4 (feature request, post-1.0)**

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
