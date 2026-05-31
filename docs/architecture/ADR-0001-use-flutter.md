# ADR-0001: Use Flutter for Android and Windows

## Status

Accepted

## Context

Cratewise needs to support Android and Windows with one main codebase.

## Decision

Use Flutter as the main app framework.

## Consequences

Positive:

- One codebase for Android and Windows.
- Good control over UI.
- Strong mobile-first development.
- Possible future support for iOS, macOS, web, and Linux.

Negative:

- Windows-specific edge cases need testing.
- Some packages may not support Windows.

## Follow-up

Check Windows compatibility before adding packages.
