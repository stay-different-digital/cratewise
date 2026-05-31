---
name: flutter-testing
description: Add, run, and review Flutter tests for Cratewise domain logic, repositories, API mapping, widgets, and manual QA scenarios.
argument-hint: '[test target]'
---

# Flutter Testing Skill

Use this skill when adding or reviewing tests.

## Test targets

Prioritize tests for:

- API client parsing
- Token validation
- Search result mapping
- Release detail mapping
- Collection repository
- Wishlist repository
- CSV import
- CSV export
- Sync status logic

## Procedure

1. Identify the behavior under test.
2. Add small focused tests.
3. Avoid tests that depend on live Discogs API calls.
4. Use fixtures or mock responses.
5. Test errors and empty states.
6. Run `flutter test`.

## Manual QA checklist

Check:

- Android
- Windows
- Light mode
- Dark mode
- Valid token
- Invalid token
- No internet
- Empty search result
- Rate limit error
- Offline collection view

## Done criteria

- Important logic is tested.
- Tests are deterministic.
- No live token is needed for automated tests.
