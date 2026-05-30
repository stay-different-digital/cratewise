# ADR 0009: Support Light, Dark, and System Theme

## Status

Accepted

## Date

2026-05-30

## Context

The user wants both light and dark mode. This affects theme tokens from day one.

## Decision

Support light mode, dark mode, and system theme mode. Store the user preference.

## Consequences

### Positive

- Better user experience.
- Avoids theme refactor later.
- Supports modern mobile expectations.

### Negative

- Requires testing both modes.
- Requires design tokens for both modes.

## Alternatives Considered

### Light mode only

Rejected. The project explicitly wants light and dark mode.

## Follow-up Actions

- Create theme tokens.
- Add settings option.
- Add widget tests for theme switching.
