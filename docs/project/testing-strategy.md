# Testing Strategy

## Purpose

This document defines the testing approach for Crate.

The goal is to keep the Flutter app stable while moving fast with vibe coding.

## Test Pyramid

Use this order of priority:

1. Unit tests
2. Widget tests
3. Integration tests
4. Manual tests

## Unit Tests

Use unit tests for:

- OAuth state handling
- Token storage
- Discogs API client behavior
- Error mapping
- Collection parsing
- Search parsing
- Release detail parsing
- Theme mode logic
- Use cases
- Repositories with mocked data sources

Example command:

```bash
flutter test
```

## Widget Tests

Use widget tests for:

- Loading states
- Empty states
- Error states
- Success states
- Collection item cards
- Search result cards
- Release detail sections
- Settings screen state

## Integration Tests

Use integration tests for critical flows:

- Login flow with mocked callback
- Collection list flow
- Search flow
- Release detail flow
- Barcode scan result flow
- Logout flow

Integration tests should not depend on real Discogs secrets.

## Manual Tests

Use manual tests for:

- Real Discogs OAuth login
- Real Discogs API response behavior
- Barcode scanner camera behavior
- iOS device behavior
- Android device behavior
- Tablet layouts
- Light and dark mode visual checks

## CI Checks

Every pull request should run:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

## Test Data Rules

Allowed:

- Fake API responses
- Mock repositories
- Local test fixtures
- Safe sample release data

Not allowed:

- Real secrets
- Real user tokens
- Personal data
- Hardcoded Discogs consumer secret
