---
name: discogs-api
description: Implement or review Discogs API integration for search, release details, user token validation, pagination, rate limits, and safe error handling.
argument-hint: '[API task]'
---

# Discogs API Skill

Use this skill for Discogs API work.

## Procedure

1. Keep API code inside `infrastructure/discogs`.
2. Use typed DTOs for Discogs responses.
3. Map DTOs to domain models.
4. Add a clear User-Agent header.
5. Handle pagination.
6. Handle empty results.
7. Handle rate limits.
8. Handle invalid tokens.
9. Never log tokens.
10. Never expose tokens in error messages.

## Token mode

For MVP, support Discogs current token mode.

The user pastes a current token from Discogs developer settings.

The app must:

- Validate the token.
- Store it securely.
- Mask it in UI.
- Allow removing it.

## Error rules

Convert technical errors into friendly app errors.

Examples:

- Invalid token
- No internet connection
- Discogs unavailable
- Rate limit reached
- Empty search result

## Done criteria

- API logic is not inside widgets.
- Token is not logged.
- API responses are typed.
- Error handling is tested.
