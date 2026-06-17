# Publishing Cratewise — Step-by-step Guide

How to get the app from this repo into the Google Play Store and the Apple
App Store, starting from zero (no developer accounts yet). Written for
Cratewise specifically; companion docs:

- `RELEASE_BUILD.md` — exact build commands, signing, versioning
- `RELEASE_CHECKLIST.md` — the per-release checklist
- `STORE_REVIEW.md` — review rejection traps + App Review notes
- `../store/STORE_LISTINGS.md` — all listing text, ready to paste
- `../store/PRIVACY_POLICY.md` — policy text to host

Rough timeline: accounts ~1–2 days (identity verification), first store
setup ~half a day per store, first review 1–7 days (Apple usually 24–48h,
Google's first review of a new account can take a week).

---

# Part 1 — One-time setup

## 1.1 Developer accounts

**Google Play Console** — https://play.google.com/console/signup
1. Sign in with the Google account you want to own the app (this is hard to
   change later — use a long-term personal or dedicated account).
2. Choose account type: **Personal** is fine for Cratewise. (Organisation
   requires a D-U-N-S number.)
3. Pay the **one-time $25** registration fee.
4. Complete identity verification (ID document; can take 1–2 days).
5. Note for new personal accounts: Google requires a **closed test with at
   least 12 testers for 14 days** before you may publish to production.
   Plan the Phase 12 beta to satisfy this — it counts.

**Apple Developer Program** — https://developer.apple.com/programs/enroll/
1. You need an Apple ID with two-factor authentication enabled.
2. Enrol as an **Individual** ($99/year, recurring).
3. Identity verification is usually instant, sometimes 1–2 days.
4. Once enrolled, sign in to Xcode: Xcode → Settings → Accounts → add your
   Apple ID. Your team appears automatically.

## 1.2 Host the privacy policy

Both stores require a public privacy policy URL before you can complete the
listing.

The repo contains a ready-made 11ty site in `site/` (landing page + privacy
policy) and a deploy workflow (`.github/workflows/deploy-pages.yml`).

1. GitHub → repo **Settings → Pages → Source: "GitHub Actions"**.
2. Push `master` (or run the "Deploy site to GitHub Pages" workflow
   manually); it builds `site/` and publishes it.
3. Verify `https://itris.github.io/cratewise/privacy/` loads.
4. The URL is already recorded in `docs/store/STORE_LISTINGS.md`.

Note: Pages on a **private** repo requires a paid GitHub plan; if the repo
is private and on the free plan, either make it public or host the same
`site/_site` output elsewhere (Netlify, Cloudflare Pages — both free).

## 1.3 Android signing key (once, keep forever)

```sh
mkdir -p ~/keystores
keytool -genkey -v -keystore ~/keystores/cratewise-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (gitignored — never commit):

```properties
storeFile=/Users/fred/keystores/cratewise-upload.jks
storePassword=<store password>
keyAlias=upload
keyPassword=<key password>
```

**Back up the keystore and passwords** (password manager + offline copy).
With Play App Signing, Google can reset a lost *upload* key, but it's a
support process you don't want.

iOS needs no manual key work — Xcode's automatic signing handles
certificates and provisioning once you're signed in to your team.

## 1.4 Screenshots

Shot-lists and required sizes are in `../store/STORE_LISTINGS.md`. Practical
route: seed the app with a realistic collection, then:

- **Android:** phone + tablet emulators (or devices), screenshot the six
  scenes.
- **iOS:** iPhone 17 Pro Max simulator and 13" iPad simulator
  (`Cmd+S` saves a screenshot at the exact required resolution).
- Never show a real Discogs token on screen.

---

# Part 2 — Google Play, first release

## 2.1 Create the app

1. Play Console → **Create app**.
2. Name: `Cratewise — Vinyl Collection` · Default language: English (US) ·
   Type: App · Free.
3. Accept the declarations.

## 2.2 Complete the "Set up your app" tasks

The console shows a task list; all answers are prepared:

1. **Privacy policy** — paste the hosted URL (§1.2).
2. **App access** — "All functionality is available without special access".
   (A Discogs token is optional; reviewers don't need one — see
   `STORE_REVIEW.md`.)
3. **Ads** — No ads.
4. **Content rating** — fill the questionnaire (no violence, no UGC visible
   to others, etc.) → rating "Everyone".
5. **Target audience** — 18+ or 13+ (don't target children; avoids extra
   policy requirements).
6. **News app** — No.
7. **Data safety** — answers in `../store/STORE_LISTINGS.md`: **no data
   collected, no data shared**.
8. **Government app** — No.
9. **Store listing** — paste title, short and full description from
   `../store/STORE_LISTINGS.md`; upload the app icon (512×512), feature
   graphic (1024×500), and screenshots.

## 2.3 Build and upload

```sh
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

1. Play Console → **Testing → Internal testing** → Create release.
2. On first upload you'll be asked to enrol in **Play App Signing** — accept
   (Google holds the app signing key; your keystore is the upload key).
3. Upload `build/app/outputs/bundle/release/app-release.aab`.
4. Release notes: from `CHANGELOG.md`.
5. Add testers (email list including your own), save, roll out.
6. Open the opt-in link on your phone, install from the Play Store, and run
   the smoke test from `RELEASE_CHECKLIST.md`.

## 2.4 Beta → production

1. Run the Phase 12 beta on internal/closed testing (remember the
   12-testers/14-days rule for new personal accounts, §1.1).
2. When ready: **Production → Create release** → reuse the tested bundle
   (or upload the release build with a bumped build number).
3. **Send for review.** First review on a new account can take up to a week;
   subsequent updates are usually hours.
4. After approval the app goes live (default: automatic publish; you can
   switch to managed publishing if you want to control the moment).

---

# Part 3 — Apple App Store, first release

## 3.1 Register the app

1. https://appstoreconnect.apple.com → **My Apps → + → New App**.
2. Platform: iOS · Name: `Cratewise — Vinyl Collection` · Language:
   English (US) · Bundle ID: select `app.cratewise` · SKU: `cratewise`
   (internal only).
   - If `app.cratewise` isn't offered: build once from Xcode on your Mac
     with automatic signing (it registers the bundle ID), or add it at
     developer.apple.com → Identifiers.

## 3.2 Fill in the listing

All text is in `../store/STORE_LISTINGS.md`:

1. Subtitle, promotional text, description, keywords, support URL,
   privacy policy URL.
2. **App Privacy** → answer "Data Not Collected" (per the cheat-sheet).
3. Screenshots: 6.9" iPhone set + 13" iPad set.
4. Age rating questionnaire → 4+.
5. **App Review notes**: paste the prepared text from `STORE_REVIEW.md`
   (explains that a Discogs account is optional).

## 3.3 Build and upload

```sh
flutter build ipa --release --obfuscate --split-debug-info=build/symbols
```

(From a Claude/agent shell, prefix with the SPM git config from
`RELEASE_BUILD.md`; from your own terminal it's not needed.)

Upload, pick one:
- **Transporter app** (Mac App Store, simplest): drag in
  `build/ios/ipa/cratewise.ipa` → Deliver.
- Or Xcode → Window → Organizer → select the archive → Distribute App.

Processing takes ~15–30 min; the build then appears in App Store Connect.

## 3.4 TestFlight (beta)

1. App Store Connect → TestFlight → the build appears after processing.
2. First build asks the export compliance question — already answered by
   `ITSAppUsesNonExemptEncryption=NO` in Info.plist, so it should not prompt.
3. **Internal testing** (your own Apple ID, up to 100 users): instant, no
   review. Add yourself, install via the TestFlight app on iPhone and iPad,
   run the smoke test.
4. **External testers** (optional, up to 10,000): requires a one-time beta
   review (~1 day).

## 3.5 Submit for review

1. App Store Connect → App Store tab → the 1.0 version → select the build.
2. Release option: **Manually release** (recommended for 1.0 — you choose
   the moment after approval).
3. Run through `STORE_REVIEW.md` one last time.
4. **Submit for Review.** Typical turnaround 24–48h.
5. On approval: press Release. On rejection: follow the "If rejected"
   protocol in `STORE_REVIEW.md`.

---

# Part 4 — After both are live

1. Set the release date in `CHANGELOG.md`'s 1.0.0 entry.
2. `git tag v1.0.0` and push the tag.
3. Verify both store pages (metadata, screenshots, working install).
4. Archive the symbol files for this build if not already done
   (`RELEASE_BUILD.md` §Symbol files).
5. Future updates are much smaller: bump version, build, upload to the same
   tracks, short review, done — `RELEASE_CHECKLIST.md` covers it.

## Common first-timer pitfalls

- **Play:** forgetting the 14-day closed test requirement and being blocked
  from production at the last minute — start the clock early.
- **Play:** uploading an APK instead of an AAB (production requires AAB).
- **Apple:** screenshots with the wrong resolution are rejected at upload —
  take them on the exact simulators named in §1.4.
- **Both:** privacy answers that don't match the policy text. Cratewise's
  are aligned (nothing collected) — keep them aligned if the app changes.
- **Both:** version/build number reuse. Every upload needs a higher build
  number (`pubspec.yaml` `+N`).
