# ADR 0010: Use Cloudflare Worker as BFF for Discogs API

## Status

Accepted

## Date

2026-05-30

## Context

Crate needs a safe and consistent way to call Discogs API v2.0, handle OAuth signing, hide secrets, map errors, and manage rate limits.

## Decision

Use Cloudflare Worker as Backend-for-Frontend for signed Discogs API calls and secret-based operations.

## Consequences

### Positive

- Keeps secrets out of Flutter.
- Centralizes error mapping.
- Centralizes rate limit handling.
- Makes API behavior easier to control.

### Negative

- Adds backend deployment.
- Worker endpoints must be maintained.

## Alternatives Considered

### Direct Flutter to Discogs for all calls

Rejected for signed or secret-based calls.

### Larger custom backend

Rejected for MVP.

## Follow-up Actions

- Add Worker route design.
- Add Worker API docs.
- Add Flutter repository clients for Worker endpoints.
