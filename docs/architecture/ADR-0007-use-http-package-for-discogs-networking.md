# ADR-0007: Use the http package for Discogs networking

## Status

Accepted

## Context

The architecture notes listed Dio as a suggested HTTP package. The implemented
Discogs client uses the Dart `http` package.

Cratewise currently needs straightforward REST calls to Discogs, typed error
mapping, token-safe messages, timeouts, rate-limit handling, and injectable
clients for tests.

## Decision

Use `package:http` for the Discogs API client and related simple HTTP fetches.

Keep Discogs-specific policy in `DiscogsApiClient`: base URL, versioned Accept
header, User-Agent, token header, timeout mapping, status-code mapping, and
rate-limit state.

## Consequences

Positive:

- The dependency is small and easy to mock with `http/testing`.
- The current API surface is simple enough that interceptors are not required.
- Typed errors and token-safety rules stay explicit in app code.
- Tests can inject `MockClient` without platform or network access.

Negative:

- There is no built-in interceptor pipeline for auth, retry, logging, or request
  cancellation.
- Rate-limit and retry policy must be implemented manually.
- If API usage grows, repeated policy code could become harder to maintain.

## Follow-up

Reconsider Dio if Cratewise needs centralized interceptors, request
cancellation, richer timeout policy, automatic retries, or more advanced
request/response diagnostics.
