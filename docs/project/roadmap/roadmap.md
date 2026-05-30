# Crate Roadmap

## Phase 0: Product and Technical Setup

Goal:

Create a stable project foundation.

Deliverables:

- Confirm MVP scope
- Set up Flutter project
- Add app architecture
- Add routing
- Add theme system
- Add light, dark, and system theme mode
- Add environment config
- Add secure storage abstraction
- Add API client base
- Define OAuth architecture
- Set up Cloudflare Worker project
- Add PR workflow and CI

Exit criteria:

- App runs on iOS and Android
- Basic navigation works
- Theme switching works
- API client has test coverage
- No secrets are stored in the app
- CI runs format, analyze, test, and Android debug build

## Phase 1: Discogs OAuth Login

Goal:

Allow users to connect their Discogs account.

Deliverables:

- Welcome screen
- Connect Discogs button
- OAuth request flow
- Callback handling
- Token or session storage
- Logged-in account state
- Logout
- Error handling

Exit criteria:

- User can connect Discogs
- User stays logged in after restart where appropriate
- User can log out
- Failed login shows a clear message

## Phase 2: Collection MVP

Goal:

Make collection management the core experience.

Deliverables:

- Collection overview
- Collection list
- Pagination
- Pull to refresh
- Collection item cards
- Empty state
- Error state
- Loading skeleton
- Release detail navigation

Exit criteria:

- User can view their collection
- User can browse collection pages
- User can open release details
- API rate limit errors are handled

## Phase 3: Collection Search and Filters

Goal:

Help users find records in their collection quickly.

Deliverables:

- Search inside collection
- Filter bottom sheet
- Sort options
- Active filter chips
- Reset filters
- Tablet-friendly filter layout

Exit criteria:

- User can search collection
- User can filter by format, artist, label, year, and folder
- User can sort results
- UX works on phone and tablet

## Phase 4: Release Detail

Goal:

Create a premium release detail experience.

Deliverables:

- Cover artwork section
- Metadata section
- Tracklist
- Notes
- Community data
- Collection status
- Wantlist status
- Open in Discogs
- Share action

Exit criteria:

- Release detail is useful and readable
- Long tracklists remain easy to scan
- Missing data does not break the layout

## Phase 5: Add and Remove Collection Items

Goal:

Allow collection actions from the app.

Deliverables:

- Add release to collection
- Remove release from collection
- Folder support where possible
- Success feedback
- Error feedback
- Optimistic UI only where safe

Exit criteria:

- User can add a release
- User can remove a release
- App handles API failures safely

## Phase 6: Discogs Search

Goal:

Allow users to find releases outside their collection.

Deliverables:

- Search Discogs releases
- Result cards
- Search filters
- Release detail from search
- Add to collection from search result

Exit criteria:

- User can search Discogs
- User can open a result
- User can add a result to collection

## Phase 7: Barcode Scanner

Goal:

Make it easy to add physical records.

Deliverables:

- Barcode scanner screen
- Camera permission flow
- Barcode search result
- Match selection
- Add to collection
- Manual fallback

Exit criteria:

- User can scan a barcode
- User can select the correct release
- User can add it to collection

## Phase 8: Wantlist Basics

Goal:

Add simple wantlist support.

Deliverables:

- Wantlist overview
- Wantlist search
- Add to wantlist
- Remove from wantlist
- Wantlist status on release detail

Exit criteria:

- User can view wantlist
- User can add and remove items
- Wantlist status is clear

## Phase 9: Polish and Beta

Goal:

Prepare the app for real users.

Deliverables:

- App icon
- Splash screen
- Error copy review
- Accessibility pass
- Performance pass
- Tablet layout pass
- Crash reporting decision
- Beta test checklist

Exit criteria:

- App feels stable
- Core flows work
- Test users can use the app without guidance
