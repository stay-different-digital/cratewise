# Copilot Instructions for Cratewise

## Project summary

Cratewise is a Flutter app for Android and  iOS/iPadOS.

It is a modern vinyl collection app that uses the Discogs API for metadata.

## Always follow these rules

- Use clean architecture.
- Keep UI code separate from business logic.
- Keep API code separate from widgets.
- Keep local database code separate from domain models.
- Write small, focused changes.
- Prefer readable code over clever code.
- Use clear names.
- Add tests for core behavior.
- Run `dart format` after code changes.
- Run `flutter test` when tests are available.

## Architecture

Use these layers:

- `presentation`
- `application`
- `domain`
- `infrastructure`
- `shared`

Preferred structure:

```text
lib/
  app/
  presentation/
  application/
  domain/
  infrastructure/
  shared/
test/
```

## Flutter rules

- Use Flutter widgets that work on Android and iOS/iPadOS.
- Use responsive layouts.
- Use Material 3 as base.
- Support light mode and dark mode.
- Avoid platform-specific logic unless needed.
- Keep widgets small and reusable.

## Discogs API rules

- Add a clear User-Agent header.
- Handle pagination.
- Handle rate limits.
- Debounce search input.
- Cache common API responses.
- Never expose tokens in logs or errors.

## Token and security rules

- Store Discogs current token with secure storage.
- Never hardcode tokens.
- Never commit secrets.
- Never print tokens.
- Mask tokens in the UI.
- Add a remove-token flow.

## Testing rules

Add tests for:

- API client parsing
- Token validation
- Search result mapping
- Release detail mapping
- Collection repository behavior
- Wishlist repository behavior
- CSV import and export

## Git and commit rules

- Commit every completed change automatically. Do not leave finished work uncommitted.
- Commit only after `dart format`, `flutter analyze`, and `flutter test` pass.
- Use this commit message format:
  - User story work: `Resolved: US-XX: <user story title>`
  - Bug fixes: `Resolved <short description>`
  - Docs/config changes: short imperative summary
- One logical change per commit, including its tests and doc updates.
- Never push unless the user explicitly asks.
- Never commit secrets, tokens, or `.env` files.

## Documentation rules

Update docs when you change:

- Architecture
- Authentication
- Data model
- API behavior
- Sync behavior
- Product scope
- Design system

## UX rules

- Keep the app clean and simple.
- Use large cover images where useful.
- Use clear empty states.
- Use friendly error messages.
- Use strong search and filtering.
- Follow the Airbnb-inspired design direction from `docs/design/DESIGN_SYSTEM.md`.
- Do not copy Airbnb branding.

## Output style for Copilot responses

When creating plans, use this format:

- Goal
- Scope
- Files to change
- Implementation steps
- Tests
- Risks
- Done criteria
