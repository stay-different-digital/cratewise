# Contributing to Crate

## Purpose

This guide explains how to contribute to Crate.

Crate is a Flutter app for music collectors. It uses Discogs API v2.0 and focuses first on collection management.

## Read First

Before contributing, read:

1. `AGENT.md`
2. `docs/project/working-agreement.md`
3. `docs/project/definition-of-ready.md`
4. `docs/project/definition-of-done.md`
5. Relevant ADRs in `docs/project/decisions/`

## Workflow

1. Pick or create an issue.
2. Create a branch from `main`.
3. Make a small focused change.
4. Add or update tests.
5. Run checks.
6. Update docs when needed.
7. Update changelog when needed.
8. Open a pull request.

## Branch Names

Use:

```text
feature/short-description
fix/short-description
docs/short-description
refactor/short-description
test/short-description
chore/short-description
```

## Code Rules

- Use Flutter and Dart.
- Use feature-based clean architecture.
- Use Riverpod for state management.
- Use go_router for navigation.
- Keep business logic out of widgets.
- Add tests for important logic.
- Keep UI states complete.

## API Rules

- Use Discogs API v2.0 only.
- Do not use Discogs API v1.0.
- Do not scrape Discogs.
- Respect rate limits.
- Use the Cloudflare Worker where secrets or signed calls are needed.
- Do not expose secrets in Flutter.

## Checks

Run before opening a PR:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Changelog

Update:

```text
docs/project/changelog/changelog.md
```

Use:

- Added
- Changed
- Fixed
- Removed
- Technical

## ADRs

Create or update an ADR when changing:

- Architecture
- State management
- Navigation
- API approach
- Auth approach
- Storage
- Design direction
- Testing strategy
- Major packages
- MVP scope
