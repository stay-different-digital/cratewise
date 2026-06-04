# Beta User Stories — S (Defer post-beta)

Derived from S-priority known limitations recorded across Phases 1–6.  
**Beta importance:** S = defer to post-beta  
**Story points** are estimates for a single developer.

---

### US-28: App supports deep linking and named routes

**Beta: S · 8 SP**

> As a user who receives a link to a specific release or screen,  
> I want the app to open directly to that screen,  
> so that I don't have to navigate there manually.

**Acceptance criteria:**
- All primary screens (Search, Release Detail, Collection, Collection Detail, Wishlist, Wishlist Detail, Settings, Import/Export) have named routes.
- Deep links from outside the app open the correct screen with the correct data.
- The Back button from a deep-linked screen navigates to the logical parent, not exits the app.
- GoRouter (or equivalent) replaces the current `MaterialPageRoute` push pattern throughout the app.
- Applies on Android (Intent) and iOS (Universal Links or URL scheme).

---

### US-29: Discogs token setup screen has a tappable help link

**Beta: S · 1 SP**

> As a new user setting up my Discogs token,  
> I want to tap the help URL to open the Discogs developer settings page,  
> so that I can generate my token without copying and pasting the URL manually.

**Acceptance criteria:**
- The `discogs.com/settings/developers` URL on the token setup screen is rendered as a tappable link.
- Tapping the link opens the URL in the device's default browser.
- The link is accessible (correct contrast, touch target size ≥ 48 dp).
- Uses `url_launcher` or equivalent; falls back gracefully if the browser cannot be opened.

---

### US-30: Token input field shows format guidance

**Beta: S · 1 SP**

> As a user entering my Discogs personal access token,  
> I want a hint about the expected token format or length,  
> so that I can identify an obviously wrong entry before tapping Validate.

**Acceptance criteria:**
- The token `TextField` shows a helper text explaining the expected format (e.g., "Discogs personal access tokens are 40 characters").
- A `maxLength` counter is shown so the user can see if the pasted token is clearly too short or too long.
- The hint does not reveal any example token values.
- Validation error messaging remains unchanged.

---

### US-31: Artist name parsed correctly for releases with " – " in the title

**Beta: S · 2 SP**

> As a user searching for a release from an artist whose name contains a dash (e.g. "A-ha", "E-40"),  
> I want the artist field to be displayed correctly,  
> so that I don't see the artist name incorrectly split.

**Acceptance criteria:**
- The Discogs search result DTO parser does not split artist/title on the first occurrence of ` - ` in the combined `title` field when a dedicated `artist` field is available in the response.
- For records where the API returns a combined `"Artist - Title"` string, only the rightmost unambiguous separator is used to split; if the API provides separate fields, those are used directly.
- Releases whose artist name contains ` - ` (e.g., `"Wire"` vs `"Wire - Pink Flag"`) parse to the correct artist and title.
- No regression on releases with a single clear artist/title separator.

---

### US-32: ANV (credited artist name) shown on release detail

**Beta: S · 2 SP**

> As a user viewing a pressing where the credited name differs from the canonical artist name,  
> I want the credited name (ANV) to be displayed,  
> so that I can see the name exactly as it appears on the record label.

**Acceptance criteria:**
- When the Discogs API response includes an `anv` field for an artist, the Release Detail screen shows the ANV value instead of (or alongside) the canonical name.
- When `anv` is absent or empty, the canonical artist name is shown as before.
- The ANV is used in the app bar title if present.
- No change to how artist name is stored in the local collection or wishlist (canonical name is stored for search/filter consistency).

---

### US-33: Multi-format releases show all format entries

**Beta: S · 2 SP**

> As a user viewing a release that was issued in multiple formats (e.g., LP + 7" single),  
> I want all format entries to be shown,  
> so that I get the complete picture of what the pressing includes.

**Acceptance criteria:**
- When the Discogs `formats` array contains more than one entry, all entries are shown in the Format row of Release Detail.
- Entries are separated by a clear delimiter (e.g., comma or line break).
- The Format row in collection and wishlist detail screens also shows all formats from the stored data.
- No regression for releases with a single format.

---

### US-34: Retry button uses back-off delay after rate-limit errors

**Beta: S · 2 SP**

> As a user who taps Retry immediately after hitting Discogs rate limits,  
> I want the retry to wait before re-sending the request,  
> so that I don't waste an attempt that is guaranteed to fail within the rate-limit window.

**Acceptance criteria:**
- When the last error was a rate-limit (429) response, the Retry button shows a countdown (e.g., "Retry in 12 s") and is disabled until the window elapses.
- After the countdown reaches zero the button becomes active and the user can tap it.
- For non-rate-limit errors the Retry button is immediately active as before.
- Applies to Release Detail, Search, and any other screen with a Retry button.

---

### US-35: Collection detail live-reloads when the item is changed

**Beta: S · 3 SP**

> As a user who edits a collection item on one device or triggers a sync,  
> I want the Collection Detail screen to reflect the latest data automatically,  
> so that I don't see stale condition, notes, or tags after a change elsewhere.

**Acceptance criteria:**
- Collection Detail re-fetches the item from local storage when the screen becomes active (e.g., after a pop from an edit sheet).
- The re-fetch is silent — existing content remains visible while the fetch runs; there is no full-screen loading spinner.
- If the item has been removed since the detail was opened, the screen transitions to the "item not found" state.
- No regression on the existing edit-and-save flow within the detail screen.

---

### US-36: Dates displayed in the device's locale format

**Beta: S · 3 SP**

> As a user in a country that does not use YYYY-MM-DD date notation,  
> I want dates throughout the app to be formatted according to my device's locale,  
> so that dates are immediately readable without translation.

**Acceptance criteria:**
- All user-visible dates (collection added/updated, wishlist added/updated, import/export job dates, cached-data banner date) are formatted using the `intl` package (or equivalent) with the device's current locale.
- Dates that already use a fixed format (e.g., "15 Jan 2026" in the cached banner) are replaced with locale-aware equivalents.
- The release year field (a plain integer) is unaffected.
- Works in English, German, French, Japanese, and RTL locales (Arabic, Hebrew) without layout breakage.

---

### US-37: Barcode scan area shows a viewfinder frame

**Beta: S · 3 SP**

> As a user scanning a barcode,  
> I want to see a viewfinder overlay on the camera preview,  
> so that I know where to position the barcode for a successful scan.

**Acceptance criteria:**
- The camera scan area displays a rectangular or line-shaped viewfinder overlay centred on the camera preview.
- The overlay is visually distinct from the background (e.g., white/green bracket corners).
- Scanning succeeds when the barcode is within the viewfinder bounds.
- The overlay adapts to both the narrow (phone) and wide (iPad) scan area sizes.

---

### US-38: Manual barcode entry validates the format before searching

**Beta: S · 2 SP**

> As a user typing a barcode manually,  
> I want the app to warn me if the value is clearly not a valid barcode,  
> so that I don't waste a network request on gibberish input.

**Acceptance criteria:**
- The manual barcode field validates that the input is numeric-only and has a length consistent with known barcode standards (8, 12, or 13 digits for EAN/UPC).
- An inline validation message is shown if the format is invalid before the search fires.
- The search button is disabled while the field contains an invalid format.
- QR codes and other non-barcode formats show a friendly "This doesn't look like a barcode" message.
- Completely blank input is still handled by the existing empty-input guard.

---

### US-39: Barcode scanner uses a wide two-panel layout on iPad

**Beta: S · 2 SP**

> As an iPad user scanning barcodes,  
> I want the scan area and results list to use the full available width,  
> so that I can see the camera preview and results side-by-side rather than stacked.

**Acceptance criteria:**
- On iPad (≥ 700 dp width), the barcode screen uses a two-panel layout: camera/input on the left, results on the right.
- The left scan panel is proportional to the iPad screen width, not fixed at 360 dp.
- Results appear in the right panel immediately after a scan without hiding the camera view.
- Portrait and landscape orientations both use the wide layout on iPad.

---

### US-40: Camera scan area has a flashlight toggle

**Beta: S · 2 SP**

> As a user scanning barcodes in low-light conditions,  
> I want to toggle the camera flashlight on and off from the scan screen,  
> so that I can scan without needing to find better lighting.

**Acceptance criteria:**
- A flashlight / torch toggle button is visible on the camera scan area.
- Tapping the button toggles the device torch on and off.
- The icon reflects the current torch state (on/off).
- The torch is turned off automatically when the scan area is deactivated or the screen is left.
- Works on both Android and iOS; gracefully hidden on devices that do not have a torch.

---

### US-41: Cached release detail banner shows the data age

**Beta: S · 1 SP**

> As a user viewing a release from the offline cache,  
> I want the cached-data banner to show how old the cached data is,  
> so that I know whether I should go online and refresh before relying on it.

**Acceptance criteria:**
- The offline cached-data banner already shows "last updated [date]"; this story ensures the date is always visible and not truncated.
- If the cached data is older than 30 days, the banner uses a more prominent warning colour.
- The date is formatted using the device locale (see US-36 when implemented; otherwise keep existing format).
- No change to the refresh or retry flow.

---

### US-42: Failed action queue entries expire after a configurable period

**Beta: S · 2 SP**

> As a user who accumulates failed actions over time,  
> I want old entries to be automatically removed from the queue,  
> so that the Failed Actions screen doesn't grow indefinitely with entries I can no longer act on.

**Acceptance criteria:**
- Failed action entries older than a configurable TTL (default: 30 days) are automatically deleted on app launch or on a background schedule.
- Entries that have never been attempted (status: `pending`) are not deleted by TTL — only `failed` entries past the threshold.
- The Failed Actions screen shows no stale entries older than the TTL.
- The TTL is applied silently with no notification to the user.

---

### US-43: Failed Actions screen has a "Retry All" button

**Beta: S · 1 SP**

> As a user with many entries on the Failed Actions screen,  
> I want a single "Retry All" button,  
> so that I don't have to tap each retry button individually.

**Acceptance criteria:**
- A "Retry All" button appears at the top of the Failed Actions screen when there are retryable entries.
- Tapping "Retry All" sequentially retries all entries that support retry (currently: `refreshReleaseMetadata` and `cacheThumbnail`).
- A progress indicator shows how many retries remain (e.g., "Retrying 3 of 7…").
- After all retries complete, the screen refreshes to show the updated state.
- Entries with no retry support (if any) are skipped.

---

### US-44: Failed Actions screen has a "Clear All" button

**Beta: S · 1 SP**

> As a user who wants to dismiss all failed action entries at once,  
> I want a "Clear All" button,  
> so that I can reset the list without tapping each entry individually.

**Acceptance criteria:**
- A "Clear All" option is available on the Failed Actions screen (e.g., in the app bar overflow menu).
- Tapping it shows a confirmation dialog before deleting all entries.
- After confirmation, all entries are removed from storage and the screen shows the empty state.
- The action cannot be undone; the confirmation dialog makes this clear.

---

### US-45: Export shows per-item progress during large exports

**Beta: S · 2 SP**

> As a user exporting a large collection or wishlist to Discogs,  
> I want to see which item is currently being exported and how many remain,  
> so that I know the export is progressing and roughly how long it will take.

**Acceptance criteria:**
- The exporting screen shows a progress indicator: "Exporting item N of M…" (or equivalent).
- The currently-exporting item's title or artist is shown.
- Progress updates in real time as each item completes.
- The final "Export complete" summary screen is unchanged.
- Applies to both collection and wishlist Discogs exports.

---

### US-46: Export success screen has a "Share Again" option

**Beta: S · 1 SP**

> As a user who accidentally dismissed the share sheet before saving the CSV,  
> I want a "Share Again" button on the export success screen,  
> so that I can re-open the share sheet for the same file without re-running the export.

**Acceptance criteria:**
- The CSV export success screen shows a "Share Again" button alongside the "Done" button.
- Tapping "Share Again" re-opens the share sheet with the same temp file.
- If the temp file has been cleaned up, the button is hidden or shows a message asking the user to export again.
- Applies to both collection and wishlist CSV exports.

---

### US-47: Temp CSV export files are cleaned up automatically

**Beta: S · 2 SP**

> As a user who exports CSV files regularly,  
> I want old temp export files to be deleted automatically,  
> so that they do not accumulate and waste device storage.

**Acceptance criteria:**
- Temp CSV files older than 7 days are deleted from the temp directory on app launch.
- The cleanup runs silently with no notification to the user.
- The current export session's temp file is not deleted until at least 7 days have elapsed.
- If the Share Again flow (see US-46) is implemented, the temp file is kept until at least one sharing attempt has completed.

---

### US-48: Import/export history is paginated

**Beta: S · 3 SP**

> As a user with a long history of imports and exports,  
> I want to browse beyond the 20 most recent jobs,  
> so that I can refer back to older operations.

**Acceptance criteria:**
- The Import/Export History screen initially shows the 20 most recent jobs.
- A "Load more" button or infinite scroll loads additional pages of 20 jobs.
- A loading indicator is shown while the next page is fetching.
- The total job count is shown (e.g., "Showing 20 of 47 jobs").

---

### US-49: Import/export history allows deleting individual entries

**Beta: S · 2 SP**

> As a user who wants to remove a specific import or export record from history,  
> I want to delete individual history entries,  
> so that my history stays tidy without clearing everything.

**Acceptance criteria:**
- Each history entry has a delete option (e.g., swipe-to-dismiss or long-press menu).
- A confirmation step is shown before deleting (inline undo snackbar or dialog).
- Deleting a job record also deletes its associated row results from storage.
- The history list updates immediately after deletion with no full reload.

---

### US-50: Import/export history status chips are visually distinct

**Beta: S · 1 SP**

> As a user reviewing import/export history,  
> I want the "completed with errors" status chip to look clearly different from "completed",  
> so that I can quickly spot jobs that had problems.

**Acceptance criteria:**
- The `completedWithErrors` chip uses a colour distinct from the `completed` chip on all Material 3 colour themes.
- The `failed` and `cancelled` chips use appropriately warning/error colours.
- The distinction is visible in both light and dark mode.
- No change to the chip text labels.

---

### US-51: In-flight search requests are cancelled when the query changes

**Beta: S · 3 SP**

> As a user who types quickly in the search box,  
> I want a stale slow API response from an earlier query to be discarded immediately when a new query fires,  
> so that the results always match the latest search term and the network is not wasted.

**Acceptance criteria:**
- When a new debounced search query fires while a previous request is still in-flight, the previous request is cancelled (not merely ignored on arrival).
- Cancelled requests do not trigger state changes or error snackbars.
- The same behaviour applies to the barcode search screen.
- No regression on normal search flows.

---

### US-52: Recent search results are cached locally

**Beta: S · 5 SP**

> As a user who searches for the same release multiple times,  
> I want recent search results to be available instantly without a network call,  
> so that browsing feels faster and works in areas with poor connectivity.

**Acceptance criteria:**
- The app caches the most recent N search query results (N configurable; default: 20 queries).
- A cached result is returned immediately while a background refresh runs; the list updates silently if fresher results arrive.
- Cached results are keyed by query string (case-insensitive, trimmed).
- Cache entries expire after a configurable TTL (default: 24 hours).
- When the device has no connection and a cached result exists, it is shown with a "Showing saved results" indicator.
- Barcode search results are cached separately using the barcode value as the key.
