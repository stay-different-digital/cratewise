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

- Base URL (https://api.discogs.com)
- API 2.0
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

## Search parameters (verified)

`GET /database/search` accepts these parameters although the public API docs
don't list them. Verified 2026-11-16 and 2026-11-17 with real requests (`label=Blue Note`,
`type=release`):

| Parameter | Effect | Used by |
|---|---|---|
| `sort=year&sort_order=desc\|asc` | By release year; later pages continue the same order (used by US-133 until US-162) | — |
| `sort=date_added&sort_order=desc` | Most recently added to Discogs first (highest release IDs). Verified 2026-11-17 | US-162 |
| `sort=date_added&sort_order=asc` | Earliest added to Discogs first (lowest release IDs) | US-162 |
| `format=Vinyl` | Only releases with a vinyl format: 13,790 of 32,777 results, no `File` releases | US-142 |

`format=Vinyl` matches a release when any of its formats is vinyl: all 14
mixed releases (LP + CD box sets) on the first page of `q=super deluxe edition`
were still there with the filter on.

Without `sort` Discogs orders by relevance. Combined with a field filter
(`label`, `artist`, `release_title`) the parameters still work. Search results
are public data: the endpoint also answers without a token, but the app always
sends one.

If Discogs ever drops these parameters the results come back in relevance
order or unfiltered instead of failing, so check them again when search
results look wrong.

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

`sort=added` is silently ignored (relevance order); the parameter must be `date_added`.
