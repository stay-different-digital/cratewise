# ADR-0011: Use typed Discogs errors and explicit rate-limit policy

## Status

Accepted

## Context

Discogs API calls can fail because of invalid tokens, network failures, service
errors, unexpected status codes, or rate limits. The app must show friendly
messages without exposing tokens or raw API details.

Cratewise also performs multi-request workflows such as import, export, retry
actions, and pending deletion sync. These workflows need consistent behaviour
when Discogs returns `429 Too Many Requests`.

## Decision

Map Discogs API failures to typed application errors.

`DiscogsApiClient` maps:

- `401` and `403` to `InvalidTokenError`.
- `429` to `RateLimitedError`.
- `5xx` responses to `DiscogsUnavailableError`.
- socket, timeout, and transport failures to `NetworkError`.
- other unexpected status codes to `UnexpectedApiError`.

Read `X-Discogs-Ratelimit-Remaining` when available and delay the next request
after the allowance reaches the configured threshold. Multi-page import and
per-item export workflows handle `RateLimitedError` with bounded retries and
fixed back-off delays.

## Consequences

Positive:

- UI code can show friendly, token-safe messages based on error type.
- Token revocation handling can clear stored credentials consistently.
- Search, detail, barcode, import, export, retry, and deletion flows share the
  same error vocabulary.
- Rate-limit behaviour is testable because delay functions are injectable.

Negative:

- The current rate-limit policy uses a fixed reset window rather than
  `Retry-After`.
- The client does not centrally retry every `429`; some workflows handle retry
  at the use-case level.
- Parallel requests still require care because rate-limit state is held in the
  API client instance.

## Follow-up

Consider a central Discogs request queue or rate limiter if background sync,
bulk operations, or parallel API usage grows. Prefer `Retry-After` or explicit
reset headers if Discogs exposes them reliably.
