# ADR 0003: Use Flutter Feature-Based Clean Architecture

## Status

Accepted

## Date

2026-05-30

## Context

Crate will contain several app areas, such as auth, collection, release detail, search, barcode scanner, wantlist, and settings. The project needs a structure that stays understandable as it grows.

## Decision

Use Flutter with feature-based clean architecture. Split each feature into data, domain, and presentation layers.

## Consequences

### Positive

- Keeps features isolated.
- Makes testing easier.
- Makes the app easier to refactor.
- Prevents large mixed folders.

### Negative

- Adds more folders at the start.
- Can feel heavy for very small features.

## Alternatives Considered

### Layer-first folders

Rejected. Feature-based work is easier for this app.

### Simple folder structure

Rejected for now. It can become messy quickly.

## Follow-up Actions

- Create base folder structure.
- Keep shared UI in core and shared folders.
- Add examples for auth and collection features.
