# ADR 0004: Use Riverpod for State Management

## Status

Accepted

## Date

2026-05-30

## Context

Crate needs testable state management for auth, collection data, search state, filters, theme settings, and API dependencies.

## Decision

Use Riverpod for state management and dependency injection.

## Consequences

### Positive

- Keeps state testable.
- Avoids business logic in widgets.
- Works well with feature-based architecture.
- Supports dependency overrides in tests.

### Negative

- Requires consistent provider structure.
- Developers must understand Riverpod patterns.

## Alternatives Considered

### Provider package

Rejected. Riverpod is more flexible for this architecture.

### Bloc

Rejected for now. It adds more boilerplate than needed.

## Follow-up Actions

- Add provider conventions.
- Add tests with provider overrides.
- Consider riverpod_lint.
