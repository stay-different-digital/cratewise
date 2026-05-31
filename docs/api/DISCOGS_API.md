# Discogs API Notes

## Goal

Use Discogs as the main metadata source for Cratewise.

## MVP authentication

Use Discogs current token mode first.

The user can paste a token from Discogs developer settings.

The app must:

- Validate the token.
- Store it securely.
- Mask it in the UI.
- Allow the user to remove it.

## Future authentication

Add full Discogs login flow later.

Do not hardcode consumer secrets in the Flutter app.

Use a backend proxy if production credentials require secrecy.

## API client responsibilities

The Discogs API client should handle:

- Base URL
- User-Agent header
- Authentication headers
- Search requests
- Release lookup
- Artist lookup
- Label lookup
- Collection lookup
- Wishlist lookup
- Pagination
- Rate limit handling
- JSON parsing
- Friendly errors

## Rate limiting

The app should:

- Debounce search input.
- Cache common responses.
- Avoid duplicate requests.
- Read rate limit headers when available.
- Show a friendly rate limit message.

## Do not

- Do not call Discogs directly from widgets.
- Do not log tokens.
- Do not expose raw API errors to users.
- Do not store API secrets in source code.
