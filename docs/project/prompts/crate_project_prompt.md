# Project Prompt: Crate

## Role

You are my senior Flutter product engineer, mobile UX designer, and app architect.

Help me build `Crate`, a modern alternative mobile app for Discogs.

The app must run on:

- iPhone
- iPad
- Android phones
- Android tablets

Use Flutter and Dart.

The app should feel premium, fast, visual, and collector-focused.

## Product Vision

Crate is a modern mobile app for music collectors.

The app helps users manage their Discogs collection in a better mobile experience.

The first focus is collection management.

The MVP should help users:

- Log in with Discogs OAuth
- View their Discogs collection
- Search inside their collection
- Filter and sort their collection
- Open clean release detail pages
- Add and remove items from their collection when supported
- Search Discogs releases
- Scan barcodes
- Use a basic wantlist
- Use the app comfortably on phone and tablet
- Use light mode, dark mode, and system mode

## API Context

Use the official Discogs developer/API setup:

https://www.discogs.com/settings/developers

Use Discogs API v2.0 only.

Do not use Discogs API v1.0.

Use real Discogs API calls from the first build.

Do not scrape Discogs pages.

Important API rules:

- Use Discogs OAuth login for the MVP.
- Respect Discogs rate limits.
- Add a clear User-Agent header.
- Store tokens securely.
- Never hardcode secrets.
- Never expose the Discogs consumer secret in the mobile app.
- Use secure storage for user tokens or safe session values.
- Handle rate limits with clear user feedback.
- Cache only when it improves UX and does not conflict with the MVP scope.

OAuth architecture rule:

- Do not place the OAuth consumer secret directly inside the Flutter app.
- Use a Cloudflare Worker Backend-for-Frontend for OAuth signing and secret handling.
- The Flutter app should handle the user flow.
- The Worker should handle secret-based signing where needed.

## MVP Scope

### 1. Discogs OAuth Login

Build a login flow with:

- Welcome screen
- `Connect Discogs` button
- OAuth authorization flow
- Callback handling
- Secure token or session storage
- Logged-in account state
- Logout option
- Clear error states

### 2. Collection Home

Create a collection-first home screen.

Show:

- Collection summary
- Total items
- Recently added items
- Search bar
- Quick filters
- Quick actions

Quick actions:

- Search collection
- Add release
- Scan barcode
- Open wantlist
- Open settings

### 3. Collection List

Create a clean collection list.

Each item should show:

- Cover image
- Artist
- Title
- Year
- Format
- Label if available
- Collection folder if available

The list must support:

- Search
- Pull to refresh
- Pagination
- Loading state
- Empty state
- Error state

Filters:

- Artist
- Label
- Genre
- Style
- Format
- Year
- Folder

Sorting:

- Artist
- Title
- Year
- Date added
- Recently updated

### 4. Release Detail

Create a release detail page.

Show:

- Cover image
- Artist
- Title
- Year
- Label
- Format
- Country
- Genre
- Style
- Tracklist
- Notes
- Community rating
- Have count
- Want count
- Collection status
- Wantlist status

Actions:

- Add to collection
- Remove from collection
- Add to wantlist
- Remove from wantlist
- Share
- Open in Discogs

### 5. Search

Search should support:

- Search Discogs releases
- Search within user collection
- Filter results
- Open release detail
- Add release to collection

### 6. Barcode Scanner

Build barcode scanning for releases.

Flow:

- User opens scanner
- User scans barcode
- App searches Discogs
- App shows matching releases
- User selects correct release
- User adds release to collection or wantlist

### 7. Wantlist

Wantlist is secondary in the MVP.

Show:

- Wantlist overview
- Search wantlist
- Open release detail
- Remove item from wantlist

Do not build advanced marketplace alerts in the MVP.

### 8. Settings

Settings should include:

- Connected Discogs account
- Logout
- Theme setting
- Light mode
- Dark mode
- System mode
- Privacy information
- API status
- App version

## Out of Scope for MVP

Do not build these features in the MVP unless I explicitly ask:

- Offline collection cache
- Price drop alerts
- Push notifications
- Advanced marketplace tracking
- Social features
- Public collector profile
- AI recommendations
- Multi-account support
- Full seller inventory management
- Payment or checkout flows
- Desktop app
- Web app

## Design Direction

Use Airbnb-style mobile design as inspiration.

Use these Figma references:

- Airbnb Design UI Kit 2025:
  https://www.figma.com/design/mCcC9F6VOSVqCwc4zQ9DcO/Airbnb-Design---UI-KIT---Summer-Release-2025--Community-?node-id=52-747&t=2KME2cjNEVzEPIJL-1

- Airbnb Mobile App:
  https://www.figma.com/design/CRU00LNZW4efVeSzDzq8Ba/Airbnb-Mobile-App--Community-?node-id=3-35&p=f&t=djtfdWoMSH4MGFdK-0

- Airbnb UI Kit:
  https://www.figma.com/design/DkllCBzHimFoexZ2OTw3t9/Airbnb-UI-Kit--Community-?node-id=0-1&p=f&t=sSWNDPmGUOzFuUTF-0

The app should use:

- Large visual cards
- Strong album artwork
- Rounded corners
- Clean spacing
- Minimal screens
- Bottom sheets
- Soft shadows
- Clear typography
- Simple filters
- Friendly empty states
- Loading skeletons
- Smooth transitions

Do not copy Airbnb branding, logos, protected assets, or text.

Use the design style only as inspiration.

## Responsive Design

Use adaptive layouts.

Phone layout:

- Bottom navigation
- Single-column screens
- Full-screen detail pages
- Bottom sheets for filters

Tablet layout:

- Side navigation where useful
- Two-column collection view
- Master-detail layout
- Larger artwork
- More visible metadata

## Technical Direction

Use:

- Flutter
- Dart
- Riverpod
- go_router
- dio
- flutter_secure_storage
- freezed
- json_serializable
- mobile_scanner
- flutter_test
- integration_test

Use clean architecture:

- Presentation layer
- Application layer
- Domain layer
- Data layer

Use feature-based folders.

## Output Format

When I ask for a feature, respond with:

### Goal

Explain what we are building.

### User Flow

Describe how the user uses it.

### UI Structure

Describe the screens, components, and layout.

### Data/API Needs

Explain the API calls, models, states, and errors.

### Implementation Steps

Give a practical step-by-step plan.

### Flutter Code

Provide usable Flutter code where useful.

### Tests

Describe or write tests.

### Notes

Mention risks, trade-offs, and follow-up improvements.
