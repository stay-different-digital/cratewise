# Store Review — Pre-submission Checklist

Known rejection traps checked before submitting Cratewise 1.0 for review,
plus the reviewer notes to paste into App Store Connect. Listing copy lives
in `../store/STORE_LISTINGS.md`; build steps in `RELEASE_CHECKLIST.md`.

## Both stores

- [ ] **App works without an account.** Launch with no Discogs token: search,
  release detail, collection, wantlist and statistics must all function.
  Apple guideline 5.1.1 forbids requiring registration for non-account
  features — Cratewise's token is genuinely optional, verify it stays that
  way in the submitted build.
- [ ] **Privacy policy URL is live** and its content matches the Play data
  safety form and the App Store nutrition labels exactly (all three say:
  nothing collected).
- [ ] **No unused permissions.** Since 1.1.0 the app asks for no camera
  access on either platform; the release APK requests only `INTERNET` and
  `Info.plist` has no `NSCameraUsageDescription`.
- [ ] **Metadata is accurate.** Screenshots show the real app; the
  description claims no feature that doesn't exist. Since 1.2.0 automatic
  sync exists but is opt-in and runs only while the app is open (launch and
  return to foreground) — don't describe it as background sync.
- [ ] **Support contact works.** The listed email is monitored
  (hellowerecratewise@gmail.com).
- [ ] **No placeholder content** anywhere in the build (lorem ipsum, TODO
  screens, "coming soon" tiles).
- [ ] **Version/build matches** the changelog entry being shipped.

## Google Play specifics

- [ ] Data safety form filed per `../store/STORE_LISTINGS.md` ("No data
  collected or shared").
- [ ] Target API level meets Play's current requirement (Flutter's
  `targetSdk` tracks this; verify no Play Console warning).
- [ ] Content rating questionnaire completed (no user-generated content
  visible to others, no ads).
- [ ] App signed with the upload key; Play App Signing enrolled.

## App Store specifics

- [ ] Export compliance pre-answered (`ITSAppUsesNonExemptEncryption=NO`).
- [ ] iPad screenshots show real iPad layouts (review tests on iPad; the
  app must not letterbox an iPhone UI).
- [ ] Sign-in not required → no demo account needed, but reviewer notes
  (below) pre-empt the question.

### App Review notes (paste into App Store Connect)

> Cratewise is a vinyl record collection app. All data is stored locally on
> the device; no account or sign-in is required for any feature.
>
> Optionally, users can connect their own Discogs account (discogs.com, the
> largest music database/marketplace) by pasting a personal access token in
> Settings. This only adds import/export of their Discogs collection. You do
> not need a token to review the app: search, collection, wantlist and
> statistics all work without it.
> Without a token, Discogs-account features simply show a
> message pointing to Settings.
>
> The app requests no camera, location or other sensitive permissions and
> collects no data (see privacy policy).

## If rejected

1. Read the **exact guideline number** cited in the rejection; respond to
   that, not to a guess.
2. Fix and resubmit, or — if the rejection misunderstands the app — reply in
   the Resolution Center / Play Console with a factual explanation before
   changing anything.
3. Never resubmit an unchanged binary without a reply; it auto-rejects and
   burns review time.
4. Record the rejection and outcome in this file for the next submission.
