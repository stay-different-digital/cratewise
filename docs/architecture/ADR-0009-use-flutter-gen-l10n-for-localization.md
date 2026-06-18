# ADR-0009: Use Flutter gen-l10n for localization

## Status

Accepted

## Context

Cratewise needs to support multiple languages while remaining a Flutter-first
mobile app. Phase 15 defines support for English, German, French, Spanish, and
Dutch, with a user-overridable language preference.

The app already depends on `intl`, and Flutter provides `flutter_localizations`
and `gen-l10n` without requiring a third-party localization framework.

## Decision

Use Flutter's built-in localization stack:

- `flutter_localizations` from the Flutter SDK.
- ARB resource files under `lib/l10n`.
- `flutter gen-l10n` through `flutter.generate: true`.
- `intl` for locale-aware formatting.

Store the user's language override separately from the generated localization
messages, and pass the selected locale into `MaterialApp`.

## Consequences

Positive:

- Uses Flutter's standard localization pipeline.
- Generated `AppLocalizations` gives typed access to translated strings.
- ARB files are easy to review and translate.
- The app avoids another runtime dependency for localization.

Negative:

- Hardcoded UI strings must be migrated gradually and carefully.
- Widget tests need to account for localized text.
- Translation completeness becomes part of release quality.

## Follow-up

Keep new user-facing strings in ARB files. Add tests for language switching and
for the most important translated screens.
