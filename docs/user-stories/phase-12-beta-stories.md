# Phase 12 Beta — User Stories

Derived from the Phase 12 deliverables in `docs/product/ROADMAP_V2.md`.
**Story points** are estimates for a single developer.
Numbering continues from the Phase 11 stories (US-56 … US-62).

Steps marked **[Fred]** need store accounts, signing credentials, or physical
devices. Everything else lives in the repo.

---

### US-63: Beta builds are live on the Play internal track and TestFlight

**3 SP**

> As a beta tester,
> I want to install Cratewise through Google Play internal testing or TestFlight,
> so that I get real store-delivered builds with painless updates.

**Acceptance criteria:**
- The first beta build is produced exactly per `docs/release/RELEASE_CHECKLIST.md` (version bumped to `1.0.0+2` or higher, signed, obfuscated, symbols archived).
- **[Fred]** The `.aab` is uploaded to the Play Console **internal testing** track and at least one tester (Fred) can install it from the Play Store.
- **[Fred]** The `.ipa` is uploaded and assigned to a **TestFlight** group; it installs on iPhone and iPad.
- Release notes for the build come from `CHANGELOG.md`.
- The installed beta passes the smoke test from the release checklist on at least one physical device per platform.
- Tester onboarding instructions exist (covered by US-66's tester guide).

---

### US-64: Testers can send feedback from inside the app

**2 SP**

> As a beta tester who just hit a problem,
> I want a "Send feedback" action in Settings that opens a pre-addressed email,
> so that reporting takes seconds and automatically includes my app version and platform.

**Acceptance criteria:**
- Settings shows a "Send feedback" tile that opens the system mail composer via a `mailto:` link addressed to the feedback address.
- The subject and body are prefilled with the app version+build (read at runtime, not hardcoded) and the platform/OS, leaving space for the tester's description.
- No personal data beyond what the tester types is included — no identifiers, no logs, no token. The email is composed and sent entirely by the user's own mail app.
- If no mail app is available, a snackbar shows the feedback address so the tester can reach it another way.
- Works on Android, iPhone, and iPad (uses the same `url_launcher` external-launch pattern as the token help link).
- Widget tests cover: tile present, launched URI is a `mailto:` containing the address/subject/version, and the fallback snackbar when launching fails.

---

### US-65: Beta feedback has a defined channel and triage process

**1 SP**

> As the developer running the beta,
> I want one documented intake channel and a triage routine,
> so that no report is lost and every report ends up rejected, fixed, or scheduled.

**Acceptance criteria:**
- `docs/beta/FEEDBACK_TRIAGE.md` names the intake channels (in-app feedback email from US-64, TestFlight feedback, Play Console reports, direct messages) and states that everything is normalised into GitHub issues on `itris/Crate`.
- A severity scale (S1 blocker → S4 polish) with response expectations is defined.
- A triage cadence is defined (e.g. within 48h of receipt: reproduce, label, decide).
- The path from report → user story is specified: confirmed issues become `US-XX` stories in `docs/user-stories/` following the existing template, bugs reference the originating report.
- A feedback report template is included (device, OS, app version+build, steps, expected/actual) matching what US-66 asks testers to provide.

---

### US-66: Beta testers have a test plan and reporting guide

**1 SP**

> As a beta tester,
> I want a short guide telling me what to try and how to report problems,
> so that my testing time produces actionable findings instead of "it works I guess".

**Acceptance criteria:**
- `docs/beta/BETA_TEST_PLAN.md` contains a tester-facing guide: installing via Play internal testing / TestFlight, connecting a Discogs token (with a warning to use their own account), and a prioritised list of scenarios to exercise (search, scan, collection/wishlist CRUD, import/export, offline behaviour, iPad split view).
- Scenarios are phrased as user goals ("scan a record in a shop with bad lighting"), not internal QA steps.
- The reporting section tells testers exactly what to include and points at the in-app "Send feedback" button (US-64).
- Known limitations at beta start are listed honestly (e.g. English-only UI, no Discogs OAuth — token setup required).
- The guide fits on roughly two pages; testers will not read more.

---

### US-67: Crash reports can be symbolicated and turned into stories

**1 SP**

> As the developer receiving a crash report from an obfuscated beta build,
> I want a documented path from raw report to readable stack trace to follow-up story,
> so that beta crashes actually get fixed instead of filed as "unreadable".

**Acceptance criteria:**
- `docs/beta/CRASH_FOLLOWUP.md` documents where crash reports arrive (TestFlight/Xcode Organizer, Play Console "Android vitals", tester emails) given that the app deliberately ships **without** a crash-reporting SDK.
- The symbolication procedure is documented: matching the report to the right `symbols-X.Y.Z+N-<platform>.zip` archive and running `flutter symbolize -i <stack> -d <symbols file>`.
- A crash follow-up story template is included (version+build, device/OS, symbolicated trace, reproduction status, severity per US-65).
- The doc cross-references `RELEASE_BUILD.md`'s symbol-archiving step as the hard prerequisite.
- The decision to stay SDK-free for beta is recorded with its trade-off (privacy promise upheld; crashes only visible when testers opt in to platform sharing or report manually), and the revisit point (post-beta) is named.

---

### US-73: Large Discogs imports complete quickly and show progress

**S2 · 3 SP**

> As a user importing a real-world collection (thousands of records),
> I want the import to finish in seconds and show its progress,
> so that it visibly completes instead of appearing to hang forever.

**Acceptance criteria:**
- Importing 2,800 rows completes in seconds, not minutes: all per-row database writes (collection/wishlist items **and** import-history row results) happen inside a single transaction or batch instead of one implicit transaction per insert.
- The Importing state shows per-item progress ("Importing item N of M…", same pattern as the export progress from US-45) instead of a static spinner.
- An interrupted import no longer leaves a partially-saved state that the user can't distinguish from success: either the transaction makes it all-or-nothing, or the job record correctly reflects the interruption.
- Applies to both collection and wishlist Discogs imports (identical code structure), and the CSV imports if they share the per-insert pattern.
- A test demonstrates the batching (e.g. repository receives a batched call / runs inside a transaction) and existing import tests still pass.
- **[Fred]** Re-test the 2,800-record import on the physical device: completion screen appears, counts correct.

**Found during:** Beta QA (2026-06-12): importing a 2,800-record Discogs
collection never showed the "Import complete" screen; importing afterwards
(1 new + 2,618 already linked) completed and showed it.

**Investigation notes:**
- `ExecuteCollectionImportUseCase` does 2 awaited inserts per row
  (~5,600 sequential implicit transactions for 2,800 rows); no
  `transaction()`/`batch()` anywhere in the import path; each insert pays a
  disk sync.
- The tester's screenshot ("Skipped 2618, Added 1") proves the first run
  partially persisted before being abandoned — items were saved as synced,
  so the rerun skipped them as "Already linked".
- The Importing UI (`_ImportingBody`) is a static spinner with no progress;
  exports already have the per-item progress pattern to copy (US-45).
