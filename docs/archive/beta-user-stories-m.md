# Beta User Stories — M (Consider for beta)

Derived from M-priority known limitations recorded across Phases 1–6.  
**Beta importance:** M = consider fixing before beta  
**Story points** are estimates for a single developer.

---

### US-13: Wide-screen navigation keeps the nav rail visible

**Beta: M · 5 SP**

> As a user on an iPad or wide Android tablet,  
> I want the nav rail to remain visible when I open Release Detail,  
> so that I can switch tabs without pressing Back first.

**Acceptance criteria:**
- Tapping a search result on a layout ≥ 700 dp opens the detail pane beside the nav rail rather than pushing a full-screen route that hides it.
- The nav rail (or bottom nav bar on narrow layouts) stays reachable while Release Detail is open.
- Navigating to a different tab from the detail pane works without an extra Back tap.
- Works on iPad and wide Android tablets in both portrait and landscape.

---

### US-14: Revoked Discogs token is detected and cleared automatically

**Beta: M · 3 SP**

> As a user whose Discogs personal access token has been revoked or expired,  
> I want the app to detect the invalid token on next use and prompt me to reconnect,  
> so that I don't see a persistent error state with no clear way to fix it.

**Acceptance criteria:**
- When a Discogs API call returns a 401 (invalid token), the app transitions to a "token invalid" state.
- The user is shown a friendly message explaining that their token is no longer valid and directing them to Settings to reconnect.
- The invalid token is cleared from secure storage so that subsequent app launches do not silently fail.
- The error message does not contain the token value.

---

### US-15: Discogs credentials saved atomically

**Beta: M · 3 SP**

> As a user saving my Discogs token,  
> I want both my token and username to be saved together,  
> so that a crash between the two writes cannot leave the app in a broken half-connected state.

**Acceptance criteria:**
- `saveCredentials` writes the token and username in a single operation, or checks that both were written successfully before returning.
- If either write fails, any partial write is cleaned up and the caller receives a `StorageError`.
- `loadStatus` never returns "connected" when the token key is present but the username key is absent (or vice versa).
- Error messages shown to the user do not include the token value.

---

### US-16: Rate-limit response headers used to back off proactively

**Beta: M · 3 SP**

> As a user performing multiple actions quickly,  
> I want the app to respect Discogs rate-limit headers before hitting a 429,  
> so that requests succeed more often without unnecessary retries.

**Acceptance criteria:**
- The Discogs API client reads `X-Discogs-Ratelimit-Remaining` from each response.
- When the remaining allowance is zero (or below a configured threshold), the next outgoing request is delayed until the reset window elapses.
- The rate-limit delay is transparent to the user — no error screen is shown unless the delay exceeds a reasonable timeout.
- Applies to all API endpoints (search, release detail, collection/wishlist import, export).

---

### US-17: Collection item condition prompt after adding

**Beta: M · 2 SP**

> As a user adding a vinyl record to my collection,  
> I want to be prompted to set the media and sleeve condition immediately after adding,  
> so that I don't have to remember to edit it later from the collection list.

**Acceptance criteria:**
- After a successful "Add to Collection", the app offers a quick-set prompt (bottom sheet or dialog) for media condition and sleeve condition.
- The prompt defaults are visible so the user understands the current values.
- Dismissing the prompt without changing values saves the item with the current defaults — it does not block the add.
- The prompt does not appear when the item is already in the collection (duplicate).

---

### US-18: Cached offline release detail shows complete data

**Beta: M · 5 SP**

> As a user viewing a release while offline,  
> I want the cached detail to include the full tracklist, identifiers, and notes,  
> so that offline browsing is as useful as the live view.

**Acceptance criteria:**
- When a release is fetched successfully, the cache saves the full tracklist, identifiers (barcodes, matrix numbers), and notes — not just the summary fields.
- The offline cached view renders tracklist, identifiers, and notes sections exactly as the live view does.
- Fields that were empty or absent in the live API response remain absent in the cached view.
- The cached-data banner continues to display the last-updated date.

---

### US-19: Thumbnail cache has a storage limit and eviction policy

**Beta: M · 3 SP**

> As a user who browses many releases over time,  
> I want the app to automatically remove old thumbnails when storage grows large,  
> so that the app does not accumulate gigabytes of cached images indefinitely.

**Acceptance criteria:**
- The thumbnail cache enforces a configurable maximum size (e.g., 200 MB by default).
- When the cache exceeds the limit, the least-recently-used thumbnails are evicted first.
- Eviction runs silently in the background — no user-visible disruption.
- The user can see the current cache size in Settings and manually clear it.

---

### US-20: Failed cache writes are silently retried

**Beta: M · 2 SP**

> As a user whose device temporarily has no storage space or an I/O error,  
> I want a failed cache write to be retried automatically,  
> so that the release detail or thumbnail is available offline on the next visit without me doing anything.

**Acceptance criteria:**
- When saving release metadata or a thumbnail to the local cache fails, a retry action is recorded in the failed-action queue.
- The retry uses the existing `RetryMetadataRefreshUseCase` / `RetryThumbnailUseCase` path.
- No error is shown to the user for a cache write failure — the failure is handled silently in the background.
- The original screen interaction (viewing release detail) is not blocked or slowed by the failure.

---

### US-21: Locally-added items can be promoted to Discogs-linked status

**Beta: M · 3 SP**

> As a user who added records manually (via search or barcode) and later imports the same items from Discogs,  
> I want the app to recognize duplicates and offer to link the local record to the Discogs entry,  
> so that my manually-added items eventually show as synced rather than perpetually "local only".

**Acceptance criteria:**
- During a Discogs import, items whose `discogsReleaseId` already exists in the local collection or wishlist are detected as duplicates.
- The import preview shows these as "Already linked" rather than just "Duplicate".
- The user is offered the option to update the existing local item's sync status to `synced` without creating a second entry.
- Choosing to skip the duplicate leaves the local item's sync status unchanged.

---

### US-22: Failed collection and wishlist writes are queued for retry

**Beta: M · 5 SP**

> As a user who attempts to add a release to my collection or wishlist while the device storage is temporarily unavailable,  
> I want the failed write to be automatically retried,  
> so that I don't silently lose an item I thought I saved.

**Acceptance criteria:**
- When `CollectionRepository.add` or `WishlistRepository.add` throws a storage error, a retry action is recorded in the failed-action queue.
- The Failed Actions screen shows these entries with a friendly description (e.g., "Could not save 'Kind Of Blue' to collection").
- The retry re-attempts the full add operation (duplicate check + insert).
- A successful retry removes the entry from the queue and shows the item in the relevant list.
- A failed retry increments the attempt count and leaves the entry for the user to retry manually.

---

### US-23: Discogs import handles rate limits mid-pagination

**Beta: M · 3 SP**

> As a user with a large Discogs collection or wantlist,  
> I want the import to pause and retry gracefully if Discogs rate-limits the paginated fetch,  
> so that the full collection is imported rather than silently truncated at the point of the 429.

**Acceptance criteria:**
- When a 429 response is received during collection or wishlist pagination, the import pauses for the Discogs rate-limit reset window before retrying the failed page.
- The import preview screen shows a "Fetching…" indicator that remains visible during the back-off delay.
- The final preview reflects all pages, not just the pages fetched before the first 429.
- If retries are exhausted, the screen shows an error explaining that the import is incomplete and offers a retry-from-beginning option.

---

### US-24: Discogs exports back off on rate limits

**Beta: M · 3 SP**

> As a user exporting a large collection or wishlist to Discogs,  
> I want the export to pause between API calls when approaching the rate limit,  
> so that it completes fully rather than failing partway through with 429 errors.

**Acceptance criteria:**
- Between each per-item POST to the Discogs API, the export checks the remaining rate-limit allowance from response headers (see US-16) or applies a fixed inter-request delay.
- When a 429 is received mid-export, the export pauses and retries the failed item after the reset window.
- Items exported before the 429 are not re-exported after the retry.
- The export summary correctly reflects items that succeeded, were skipped, and failed.
- Applies to both collection export and wishlist export.

---

### US-25: CSV export is compatible with Excel on Windows

**Beta: M · 1 SP**

> As a user who opens exported CSV files in Microsoft Excel on Windows,  
> I want the app to include a UTF-8 BOM in the CSV,  
> so that artist and title fields with non-ASCII characters (accents, diacritics, non-Latin scripts) display correctly without manual re-encoding.

**Acceptance criteria:**
- Exported collection and wishlist CSV files start with the UTF-8 BOM (`\xEF\xBB\xBF`).
- Files opened directly in Excel on Windows show non-ASCII characters correctly without the user needing to select an encoding.
- Files opened in other applications (Numbers, Google Sheets, standard text editors) are unaffected.
- Existing import parsing handles files with or without the BOM.

---

### US-26: Malformed CSV rows are reported clearly during import

**Beta: M · 2 SP**

> As a user importing a CSV file that contains malformed rows,  
> I want the import preview to explicitly flag rows that cannot be parsed,  
> so that I know which entries were skipped and why, rather than having them silently accepted with default values.

**Acceptance criteria:**
- Rows where the number of cells does not match the header column count are reported as "failed" rows in the import preview, not silently padded with empty strings.
- The error description for each failed row states the row number and reason (e.g., "Row 14: expected 15 columns, found 9").
- The preview summary counts include these parse-rejected rows in the "failed" bucket.
- Valid rows from the same file are still importable even when some rows fail.

---

### US-27: Safe area applied correctly for scrollable screen content

**Beta: M · 2 SP**

> As a user on a device with a notch, Dynamic Island, home bar, or rounded corners,  
> I want content in scrollable screens to respect the safe area,  
> so that text and buttons are not obscured by system UI elements.

**Acceptance criteria:**
- All screens that contain their own `ScrollView` apply appropriate `SafeArea` padding (or equivalent `MediaQuery` padding) so content is not clipped by the notch, status bar, or home indicator.
- The bottom action bar on Release Detail is always above the home indicator on notched iPhones and iPads.
- The fix applies on both iOS (Dynamic Island / notch / home bar) and Android (display cutouts).
- No layout regression on devices without notches or rounded corners.
