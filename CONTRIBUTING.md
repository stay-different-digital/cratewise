# Contributing to Cratewise

Thanks for wanting to help! Cratewise is a small, one-person project, so
contributions follow a few simple rules to keep everyone's work useful.

## How to contribute

1. **Open an issue first.** Pick a template: bug report, feature request or
   technical task. Blank issues are disabled.
2. **Wait for approval.** The maintainer replies on the issue. When the issue
   gets the **`accepted`** label, a pull request is welcome.
3. **Fork the repository** and create a branch from `master`.
4. **Make a small, focused change** with tests where it makes sense.
5. **Open a pull request** that links the issue (`Closes #123`) and fill in
   the template.

A pull request without an issue, or for an issue without the `accepted`
label, may be closed without review. Small typo fixes in docs are welcome
without an issue.

**Security problems** don't go in an issue: see [SECURITY.md](SECURITY.md).

## Setting up

- [Flutter](https://docs.flutter.dev/get-started/install) — the version in
  `.github/workflows/flutter-ci.yml` (`flutter-version`).
- For iOS builds: Xcode and CocoaPods. For Android builds: Android Studio
  (its bundled JDK is used automatically).
- A **Discogs personal access token** of your own: on Discogs go to
  Settings → Developers → Generate new token, and enter it in the app under
  Settings. Never commit it.

```bash
flutter pub get
flutter run
```

## Checking your change

Run the same checks as CI with one command:

```bash
tool/ci_local.sh            # format, analyze, tests, Android release build, iOS build
tool/ci_local.sh --skip-ios # without the iOS build
```

If you can't build for iOS or Android, at least run:

```bash
dart format .
flutter analyze
flutter test
```

GitHub Actions does **not** run on every pull request; the maintainer runs
the checks before merging.

## Conventions

- **Layers:** `lib/domain` (models, rules) → `lib/infrastructure` (Discogs
  API, database, storage) → `lib/presentation` (screens, widgets). Keep logic
  out of widgets where you can.
- **Style:** `dart format` and the rules in `analysis_options.yaml`;
  `flutter analyze` must report no issues.
- **Text in the app:** add every new string to all `.arb` files in
  `lib/l10n/` (en, nl, de, fr, es).
- **Database changes:** see the comment at the top of
  `test/infrastructure/local_database/migration_test.dart`.
- **Commits:** a short, clear summary line; mention the issue number.
- **Changelog:** add user-visible changes to `CHANGELOG.md`.
- **Never commit secrets:** no Discogs tokens, `.env`, keystores,
  `key.properties` or certificates.

## License

Cratewise is licensed under the [GNU GPL v3.0](LICENSE). By contributing, you
agree that your contribution is released under the same license.
