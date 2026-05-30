# ADR 0007: Use Real Discogs API Calls From the Start

## Status

Accepted

## Date

2026-05-30

## Context

The project should reveal real API constraints early, including data shapes, rate limits, auth behavior, and missing fields.

## Decision

Use real Discogs API calls from the first build. Mock data is allowed only for tests and isolated UI previews.

## Consequences

### Positive

- Exposes real integration issues early.
- Reduces risk of building against false assumptions.
- Makes the MVP more realistic.

### Negative

- Development can be slower when API limits apply.
- Requires earlier auth and API setup.

## Alternatives Considered

### Mock-first app

Rejected. It hides real API behavior too long.

## Follow-up Actions

- Build a base API client early.
- Add fake clients only for tests.
- Add error mapping early.
