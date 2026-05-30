# ADR 0012: Maintain Project Changelog

## Status

Accepted

## Date

2026-05-30

## Context

Vibe coding can move fast. The project needs a clear record of meaningful changes.

## Decision

Maintain `docs/project/changelog/changelog.md` from the start.

## Consequences

### Positive

- Tracks changes clearly.
- Helps release preparation.
- Helps review agent work.
- Helps future debugging.

### Negative

- Requires discipline.
- Small changes may need a judgment call.

## Alternatives Considered

### No changelog until release

Rejected. It is easier to maintain from the start.

## Follow-up Actions

- Add changelog checks to PR template.
- Update changelog after meaningful changes.
