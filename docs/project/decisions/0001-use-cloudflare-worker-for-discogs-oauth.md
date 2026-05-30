# ADR 0001: Use Cloudflare Worker for Discogs OAuth

## Status

Accepted

## Date

2026-05-30

## Context

Crate uses Discogs OAuth login. The Discogs OAuth flow requires secret-based signing. A Flutter app is distributed to user devices, so it must not contain the Discogs consumer secret.

## Decision

Use a Cloudflare Worker as Backend-for-Frontend for Discogs OAuth signing and callback handling. Store Discogs secrets as Worker secrets. The Flutter app handles the user flow and stores only safe local session values where needed.

## Consequences

### Positive

- Protects the Discogs consumer secret.
- Keeps OAuth logic centralized.
- Makes the Flutter app safer.
- Keeps the mobile code simpler.

### Negative

- Adds a small backend component.
- Requires Worker deployment and configuration.
- Local development needs a Worker base URL.

## Alternatives Considered

### Store the secret in Flutter

Rejected. Mobile apps can be inspected.

### Use Firebase Functions

Rejected for now. Firebase is useful when we also need Firebase Auth, database, or analytics.

### Use Laravel API

Rejected for now. It adds more backend complexity than the MVP needs.

## Follow-up Actions

- Create Cloudflare Worker project.
- Add Worker secrets.
- Add OAuth start and callback endpoints.
- Add Flutter auth client.
- Add tests for auth state handling.
