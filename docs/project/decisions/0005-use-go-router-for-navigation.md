# ADR 0005: Use go_router for Navigation

## Status

Accepted

## Date

2026-05-30

## Context

Crate needs structured navigation for auth, collection, release detail, search, barcode scanner, wantlist, settings, and possible deep links.

## Decision

Use go_router for navigation.

## Consequences

### Positive

- Supports declarative routes.
- Works well with auth redirects.
- Supports deep links.
- Keeps route definitions centralized.

### Negative

- Requires careful route naming.
- Auth redirect logic must stay simple.

## Alternatives Considered

### Navigator 1.0

Rejected. It is less suitable for route-based app structure.

### Custom router

Rejected. It adds unnecessary complexity.

## Follow-up Actions

- Add route map.
- Add auth guard.
- Add release detail route with ID.
