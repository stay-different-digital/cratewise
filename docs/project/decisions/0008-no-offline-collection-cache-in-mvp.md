# ADR 0008: Do Not Add Offline Collection Cache in MVP

## Status

Accepted

## Date

2026-05-30

## Context

The MVP should stay focused on collection management without adding sync complexity.

## Decision

Do not build offline-first collection cache in the MVP. Use in-memory state during app usage. Use secure storage only for auth or safe session data.

## Consequences

### Positive

- Keeps MVP smaller.
- Avoids sync bugs.
- Reduces storage complexity.

### Negative

- App needs internet for collection data.
- Some repeated loading may occur.

## Alternatives Considered

### Offline-first collection

Rejected for MVP. Reconsider after core flows work.

## Follow-up Actions

- Revisit after MVP.
- Document future cache strategy when needed.
