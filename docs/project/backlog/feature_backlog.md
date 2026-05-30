# Crate Feature Backlog

## Epic 1: App Foundation

### Story 1.1: Create Flutter project foundation

As a developer,
I want a clean Flutter project setup,
so that the app is easy to build and maintain.

Acceptance criteria:

- Flutter project is created.
- Riverpod is configured.
- go_router is configured.
- Theme setup exists.
- Light, dark, and system theme mode exist.
- Basic folder structure exists.
- CI runs on pull requests.

Priority: Must have

### Story 1.2: Add shared UI components

As a developer,
I want reusable UI components,
so that the app stays consistent.

Acceptance criteria:

- App button exists.
- Release card exists.
- Empty state exists.
- Error state exists.
- Loading state exists.
- Filter chip exists.

Priority: Must have

## Epic 2: Authentication

### Story 2.1: Connect Discogs account

As a collector,
I want to connect my Discogs account,
so that I can access my collection.

Acceptance criteria:

- User can start Discogs OAuth login.
- User can approve access.
- App handles callback.
- App stores safe session values securely.
- User sees connected state.
- Discogs consumer secret is not stored in Flutter.

Priority: Must have

### Story 2.2: Logout

As a collector,
I want to disconnect my account,
so that I can remove access from the app.

Acceptance criteria:

- Logout button exists in settings.
- Secure tokens or session values are removed.
- User returns to logged-out state.

Priority: Must have

## Epic 3: Collection Management

### Story 3.1: View collection

As a collector,
I want to view my Discogs collection,
so that I can browse my records.

Acceptance criteria:

- Collection list loads from Discogs API v2.0.
- Items show cover, artist, title, year, format.
- Pagination works.
- Pull to refresh works.
- Loading, empty, and error states exist.

Priority: Must have

### Story 3.2: Search collection

As a collector,
I want to search my collection,
so that I can quickly find a record.

Acceptance criteria:

- Search input exists.
- Search filters collection results.
- No results state exists.
- Search can be cleared.

Priority: Must have

### Story 3.3: Filter collection

As a collector,
I want to filter my collection,
so that I can browse by format, label, year, or folder.

Acceptance criteria:

- Filter bottom sheet exists.
- Active filters are visible.
- User can reset filters.
- Filters work with search.

Priority: Should have

### Story 3.4: Sort collection

As a collector,
I want to sort my collection,
so that I can browse it in the way I prefer.

Acceptance criteria:

- Sort options exist.
- User can sort by artist.
- User can sort by title.
- User can sort by year.
- User can sort by date added.

Priority: Should have

## Epic 4: Release Detail

### Story 4.1: View release detail

As a collector,
I want to open a release,
so that I can view all important release data.

Acceptance criteria:

- Detail page shows cover image.
- Detail page shows artist and title.
- Detail page shows label, year, format, country.
- Detail page shows tracklist.
- Detail page handles missing fields.

Priority: Must have

### Story 4.2: Show collection status

As a collector,
I want to see if I own a release,
so that I know whether it is already in my collection.

Acceptance criteria:

- Detail page shows owned status.
- Detail page shows folder if available.
- Status updates after add or remove action.

Priority: Must have

## Epic 5: Discogs Search

### Story 5.1: Search Discogs releases

As a collector,
I want to search Discogs,
so that I can find releases outside my collection.

Acceptance criteria:

- Search field exists.
- Results load from Discogs API v2.0.
- Result cards show key metadata.
- User can open result detail.

Priority: Should have

### Story 5.2: Add search result to collection

As a collector,
I want to add a searched release to my collection,
so that I can manage new records.

Acceptance criteria:

- Add to collection action exists.
- Success message is shown.
- Error message is shown on failure.
- Collection status updates.

Priority: Should have

## Epic 6: Barcode Scanner

### Story 6.1: Scan barcode

As a collector,
I want to scan a barcode,
so that I can quickly find a release.

Acceptance criteria:

- Camera permission is requested.
- Scanner opens.
- Barcode is detected.
- Matching releases are shown.
- Manual fallback exists.

Priority: Should have

## Epic 7: Wantlist

### Story 7.1: View wantlist

As a collector,
I want to view my wantlist,
so that I can track records I want.

Acceptance criteria:

- Wantlist screen exists.
- Wantlist items load from Discogs API v2.0.
- Empty and error states exist.

Priority: Could have

### Story 7.2: Add and remove wantlist item

As a collector,
I want to add or remove a release from my wantlist,
so that I can manage records I want.

Acceptance criteria:

- Add to wantlist action exists.
- Remove from wantlist action exists.
- Status updates after action.

Priority: Could have

## Epic 8: Settings

### Story 8.1: Manage theme

As a user,
I want to choose light, dark, or system theme,
so that the app matches my preference.

Acceptance criteria:

- Theme setting exists.
- User can select light mode.
- User can select dark mode.
- User can select system mode.
- Choice is saved.

Priority: Must have

### Story 8.2: View app and API status

As a user,
I want to see basic app status,
so that I know whether my account and API connection work.

Acceptance criteria:

- Settings show connected account.
- Settings show app version.
- Settings show API status where possible.

Priority: Should have
