# ADR 0002: Use Airbnb-Inspired Figma Design Direction

## Status

Accepted

## Date

2026-05-30

## Context

Crate needs a strong mobile visual direction from the start. The app should feel premium, visual, and easy to scan for music collectors.

## Decision

Use Airbnb-inspired mobile design patterns as inspiration. Use the linked Figma files as visual references. Do not copy Airbnb branding, logos, text, protected assets, or exact screens. Crate must have its own visual identity.

## Consequences

### Positive

- Gives the app a clear design direction.
- Helps keep UI decisions consistent.
- Works well for visual browsing and card-based layouts.
- Supports a premium collector-focused experience.

### Negative

- Requires extra care to avoid copying too closely.
- Requires a proper Flutter design system.

## Alternatives Considered

### Use default Material Design only

Rejected. It may feel less distinctive.

### Create a full custom design without references

Rejected for MVP. It takes more time.

## Follow-up Actions

- Create Flutter theme tokens.
- Create shared card components.
- Create release card component.
- Create tablet master-detail layout.
- Add light and dark mode color sets.
