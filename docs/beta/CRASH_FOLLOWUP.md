# Crash and Issue Follow-up

How a crash in an obfuscated beta build becomes a readable stack trace and a
scheduled fix.

## Why there is no crash-reporting SDK

Cratewise deliberately ships without Crashlytics/Sentry/etc. The privacy
policy promises "no analytics, no crash reporting", and beta keeps that
promise. Trade-off: crashes are only visible when (a) the tester opted in to
platform crash sharing, or (b) they report it manually. **Revisit after the
first beta cycle** — if crash volume is unmanageable this way, adding an
opt-in crash reporter is a Phase 14 decision that also requires updating the
privacy policy and store privacy declarations first.

## Where crash reports arrive

- **iOS:** App Store Connect → TestFlight → Crashes, and Xcode → Organizer →
  Crashes (testers who share analytics). TestFlight testers can also attach
  feedback directly from the crash dialog.
- **Android:** Play Console → Quality → Android vitals → Crashes & ANRs
  (testers who opted in).
- **Manual:** testers describing a crash via the in-app feedback email.

## Symbolicating an obfuscated stack trace

Release builds use `--obfuscate`, so raw Dart stack traces are unreadable.
Prerequisite: the symbol archive for that exact build
(`symbols-X.Y.Z+N-<platform>.zip`), saved during the release per
`../release/RELEASE_BUILD.md`. **No symbols, no symbolication** — this is
why archiving them is a checklist step, not a suggestion.

1. Identify the app version+build from the crash report.
2. Unzip the matching symbols archive.
3. Save the raw stack trace to a file and run:

   ```sh
   flutter symbolize -i stack.txt -d app.android-arm64.symbols   # Android
   flutter symbolize -i stack.txt -d app.ios-arm64.symbols       # iOS
   ```

4. Pick the symbols file matching the device architecture (arm64 for all
   modern phones/iPads).

Native (non-Dart) iOS crashes from TestFlight are symbolicated automatically
by Apple when the dSYMs were uploaded with the build (Xcode Organizer does
this by default).

## Crash follow-up story template

Every reproduced or recurring crash becomes a `US-XX` story in
`docs/user-stories/` (severity S1 per `FEEDBACK_TRIAGE.md`):

```markdown
### US-XX: <crash one-liner, e.g. "App crashes when scanning with camera permission revoked mid-session">

**S1 · <SP>**

> As a user <doing what>,
> I want the app not to crash,
> so that <impact>.

**Acceptance criteria:**
- The crash no longer reproduces with the original steps.
- A regression test covers the crashing path.
- <root-cause-specific criteria>

**Found during:** Beta <build, e.g. 1.0.0+2>, <device/OS>, <channel: TestFlight/vitals/tester email>.

**Investigation notes:**
- Symbolicated trace (top frames): …
- Reproduction status: reproduced / not reproduced (N attempts) / intermittent
```
