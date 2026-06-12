# Phase 11 Release Readiness — User Stories

Derived from the Phase 11 deliverables in `docs/product/ROADMAP_V2.md`.
**Story points** are estimates for a single developer.
Numbering continues from the Phase 10 stories (US-53 … US-55).

Stories marked **[Fred]** in the acceptance criteria contain steps that need
accounts, hardware, or credentials only Fred has (keystore generation, store
consoles, hosting). Everything else can be done in the repo.

---

### US-56: Android release builds are signed with a release keystore

**3 SP**

> As the developer preparing a Play Store beta,
> I want release builds signed with a proper upload keystore instead of the debug key,
> so that the Play Console accepts the build and the signing identity is stable across releases.

**Acceptance criteria:**
- `android/app/build.gradle.kts` reads signing config from `android/key.properties` (storeFile, storePassword, keyAlias, keyPassword) when that file exists.
- When `key.properties` is absent, the build falls back to the debug signing config so `flutter run --release` keeps working for local development — with no hard failure.
- `key.properties`, `*.jks`, and `*.keystore` are gitignored (already covered by `android/.gitignore` and the root `.gitignore`) and are never committed.
- No password, alias, or keystore path appears in any committed file or in build output.
- The `// TODO: Add your own signing config` comment is removed.
- **[Fred]** An upload keystore is generated (`keytool -genkey …`), `key.properties` is created locally, and `flutter build appbundle --release` produces a bundle signed with the release key.

---

### US-57: Branded splash screens for Android and iOS

**2 SP**

> As a user launching Cratewise,
> I want a branded splash screen instead of a blank white/black flash,
> so that the app feels finished from the first frame.

**Acceptance criteria:**
- `flutter_native_splash` is configured in `pubspec.yaml` with the brand colour `#FA003F` and the app icon foreground, for both Android and iOS.
- Dark mode shows an appropriate variant (same brand colour or a dark background — one deliberate choice, documented in the config).
- Android 12+ uses the proper `android_12` splash configuration (icon within the system-drawn circle, no clipped artwork).
- Generated assets are checked in (Android drawables, iOS LaunchScreen storyboard/images).
- A cold start on the iOS simulator and an Android emulator shows the splash without stretching or letterboxing.
- **[Fred]** Verified on physical Android phone, iPhone, and iPad during the next device pass.

---

### US-58: Release build and versioning are documented and reproducible

**2 SP**

> As the developer cutting a release,
> I want one documented, repeatable procedure for building signed, obfuscated release artefacts,
> so that every beta and store build is produced the same way.

**Acceptance criteria:**
- `docs/release/RELEASE_BUILD.md` documents: version bump rules for `pubspec.yaml` (`x.y.z+build` — semver plus monotonically increasing build number), the exact `flutter build appbundle` and `flutter build ipa` commands, and where artefacts land.
- The documented commands include `--obfuscate --split-debug-info=build/symbols` and the doc explains why and where symbol files must be archived (crash de-obfuscation).
- The doc states explicitly that symbol files and keystores are never committed; `build/symbols` is covered by the existing `build/` gitignore.
- The doc covers both platforms' prerequisites (key.properties for Android, Xcode signing team for iOS).
- A signed release build (`flutter build appbundle --release`) completes without errors using the documented procedure.
- **[Fred]** `flutter build ipa` verified on the Mac with the Apple Developer account selected; signed builds install and run on physical Android and iOS devices (Phase 11 done criterion).

---

### US-59: Privacy policy text is final and ready to host

**2 SP**

> As a user (and as the app stores' review teams),
> I want a clear privacy policy describing what Cratewise does with my data,
> so that I can trust the app and the store listings can link to a valid policy URL.

**Acceptance criteria:**
- `docs/store/PRIVACY_POLICY.md` contains the complete policy text in plain English.
- The policy accurately reflects the app: all collection data stored locally on-device (Drift/SQLite); Discogs personal access token stored only in platform secure storage (Keychain / Android Keystore); network requests go only to the Discogs API (api.discogs.com) on the user's behalf; camera used solely for on-device barcode scanning with no images stored or transmitted; no analytics, no ads, no crash reporting, no third-party data sharing.
- The policy covers: data deletion (uninstall removes all local data; disconnect removes the token), Discogs' own role as an independent service with its own privacy policy, contact information, and an effective date.
- No personal data is claimed that the app does not actually collect, and nothing the app does collect is omitted.
- **[Fred]** The policy is hosted at a public URL (e.g. GitHub Pages or cratewise.app) and that URL is recorded in `docs/store/STORE_LISTINGS.md`.

---

### US-60: Play Console listing content is drafted

**2 SP**

> As the developer filling in the Play Console,
> I want all listing text and data-safety answers prepared in advance,
> so that the console forms are a copy-paste exercise instead of ad-hoc writing.

**Acceptance criteria:**
- `docs/store/STORE_LISTINGS.md` contains the Android section: app title (≤30 chars), short description (≤80 chars), full description (≤4000 chars), category, contact email, and privacy policy URL placeholder.
- A complete Data Safety form cheat-sheet is included: every Play data-safety question answered to match reality (no data collected/shared off-device except user-initiated Discogs API calls authenticated with the user's own token).
- A screenshot shot-list specifies which screens to capture (Search, Collection, Release detail, Scanner, Settings/Discogs) and required dimensions for phone and 7"/10" tablet.
- All claims are consistent with the privacy policy from US-59.
- **[Fred]** Screenshots captured, listing created in the Play Console, data safety form submitted.

---

### US-61: App Store Connect listing content is drafted

**2 SP**

> As the developer filling in App Store Connect,
> I want listing text and privacy nutrition label answers prepared in advance,
> so that the App Store submission is not blocked on writing or guesswork.

**Acceptance criteria:**
- `docs/store/STORE_LISTINGS.md` contains the iOS section: app name (≤30 chars), subtitle (≤30 chars), promotional text (≤170 chars), description, keywords (≤100 chars), support URL, and privacy policy URL placeholder.
- A privacy nutrition label cheat-sheet answers every App Privacy question to match reality ("Data Not Collected" — no data leaves the device except user-initiated Discogs API calls; the developer collects nothing).
- A screenshot shot-list covers required iPhone sizes and 13" iPad (including a landscape/split-view shot, since iPad is a first-class target).
- Export compliance answer documented (HTTPS-only/exempt encryption usage).
- All claims are consistent with the privacy policy from US-59.
- **[Fred]** Screenshots captured, listing created in App Store Connect, nutrition labels submitted.

---

### US-62: Release checklist covers Android + iOS

**1 SP**

> As the developer cutting any future release,
> I want a single checklist covering both shipping platforms,
> so that no release step (tests, version bump, signing, store upload) is forgotten.

**Acceptance criteria:**
- `docs/release/RELEASE_CHECKLIST.md` exists with an ordered checklist: tests green → version bump → CHANGELOG entry → signed Android appbundle → signed iOS ipa → smoke test on device → upload to Play Console internal track → upload to TestFlight → tag in git.
- The checklist targets Android + iOS; Windows does not appear anywhere in it (the roadmap notes the old checklist targeted Android + Windows).
- Each step names the exact command or console location, referencing `RELEASE_BUILD.md` (US-58) rather than duplicating build instructions.
- A repo-wide search for "Windows" in release/checklist docs returns no scope-related hits.
