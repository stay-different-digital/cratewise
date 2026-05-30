# Security Policy

## Purpose

This document defines security rules for Crate.

Crate connects to Discogs through OAuth and uses a Cloudflare Worker for secret-based operations.

## Main Security Rules

- Never commit real secrets.
- Never store the Discogs consumer secret in the Flutter app.
- Never log sensitive tokens.
- Never expose OAuth secrets in client-side code.
- Store local sensitive values through secure storage.
- Use the Cloudflare Worker for Discogs OAuth signing.
- Use Discogs API v2.0 only.
- Do not scrape Discogs pages.

## Secrets

Discogs secrets must be stored as Cloudflare Worker secrets.

Examples:

```text
DISCOGS_CONSUMER_KEY
DISCOGS_CONSUMER_SECRET
```

These values must not be stored in:

- Flutter code
- `.env` committed to Git
- Test fixtures
- Logs
- Documentation examples with real values

## Local Environment

Use:

```text
.env
```

Do not commit `.env`.

Use `.env.example` for safe examples.

## Token Storage

Flutter may store safe user session values where needed.

Use:

```text
flutter_secure_storage
```

Do not store sensitive values in:

- Shared preferences
- Plain text files
- Logs
- Analytics events

## Logging

Do not log:

- OAuth tokens
- OAuth verifier
- Discogs consumer secret
- User access tokens
- Full authorization headers
- Personal user data

## Reporting Security Issues

If a security issue is found:

1. Do not open a public issue with sensitive details.
2. Document the issue privately.
3. Rotate affected secrets if needed.
4. Fix the issue in a dedicated branch.
5. Add a regression test where possible.
6. Update this document if needed.

## Dependency Security

Review dependencies before adding them.

Check:

- Package popularity
- Maintenance activity
- Platform support
- Permissions
- Security history

## Mobile Permissions

Only request permissions when needed.

For example:

- Camera permission only for barcode scanning

Explain why permission is needed in the UI.
