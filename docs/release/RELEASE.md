# Releasing Cratewise

Since 2026-11-16 Cratewise is **not** published to the App Store or Google
Play. A release is a version tag on GitHub plus a signed Android APK attached
to a GitHub Release. The older store documents in this folder and in
`docs/store/` are kept for history only.

## 1. Check

```bash
tool/ci_local.sh            # same checks as CI: format, analyze, tests,
                            # Android release build + KGP check, iOS build
```

For a release that touches stored data (database schema, secure storage,
dependencies with native code), also run the upgrade test on an emulator:
write with the previous tag, verify with the new code (see the header of
`integration_test/app_upgrade_test.dart`; use `--no-uninstall` in both
phases).

## 2. Version and changelog

- `pubspec.yaml`: bump the version per [ADR-0003](../architecture/ADR-0003-versioning-scheme.md);
  the build number after `+` always goes up by one.
- `CHANGELOG.md`: add `## [X.Y.Z] — YYYY-MM-DD` above the previous release.
- Commit: `Bump version to X.Y.Z — <short description>`.

## 3. Tag and push

```bash
git tag -a vX.Y.Z -m "Cratewise X.Y.Z (build N): <short description>"
git push origin master vX.Y.Z
```

A tag `vX.0.0` (major release) starts the Flutter CI workflow on GitHub
(Android job). The iOS job only runs when started by hand:
GitHub → Actions → Flutter CI → Run workflow → tick **ios**.

## 4. Publish the APK

```bash
tool/release.sh X.Y.Z
```

The script must run with `HEAD` at the tag and a clean working tree. It
builds the APK, checks versionName/versionCode against `pubspec.yaml` and the
signature against the release key, and creates the GitHub Release with the
changelog section and the SHA-256 of the APK. It refuses when the tag is not
on origin or the release already exists.

Signing needs `android/key.properties` and the keystore on this machine; they
are never committed and never go to GitHub. An APK built without them is
signed with the debug key and won't install as an update.

## 5. Install

Download `Cratewise-X.Y.Z.apk` from the GitHub Release (or
`build/Cratewise-X.Y.Z.apk`) and install it over the existing app.
