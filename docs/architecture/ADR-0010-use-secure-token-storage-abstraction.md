# ADR-0010: Use a secure token storage abstraction

## Status

Accepted

## Context

The Discogs current token is a user secret. It must not be hardcoded, logged,
shown in errors, or stored in plain text.

Flutter Secure Storage provides platform-backed secure storage, but direct
platform-channel access is awkward to unit test. Cratewise also needs username
and token writes to behave predictably when saving credentials.

## Decision

Store Discogs credentials through a small token-storage abstraction.

Use Flutter Secure Storage as the production backend. Keep a
`SecureKeyValueStore` boundary so `DiscogsTokenStorage` can be unit tested with
fakes and so token handling rules stay centralized.

## Consequences

Positive:

- Token persistence uses iOS Keychain and Android secure storage mechanisms.
- Tests can cover save, load, remove, storage failure, and revoked-token cleanup
  without platform channels.
- Token masking and token-safe error behaviour can rely on one storage contract.
- The app can later swap or extend secure storage behaviour without changing UI
  code.

Negative:

- The abstraction is another layer to maintain.
- Platform-specific secure storage behaviour still needs manual device testing.
- Full OAuth may require additional credential types and lifecycle rules.

## Follow-up

Keep token values out of logs, exceptions, analytics, and UI text. Revisit the
storage contract when full Discogs OAuth is introduced.
