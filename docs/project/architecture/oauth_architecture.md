# OAuth Architecture

## Purpose

This document explains how Crate handles Discogs OAuth.

## Decision Summary

Crate uses Discogs OAuth login.

The Flutter app does not store the Discogs consumer secret.

A Cloudflare Worker acts as Backend-for-Frontend for OAuth signing and secret handling.

## Why a Backend-for-Frontend Is Needed

A Flutter mobile app is distributed to user devices.

Anything inside the app can eventually be inspected.

Because Discogs OAuth 1.0a uses a consumer secret, the app must not include that secret.

## Components

### Flutter App

Responsibilities:

- Show login UI.
- Start the login flow.
- Open Discogs authorization page.
- Handle callback or redirect.
- Store safe session values where needed.
- Show logged-in or logged-out state.
- Call the Cloudflare Worker for authenticated operations.
- Show user-friendly error messages.

The Flutter app must not:

- Store the Discogs consumer secret.
- Sign OAuth requests with the consumer secret.
- Log sensitive tokens.
- Commit secrets.

### Cloudflare Worker

Responsibilities:

- Store Discogs consumer key and secret as Worker secrets.
- Create signed OAuth requests.
- Start the OAuth flow.
- Handle callback validation.
- Exchange verifier values.
- Call Discogs API v2.0 where signed calls are needed.
- Map Discogs errors to clean app errors.
- Avoid logging sensitive values.

## Suggested Worker Endpoints

```text
POST /auth/start
GET /auth/callback
POST /auth/logout
GET /me
GET /collection
GET /releases/:id
GET /search
GET /wantlist
```

## OAuth Flow

1. User taps `Connect Discogs`.
2. Flutter calls `POST /auth/start`.
3. Worker creates the OAuth request.
4. Worker returns an authorization URL.
5. Flutter opens the authorization URL.
6. User authorizes Crate in Discogs.
7. Discogs redirects to the callback URL.
8. Worker validates the callback.
9. Worker exchanges verifier values.
10. Worker creates or returns safe session data.
11. Flutter stores safe local state.
12. App shows connected state.

## Token Storage

Use `flutter_secure_storage` for local sensitive values where needed.

Do not store:

- Discogs consumer secret
- Full authorization headers
- Debug tokens in logs

## Error Handling

Map technical errors to user-friendly messages.

Examples:

| Technical problem | User message |
|---|---|
| OAuth callback invalid | Could not connect Discogs |
| Unauthorized | Connect Discogs again |
| Rate limited | Too many requests. Try again soon |
| Network error | Check your internet connection |
| Discogs unavailable | Discogs is unavailable. Try again later |

## Security Rules

- Do not commit secrets.
- Do not expose Worker secrets.
- Do not log OAuth tokens.
- Use HTTPS.
- Validate callback state.
- Rotate secrets if leaked.
