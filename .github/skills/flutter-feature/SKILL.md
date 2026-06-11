---
name: flutter-feature
description: Build a small Flutter feature slice for Cratewise using clean architecture, Android and iOS support, tests, and documentation updates.
argument-hint: '[feature slice]'
---

# Flutter Feature Skill

Use this skill when implementing a Flutter feature for Cratewise.

## Procedure

1. Read the relevant docs.
2. Identify the feature slice.
3. Keep the change small.
4. Add domain models first when needed.
5. Add repository contracts before infrastructure.
6. Add infrastructure implementations.
7. Add application state or use cases.
8. Add UI widgets and screens.
9. Add tests.
10. Run formatting and checks.
11. Update docs when behavior changes.

## Architecture rules

Use these layers:

- `presentation`
- `application`
- `domain`
- `infrastructure`
- `shared`

Do not let widgets call external APIs directly.

Do not let widgets write to the local database directly.

## Done criteria

- Feature works on Android.
- Feature works on iOS.
- Feature works on iPadOS.
- Core logic has tests.
- User-facing errors are friendly.
- Docs are updated when needed.
