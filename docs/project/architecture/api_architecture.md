# API Architecture

## Purpose

This document explains how Crate communicates with Discogs API v2.0 through a secure architecture.

## Main Rule

Use Discogs API v2.0 only.

Do not use Discogs API v1.0.

Do not scrape Discogs pages.

## API Access Pattern

Crate uses this pattern:

```text
Flutter app -> Repository -> Data source -> Cloudflare Worker -> Discogs API v2.0
```

Direct calls from Flutter to Discogs are only allowed when they do not require secrets and fit the documented architecture.

The preferred default is to route Discogs calls through the Cloudflare Worker, because it centralizes:

- OAuth signing
- User-Agent handling
- Rate limit handling
- Error mapping
- Request validation
- Secret protection

## Flutter Layers

### Presentation

Contains:

- Screens
- Widgets
- Controllers
- UI state

Must not contain:

- Raw HTTP calls
- Secret handling
- Discogs-specific signing logic

### Domain

Contains:

- Entities
- Repository contracts
- Use cases

### Data

Contains:

- API models
- Data sources
- Repository implementations
- Mapping between API models and domain entities

## Discogs API Client

Use a dedicated API client class.

Example:

```text
lib/core/api/discogs_api_client.dart
```

Responsibilities:

- Send HTTP requests.
- Add required headers.
- Respect timeout settings.
- Parse responses.
- Convert technical errors to app exceptions.

## Required Headers

Add a clear User-Agent.

Example format:

```text
Crate/0.1.0 +https://github.com/example/crate
```

## Error Mapping

Handle these cases:

- No internet
- Unauthorized
- Forbidden
- Rate limited
- Not found
- API unavailable
- Unexpected response
- Timeout

Do not show raw technical errors directly to the user.

## Rate Limit Handling

The API layer must detect rate limit responses.

When rate limited:

- Stop immediate repeated requests.
- Show a clear user message.
- Use response headers where available.
- Avoid automatic retry loops that can make the problem worse.

## Pagination

Collection and search endpoints may require pagination.

The app must:

- Load first page quickly.
- Support next page loading.
- Avoid duplicate items.
- Show loading state for more results.
- Handle pagination errors safely.

## Tests

Add tests for:

- API client behavior
- Header creation
- Error mapping
- Rate limit handling
- Pagination parsing
- Collection models
- Search models
- Release detail models
