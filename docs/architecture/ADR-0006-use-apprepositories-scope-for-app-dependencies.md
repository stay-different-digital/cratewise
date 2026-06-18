# ADR-0006: Use AppRepositoriesScope for app dependencies

## Status

Accepted

## Context

Cratewise needs shared app-level dependencies: the Drift database, repositories,
transaction runner, API-facing services, and local-first infrastructure.

The architecture notes listed Riverpod as a suggested state-management package.
The app currently does not use Riverpod. Instead, it creates the database and
repositories in the app composition root and exposes them to the widget tree
through `AppRepositoriesScope`.

## Decision

Use `AppRepositoriesScope`, an `InheritedWidget`, as the app-level dependency
scope for repositories and database-backed services.

Screens may still accept constructor-injected repositories or services for
tests. When no test dependency is provided, screens read the app-scoped
dependency from `AppRepositoriesScope`.

## Consequences

Positive:

- Avoids adding a state-management framework before the app needs it.
- Keeps dependency ownership explicit and easy to inspect.
- Allows a single `AppDatabase` instance to be created and closed at app scope.
- Preserves existing test injection patterns.

Negative:

- `InheritedWidget` is lower-level than Riverpod and provides fewer guardrails.
- Async UI state still needs local state machines or dedicated services.
- If app state grows more complex, Riverpod may become worthwhile later.

## Follow-up

Reconsider Riverpod if dependency graphs, async state, or cross-screen state
become difficult to maintain with `AppRepositoriesScope` and constructor
injection.
