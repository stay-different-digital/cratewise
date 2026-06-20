# Release Build Procedure

How to produce signed, obfuscated release artefacts for Android and iOS.
For the full release flow (tests, changelog, store upload), see
`RELEASE_CHECKLIST.md`.

## Versioning

The single source of truth is `version:` in `pubspec.yaml`, in the form
`x.y.z+build`:

- `x.y.z` — semantic version shown to users (`versionName` /
  `CFBundleShortVersionString`).
- `+build` — build number (`versionCode` / `CFBundleVersion`). **Increase it
  on every store upload**, even if `x.y.z` is unchanged — both stores reject
  re-used build numbers.

Rules:

- Beta builds: keep `1.0.0` and bump only the build number (`1.0.0+2`,
  `1.0.0+3`, …).
- Bug-fix release after 1.0: bump patch (`1.0.1+N`).
- New features: bump minor (`1.1.0+N`).
- Never lower the build number; Play and App Store both require it to be
  monotonically increasing.

## Prerequisites

### Android

- An upload keystore (generated once, stored **outside the repo**, backed up):

  ```sh
  keytool -genkey -v -keystore ~/keystores/cratewise-upload.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```

- `android/key.properties` (gitignored — **never commit this file**):

  ```properties
  storeFile=/Users/<you>/keystores/cratewise-upload.jks
  storePassword=<store password>
  keyAlias=upload
  keyPassword=<key password>
  ```

- Without `key.properties`, release builds fall back to the **debug key**:
  fine for local `flutter run --release`, rejected by the Play Console.

### iOS

- Xcode signed in to the Apple Developer account, with the team selected for
  the Runner target (Signing & Capabilities → automatic signing).
- Bundle id `app.cratewise` registered in the developer portal (Xcode's
  automatic signing handles this on first archive).

## Build commands

Both commands enable Dart obfuscation. Obfuscation makes stack traces from
crash reports unreadable unless you keep the symbol files, so
`--split-debug-info` is mandatory whenever `--obfuscate` is used.

### Android (App Bundle for Play Console)

```sh
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols
```

Artefact: `build/app/outputs/bundle/release/app-release.aab`

### iOS and iPadOS (IPA for TestFlight / App Store)

```sh
flutter build ipa --release \
  --obfuscate --split-debug-info=build/symbols
```

Artefact: `build/ios/ipa/cratewise.ipa` (and the Xcode archive under
`build/ios/archive/`).

Cratewise uses **Transporter** as the manual upload path for iOS and iPadOS
releases:

1. Install Transporter from the Mac App Store and sign in with the Apple ID that
   has access to the Cratewise App Store Connect app record.
2. Drag `build/ios/ipa/cratewise.ipa` into Transporter.
3. Click **Deliver** and wait for validation and upload to finish.
4. Keep the delivery log if Transporter reports a validation warning or error.
5. After App Store Connect finishes processing the build, assign it to
   TestFlight or the App Store version.

Transporter is only the upload tool. The IPA still has to be signed correctly
before upload: Xcode must be signed in, the Runner target must have a Team
selected, and App Store distribution signing/provisioning must be valid.

Note for builds started from a Claude/agent shell: SPM bare-repo checkouts
need `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all`
(see project environment notes).

## Symbol files

`build/symbols/` contains the de-obfuscation maps for this exact build.

- **Archive them per release** (e.g. zip named after the version:
  `symbols-1.0.0+2.zip`) somewhere durable outside the repo.
- They are required to symbolicate crash stack traces:
  `flutter symbolize -i stack.txt -d build/symbols/app.android-arm64.symbols`
- `build/` is gitignored; symbol files and keystores are **never committed**.

## Verifying a build

- Android: `flutter install --release` on a connected device, or build an APK
  for sideloading (`flutter build apk --release --obfuscate
  --split-debug-info=build/symbols`).
- iOS/iPadOS: upload the IPA with Transporter, wait until the build appears in
  TestFlight, then install it on a connected iPhone and iPad for the smoke test.
- Smoke test per `RELEASE_CHECKLIST.md` before uploading.
