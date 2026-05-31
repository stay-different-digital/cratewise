# ADR-0002: Use Discogs current token mode first

## Status

Accepted

## Context

The MVP needs a simple way to connect with Discogs.

The full Discogs login flow can be added later.

## Decision

Start with Discogs current token mode for MVP development and personal testing.

## Consequences

Positive:

- Faster MVP.
- Easier local development.
- Less authentication complexity.

Negative:

- Less user-friendly than full login.
- Users need to copy a token manually.

## Follow-up

Add full Discogs login flow after MVP search and collection features work.
