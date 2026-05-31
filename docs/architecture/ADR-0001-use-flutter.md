# ADR-0001: Use Flutter for Android, iPhone, and iPad

## Status

Accepted

## Context

Cratewise needs to support Android phones, iPhones, and iPads with one main
codebase.

## Decision

Use Flutter as the main app framework.

## Consequences

Positive:

- One codebase for Android, iPhone, and iPad.
- Good control over UI.
- Strong mobile-first development.
- Responsive layouts can make the app feel natural on larger iPad screens.

Negative:

- Native plugin behavior needs testing on both Android and iOS/iPadOS.
- Some packages may need platform-specific setup for permissions or build
  configuration.

## Follow-up

Check Android and iOS/iPadOS compatibility before adding packages.
