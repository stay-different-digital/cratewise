# Beta User Stories

Derived from all XL and L limitations recorded across Phases 1–6.  
**Beta importance:** XL = must fix · L = should fix  
**Story points** are estimates for a single developer.

---

## XL — Must fix before beta

---

### US-01: HTTP request timeout

**Beta: XL · 2 SP**

> As a user with a slow or unstable connection,  
> I want Discogs requests to time out after a reasonable period,  
> so that I am not left staring at an infinite loading spinner with no way out.

**Acceptance criteria:**
- All outgoing HTTP calls to the Discogs API use a configured timeout (e.g. 15 seconds).
- When the timeout elapses the screen transitions to the same error state as any other network failure.
- The error state offers a retry action.
- No loading state can remain active indefinitely.

**Affected screens:** Token validation, Search, Release Detail, Collection import/export, Wishlist import/export.

---

### US-02: iOS token save reliability (Keychain bug)

**Beta: XL · 3 SP**

> As an iPhone or iPad user,  
> I want saving my Discogs token to always succeed,  
> so that I don't have to re-enter my token every time I open the app.

**Acceptance criteria:**
- `DiscogsTokenStorage.saveCredentials` surfaces any Keychain error to the caller rather than swallowing it silently.
- When saving fails, the Settings screen shows an error message explaining the problem and does not show a success state.
- The error message does not include the token value.
- Confirm the exact Keychain error code from a device reproduction, then apply the documented fix.
- Add a widget test or integration test that covers the save-failure path.

---

## L — Should fix before beta

---

### US-03: Search results pagination

**Beta: L · 5 SP**

> As a user searching for a release,  
> I want to browse beyond the first 20 results,  
> so that I can find the correct pressing even when the initial results don't include it.

**Acceptance criteria:**
- The search results list loads additional pages as the user scrolls toward the end.
- A loading indicator is shown at the bottom of the list while the next page is being fetched.
- If Discogs returns a rate-limit error (429) during pagination, the list shows an inline retry option rather than replacing the current results.
- Total result count is shown (e.g. "1–20 of 340") when available from the API response.
- Applies to both text search and barcode lookup results.

---

### US-04: Pull-to-refresh on key screens

**Beta: L · 3 SP**

> As a user who encounters an error or stale data,  
> I want to pull down to refresh the screen,  
> so that I don't have to navigate back and re-open the screen to retry.

**Acceptance criteria:**
- Pull-to-refresh is available on: Release Detail, Collection list, Collection Detail, Wishlist list, Wishlist Detail.
- Pulling triggers the same data-fetch as the initial screen load.
- A rate-limited or network error during refresh shows the existing error state without discarding already-loaded content.
- Works on Android, iPhone, and iPad.

---

### US-05: Release detail app bar shows album title

**Beta: L · 1 SP**

> As a user viewing a release,  
> I want the app bar to display the album title and artist,  
> so that I know which release I am looking at when I scroll down past the cover image.

**Acceptance criteria:**
- Once release data has loaded, the app bar title shows the release title (and optionally the primary artist).
- While loading, the app bar shows a placeholder or "Release Detail".
- On error, the app bar shows a placeholder or "Release Detail".
- Title is truncated with ellipsis if it exceeds the available width.

---

### US-06: Release detail shows artist and title from search context

**Beta: L · 1 SP**

> As a user tapping a search result,  
> I want the release detail screen to immediately show the artist and title,  
> so that I don't see a blank or ID-only screen while the API call is in flight.

**Acceptance criteria:**
- Artist and title passed from the search result card are displayed in the detail screen before the API response arrives.
- The skeleton/loading state includes artist and title from the search context.
- Once the full API response loads, the detail screen updates with authoritative data (ANV, format details, etc.).

---

### US-07: Cover images use thumbnails

**Beta: L · 2 SP**

> As a user on a mobile connection,  
> I want release cover images to load quickly using thumbnail-sized images,  
> so that browsing the search results and collection list doesn't consume excessive data or feel slow.

**Acceptance criteria:**
- Search result cards and collection/wishlist list items use `uri150` (thumbnail) from the Discogs API response.
- The Release Detail screen may still display the full-resolution `uri` for the hero cover image.
- Thumbnail URLs are cached via the existing `ThumbnailCacheService` where applicable.

---

### US-08: "Already in collection" indicator on release detail

**Beta: L · 3 SP**

> As a user viewing a release I have already added,  
> I want the "Add to Collection" button to reflect that the item is already in my collection,  
> so that I don't accidentally add duplicates.

**Acceptance criteria:**
- When the Release Detail screen loads, it checks whether the release ID already exists in the local collection.
- If found, the button changes to "In Collection" (disabled or navigates to the collection item) rather than "Add to Collection".
- The check runs against local storage — no network call required.
- Adding an item and then navigating back to the same release detail updates the button state correctly.

---

### US-09: Collection list search and filter

**Beta: L · 5 SP**

> As a user with a large vinyl collection,  
> I want to search and filter my collection list,  
> so that I can quickly find a specific record without scrolling through everything.

**Acceptance criteria:**
- The search field in the Collection list is functional and filters items by artist and/or title as the user types.
- Filtering is local (no network call) and operates on the items already loaded.
- Debounce is applied to avoid filtering on every keystroke.
- When the search field is cleared, the full list is restored.
- An empty-state message is shown when the filter matches nothing.
- Works on Android, iPhone, and iPad (including the grid layout on iPad).

---

### US-10: Collection list live-refreshes after adding items

**Beta: L · 3 SP**

> As a user who adds a release to my collection from the Release Detail screen,  
> I want the collection list to show the new item when I navigate back,  
> so that I have immediate confirmation the item was saved.

**Acceptance criteria:**
- Navigating back to the Collection list after adding an item from Release Detail shows the newly added item without requiring a manual refresh.
- The list re-queries local storage on each entry (or uses a reactive stream) rather than caching a stale snapshot.
- No full-screen reload flicker; the list updates in place or animates the new row in.

---

### US-11: Wishlist search and filter

**Beta: L · 5 SP**

> As a user with a long wishlist,  
> I want to search and filter my wishlist,  
> so that I can quickly find a specific record I'm looking to buy.

**Acceptance criteria:**
- The Wishlist list screen includes a search/filter field that filters by artist and/or title as the user types.
- Filtering is local (no network call).
- Debounce is applied.
- When the search field is cleared, the full list is restored.
- An empty-state message is shown when the filter matches nothing.
- Works on Android, iPhone, and iPad.

---

### US-12: "Already in wishlist" indicator on release detail

**Beta: L · 3 SP**

> As a user viewing a release I have already wishlisted,  
> I want the "Add to Wishlist" button to reflect that,  
> so that I don't create duplicate wishlist entries.

**Acceptance criteria:**
- When the Release Detail screen loads, it checks whether the release ID already exists in the local wishlist.
- If found, the button changes to "In Wishlist" (disabled or navigates to the wishlist item) rather than "Add to Wishlist".
- The check runs against local storage — no network call required.
- Adding a wishlist item and then navigating back to the same release detail updates the button state correctly.
