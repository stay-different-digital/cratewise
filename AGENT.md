# AGENT.md

## Purpose

This file gives the coding agent enough context to work on the Crate project.

Crate is a Flutter mobile app for iPhone, iPad, Android phones, and Android tablets.

The app is an alternative mobile experience for Discogs.

The first product focus is collection management.

The agent must use the project documentation in `docs/project/` before making implementation choices.

## Project Name

Crate

## Product Vision

Crate helps music collectors manage their Discogs collection in a modern, fast, visual, and collector-friendly mobile app.

The app should feel:

- Premium
- Minimal
- Warm
- Fast
- Visual
- Easy to scan
- Collector-focused

## Primary Goal

Build a production-ready Flutter app that connects to Discogs and helps users manage their collection.

The MVP must focus on:

- Discogs OAuth login
- Viewing the user collection
- Searching inside the collection
- Filtering and sorting the collection
- Viewing release details
- Adding and removing collection items where supported
- Discogs search
- Barcode scanner
- Basic wantlist support
- Light mode, dark mode, and system theme mode
- Phone and tablet layouts

## Important API Rule

Use **Discogs API v2.0 only**.

Do not use Discogs API v1.0.

Do not scrape Discogs pages.

Use real Discogs API calls from the start.

Mock data is only allowed for:

- Tests
- Local isolated UI previews
- Temporary fallback states when clearly marked

## Required Documentation Reading Order

Before starting meaningful work, read these files in this order:

1. `docs/project/prompts/crate_project_prompt.md`
2. `docs/project/prompts/flutter_folder_setup_prompt.md`
3. `docs/project/roadmap/roadmap.md`
4. `docs/project/backlog/feature_backlog.md`
5. `docs/project/architecture/oauth_architecture.md`
6. `docs/project/architecture/api_architecture.md`
7. `docs/project/decisions/`
8. `docs/project/working-agreement.md`
9. `docs/project/definition-of-ready.md`
10. `docs/project/definition-of-done.md`
11. `docs/project/testing-strategy.md`
12. `docs/project/changelog/changelog.md`

When working on a specific feature, also check related ADRs before coding.

## Documentation Folder Structure

Expected documentation structure:

```text
docs/
  project/
    prompts/
      crate_project_prompt.md
      flutter_folder_setup_prompt.md
      agent/
    roadmap/
      roadmap.md
    backlog/
      feature_backlog.md
    changelog/
      changelog.md
    architecture/
      oauth_architecture.md
      api_architecture.md
    decisions/
    working-agreement.md
    definition-of-ready.md
    definition-of-done.md
    branching-strategy.md
    testing-strategy.md
    release-checklist.md
    environment-setup.md
```

## Core Architecture Decisions

The agent must follow these decisions:

- Use Flutter and Dart.
- Use feature-based clean architecture.
- Use Riverpod for state management.
- Use go_router for navigation.
- Use dio for HTTP calls.
- Use flutter_secure_storage for secure local token storage.
- Use freezed and json_serializable for typed models.
- Use mobile_scanner for barcode scanning.
- Use flutter_test and integration_test for testing.
- Use Cloudflare Worker as Backend-for-Frontend for Discogs OAuth and signed API calls.
- Do not store the Discogs consumer secret in the Flutter app.
- Do not build offline collection cache in the MVP.
- Support light, dark, and system theme modes.

## OAuth Architecture

Discogs uses OAuth 1.0a.

The Flutter app must not store the Discogs consumer secret.

Use this setup:

- Flutter app handles the mobile user flow.
- Cloudflare Worker handles OAuth signing.
- Cloudflare Worker stores Discogs secrets.
- Flutter stores only safe session data and user tokens where appropriate.
- Use secure storage for sensitive local values.
- Never commit secrets.

The OAuth flow must support:

- Start login
- Open Discogs authorization
- Handle callback
- Exchange verifier
- Store login state
- Logout
- Clear auth state
- Show clear error messages

## API Architecture

All Discogs API access must follow these rules:

- Use Discogs API v2.0 only.
- Add a clear User-Agent.
- Respect Discogs rate limits.
- Handle rate limits with user-friendly errors.
- Handle unauthorized responses.
- Handle not found responses.
- Handle network errors.
- Handle unexpected API responses.
- Keep API code outside widgets.
- Use repositories and use cases.
- Keep UI state separate from API models where useful.

## MVP Scope

### In Scope

- Discogs OAuth login
- Collection overview
- Collection list
- Collection search
- Collection filters
- Collection sorting
- Release detail
- Add to collection
- Remove from collection
- Discogs search
- Barcode scanner
- Basic wantlist
- Settings
- Light mode
- Dark mode
- System theme mode
- Phone layout
- Tablet layout

### Out of Scope

- Offline collection cache
- Push notifications
- Price drop alerts
- Advanced marketplace tracking
- Social features
- Public collector profiles
- AI recommendations
- Multi-account support
- Seller inventory management
- Payment flows
- Checkout flows
- Web app
- Desktop app

## Design Direction

Use the Airbnb-inspired Figma design direction from ADR 0002.

Figma references:

- Airbnb Design UI Kit 2025:
  https://www.figma.com/design/mCcC9F6VOSVqCwc4zQ9DcO/Airbnb-Design---UI-KIT---Summer-Release-2025--Community-?node-id=52-747&t=2KME2cjNEVzEPIJL-1

- Airbnb Mobile App:
  https://www.figma.com/design/CRU00LNZW4efVeSzDzq8Ba/Airbnb-Mobile-App--Community-?node-id=3-35&p=f&t=djtfdWoMSH4MGFdK-0

- Airbnb UI Kit:
  https://www.figma.com/design/DkllCBzHimFoexZ2OTw3t9/Airbnb-UI-Kit--Community-?node-id=0-1&p=f&t=sSWNDPmGUOzFuUTF-0

Use these design patterns:

- Large visual cards
- Strong album artwork
- Rounded corners
- Clean spacing
- Clear typography
- Simple navigation
- Search-first screens
- Bottom sheets for filters and actions
- Friendly empty states
- Loading skeletons
- Smooth transitions
- Responsive tablet layouts

Do not copy Airbnb branding, logos, text, protected assets, or exact screens.

Crate must have its own visual identity.

## Expected Flutter Folder Structure

Use the folder structure from:

```text
docs/project/prompts/flutter_folder_setup_prompt.md
```

## Coding Rules

Always:

- Use clean, readable Dart.
- Keep widgets small.
- Keep business logic out of widgets.
- Use Riverpod providers for state and dependencies.
- Use typed models.
- Use repositories for data access.
- Use use cases for business logic when useful.
- Handle loading, empty, error, and success states.
- Add tests for important logic.
- Update documentation when decisions change.
- Update the changelog after meaningful changes.

Never:

- Hardcode secrets.
- Store the Discogs consumer secret in Flutter.
- Use Discogs API v1.0.
- Scrape Discogs.
- Put API calls directly in widgets.
- Ignore rate limits.
- Add offline cache in the MVP.
- Add large features outside MVP without approval.
- Copy Airbnb or Discogs branding.

## Pull Request Workflow

For every meaningful code or documentation change:

1. Create or select an issue.
2. Create a branch from `main`.
3. Implement the smallest useful change.
4. Add or update tests.
5. Run formatting, analysis, and tests.
6. Update docs when needed.
7. Update changelog when needed.
8. Open a pull request.
9. Review the pull request.
10. Merge only after checks pass.

Do not work directly on `main`.

## Response Format for Implementation Tasks

When reporting work, use this format:

```markdown
## Summary

- What changed.

## Files changed

- File path and short explanation.

## Tests

- What was tested.
- What still needs testing.

## Documentation

- Docs updated.
- Changelog updated.

## Notes

- Risks.
- Follow-up actions.
```

## Current Known Product Choices

- App name: Crate
- Platform: Flutter
- Target devices: iPhone, iPad, Android phone, Android tablet
- First focus: collection management
- API: Discogs API v2.0
- Login: Discogs OAuth
- Backend helper: Cloudflare Worker
- Design direction: Airbnb-inspired Figma references
- MVP cache: no offline collection cache
- Theme: light, dark, and system mode
- First build: real Discogs API calls

## Conflict Resolution

When project documentation and code conflict, follow this order:

1. ADRs in `docs/project/decisions/`
2. Architecture docs in `docs/project/architecture/`
3. Project prompt in `docs/project/prompts/`
4. Roadmap in `docs/project/roadmap/`
5. Backlog in `docs/project/backlog/`
6. Existing code

If the conflict is important, create or update an ADR.
