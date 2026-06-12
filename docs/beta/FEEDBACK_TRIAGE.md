# Beta Feedback — Channels and Triage

How beta feedback comes in, and what happens to every report.

## Intake channels

| Channel | Arrives as |
|---|---|
| In-app **Send feedback** button (Settings) | Email to hellowerecratewise@gmail.com with version+platform prefilled |
| TestFlight feedback / crash sharing | App Store Connect → TestFlight → Feedback |
| Play Console | Android vitals + reviews on the internal track |
| Direct messages from testers | Whatever channel they used |

Everything, regardless of channel, is normalised into a **GitHub issue on
`itris/Crate`** during triage. The issue is the single source of truth; the
original email/report is quoted or summarised in it.

## Severity scale

| Level | Meaning | Response |
|---|---|---|
| **S1** | Blocker: crash, data loss, can't install or launch | Fix immediately; new beta build as soon as fixed |
| **S2** | Major: core flow broken (search, scan, add, import/export) with no workaround | Fix before the next planned beta build |
| **S3** | Minor: bug with a workaround, visual defect, confusing copy | Schedule into the backlog as a story |
| **S4** | Polish/idea: nice-to-have, feature request | Backlog; candidate for Phase 14 (growth) |

## Triage routine

Within **48 hours** of a report arriving:

1. **Reproduce** — on simulator/emulator first, physical device if needed.
   Record reproduced / not-reproduced / need-more-info on the issue.
2. **Label** — severity (`S1`–`S4`), platform (`android`/`ios`/`ipad`), area
   (`search`, `scan`, `collection`, `wishlist`, `import-export`, `settings`).
3. **Decide** — one of:
   - **Fix now** (S1/S2) — becomes a user story immediately.
   - **Schedule** (S3/S4) — story written, sits in the backlog.
   - **Reject** — works as intended / out of scope; reply to the tester with
     the reasoning, close the issue.
4. **Reply** to the tester (if reachable) so they know the report landed.

## From report to user story

Confirmed issues become numbered stories in
`docs/user-stories/` (continuing the `US-XX` sequence), using the same
template as the Phase 10 QA findings: story sentence, acceptance criteria,
**Found during** (beta report + reporter + build), investigation notes.
Crash reports follow the extra steps in `CRASH_FOLLOWUP.md` first.

## Report template

What a complete report contains (the in-app feedback email prefills the
starred fields; `BETA_TEST_PLAN.md` asks testers for the rest):

```
App version+build:*   e.g. 1.0.0+2
Device:               e.g. Pixel 8 / iPhone 15 Pro / iPad Air 11"
OS version:*          e.g. Android 15 / iOS 26
Steps taken:          1. … 2. … 3. …
Expected:
Actual:               (screenshots welcome)
```
