# Release Checklist — Android + iOS

> **Historical (since 2026-11-16):** Cratewise is no longer published to the App Store or Google Play. This document is kept for reference only. The current process is in [docs/release/RELEASE.md](RELEASE.md).

Run through this list in order for every release (beta or store). Build
details live in `RELEASE_BUILD.md`; store copy lives in
`../store/STORE_LISTINGS.md`.

## 1. Pre-flight

- [ ] Working tree clean, on `master`, all intended changes merged.
- [ ] `flutter analyze` — zero issues.
- [ ] `flutter test` — full suite green.
- [ ] No secrets in the diff since the last release: `git log -p <last-tag>..HEAD | grep -iE "token|secret|password"` returns nothing real.
- [ ] **Platform dependency warnings** — check build output for new warnings beyond those documented in `docs/archive/known_limitations.md § Platform dependency warnings`. If a documented warning has disappeared (upstream fixed), remove its entry from known_limitations.md. If a new warning appears, add it before shipping.

## 2. Version & changelog

- [ ] Bump `version:` in `pubspec.yaml` (`x.y.z+build` — see versioning rules in `RELEASE_BUILD.md`; build number must increase on every upload).
- [ ] Add a `CHANGELOG.md` entry for this version.
- [ ] Commit: `release: vX.Y.Z+N`.

## 3. Build Android

- [ ] `android/key.properties` present and pointing at the upload keystore.
- [ ] `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`
- [ ] Archive `build/symbols/` as `symbols-X.Y.Z+N-android.zip` (outside the repo).

## 4. Build iOS and iPadOS

- [ ] Xcode signed in, team selected for Runner.
- [ ] **Purpose strings** — for every package added since the last release,
  verify no new `NS*UsageDescription` key is required. See the table in
  `RELEASE_BUILD.md § iOS purpose strings`. Missing keys cause an ITMS-90683
  rejection after upload and require a new binary before the build can proceed.
- [ ] `flutter build ipa --release --obfuscate --split-debug-info=build/symbols`
- [ ] Archive `build/symbols/` as `symbols-X.Y.Z+N-ios.zip` (outside the repo).

## 5. Smoke test on device

On at least one physical Android device and one physical iOS device, using the
release artefacts (not a debug build):

- [ ] Cold start lands on the Search tab; correct app icon and branded splash.
- [ ] Search a release; open its detail page; tap the label and check the
      label's releases appear newest first.
- [ ] Toggle "Vinyl only" in Search; open the Statistics tab.
- [ ] Add to collection and to wantlist; relaunch — data persisted.
- [ ] Settings: connect Discogs token, validate, disconnect.
- [ ] CSV export completes.

## 6. Upload

- [ ] Android: upload the `.aab` to the Play Console **internal testing** track; release notes from the changelog.
- [ ] iOS/iPadOS: upload `build/ios/ipa/cratewise.ipa` with **Transporter**; keep the delivery log if validation reports warnings/errors; assign the processed build to **TestFlight**; export compliance is pre-answered (`ITSAppUsesNonExemptEncryption=NO`).
- [ ] First release only: store listings, data safety form, and privacy nutrition labels per `../store/STORE_LISTINGS.md`; privacy policy URL live.

## 7. Tag & close

- [ ] Tag: `git tag vX.Y.Z+N && git push --tags` (push only when intended).
- [ ] Verify the build appears for testers (internal track / TestFlight).
- [ ] File stories for anything found during the smoke test.
