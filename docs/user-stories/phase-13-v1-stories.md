# Phase 13 Version 1.0 — User Stories

Derived from the Phase 13 deliverables in `docs/product/ROADMAP_V2.md`.
**Story points** are estimates for a single developer.
Numbering continues from the Phase 12 stories (US-63 … US-67).

Steps marked **[Fred]** need store accounts, signing credentials, or physical
devices.

---

### US-68: Final branding pass with an About section

**2 SP**

> As a user (and a store reviewer) checking who made this app,
> I want consistent branding everywhere and an About section in Settings,
> so that the app looks finished and its version and licences are inspectable.

**Acceptance criteria:**
- The app presents itself as "Cratewise" consistently: Android `android:label`, iOS `CFBundleDisplayName`/`CFBundleName`, `MaterialApp.title`, store listings (verified, not assumed).
- Launcher icon and splash are the final brand assets on both platforms (carried over from Phase 10/11 work; re-verified, not regenerated).
- Settings gains an "About" tile showing the app name and the runtime version+build, opening Flutter's standard about dialog with a "View licences" path for open-source attribution.
- The version shown is read at runtime (`package_info_plus`), never hardcoded.
- Widget tests cover: About tile present, dialog opens with the version, licences page reachable.
- **[Fred]** Visual spot-check on physical devices during the release smoke test.

---

### US-69: CHANGELOG consolidated into a 1.0.0 release entry

**1 SP**

> As a user or tester reading the release notes,
> I want one readable 1.0.0 entry describing what Cratewise does,
> so that the changelog tells the product story instead of replaying 134 development increments.

**Acceptance criteria:**
- `CHANGELOG.md` has a single `[1.0.0]` entry (dated "Unreleased" until the actual release; the release checklist sets the date) that summarises the full feature set in user-facing language, grouped per Keep a Changelog.
- The 134 `[Unreleased — …]` development entries are moved intact to `docs/archive/CHANGELOG_DEV_HISTORY.md` — history preserved, not deleted.
- The `[0.0.2]` and `[0.0.1]` entries remain in `CHANGELOG.md` below the 1.0.0 entry.
- The consolidated entry is suitable as the source for store "What's new" text for the 1.0 submission.
- A pointer to the archived development history is included in `CHANGELOG.md`.

---

### US-70: Store review submissions are prepared against the review guidelines

**2 SP**

> As the developer submitting Cratewise for store review,
> I want the known rejection traps checked off in advance,
> so that the 1.0 submission passes review on the first attempt.

**Acceptance criteria:**
- `docs/release/STORE_REVIEW.md` documents a pre-submission checklist for both stores covering the rejection reasons that apply to this app: camera permission purpose strings, account-optional design (app must demonstrably work without a Discogs token), token setup instructions for the reviewer, privacy policy URL live and matching the data-safety/nutrition answers, metadata accuracy (no claims of features that don't exist), and working support contact.
- App Review notes text is drafted for App Store Connect: explains what Discogs is, that an account is optional, and how the reviewer can test scan/search without credentials.
- The doc states what to do on rejection: read the exact guideline cited, fix or appeal, never resubmit unchanged.
- **[Fred]** Both submissions filed (Google Play production review, App Store review) using this checklist.

---

### US-71: Cratewise 1.0.0 is tagged and live in both stores

**1 SP**

> As the developer shipping 1.0,
> I want the release tagged in git and live in both stores,
> so that Phase 13's done criterion — Cratewise 1.0 in both stores — is met and reproducible.

**Acceptance criteria:**
- The 1.0.0 build is produced via `docs/release/RELEASE_CHECKLIST.md` (signed, obfuscated, symbols archived).
- `CHANGELOG.md`'s 1.0.0 entry gets its release date.
- **[Fred]** `git tag v1.0.0` on the released commit (push when ready).
- **[Fred]** Google Play: promoted from internal track to production after review approval.
- **[Fred]** App Store: released after review approval.
- **[Fred]** Both store pages verified live with correct metadata and screenshots.
