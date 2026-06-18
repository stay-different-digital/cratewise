# ADR-0005: Use GoRouter for navigation

## Status

Accepted

## Context

Cratewise needs predictable navigation across Android phones, iPhones, and
iPads. The app has top-level tabs, detail pages, import/export flows, onboarding,
and wide-layout behaviours that need route awareness.

The app originally used direct widget navigation in some places, but the current
navigation model uses GoRouter.

## Decision

Use GoRouter as the app routing layer.

Use a `StatefulShellRoute.indexedStack` for the main tabs so each branch can
preserve its navigation state. Define route paths and helper methods in
`AppRoutes`, and build the router through `createAppRouter`.

## Consequences

Positive:

- Route definitions are centralized.
- Deep-link-shaped paths can be tested and reused.
- Tab state is preserved while users move between Search, Collection, Wishlist,
  Scan, and Settings.
- Route observers can refresh local-first screens when returning from detail
  pages.
- iPad split-pane and phone navigation can share the same route model.

Negative:

- Router lifecycle matters. A stale global router can preserve unwanted branch
  state across app restarts in tests or integration sessions.
- Widget tests need router harnesses for screens that navigate.
- Route-aware behaviours must be wired to the correct branch observer.

## Follow-up

Keep route creation app-scoped rather than global, and add route tests whenever
new navigation paths or shell branches are introduced.
