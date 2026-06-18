# ADR-0004: Use Drift and SQLite for local-first storage

## Status

Accepted

## Context

Cratewise is a local-first app. The collection, wishlist, cached release
metadata, thumbnails, import/export history, pending Discogs deletions, and
retry queue must remain usable when the device is offline.

The architecture notes allowed either Drift or Isar for local database storage.
The app now stores its structured local data in SQLite through Drift.

## Decision

Use Drift with SQLite as the canonical local database layer.

Repository contracts stay in the domain layer. Drift table definitions,
converters, migrations, and repository implementations stay in
`infrastructure/local_database`.

## Consequences

Positive:

- SQLite is stable, inspectable, and well suited to local-first mobile data.
- Drift gives typed queries, migrations, and in-memory database support for
  tests.
- Repository implementations can keep persistence details out of presentation
  and application code.
- Import/export history, sync status, retry actions, and tombstones can be
  modelled transactionally.

Negative:

- Drift generates a large `.g.dart` file that should not be treated like hand
  written code.
- Schema changes require disciplined migrations and tests.
- Multiple `AppDatabase` instances against the same executor can cause Drift
  warnings and potential race conditions, so database lifetime must be managed
  at app scope.

## Follow-up

Keep all local database access behind repository interfaces and add migration
tests for schema changes that affect persisted user data.
