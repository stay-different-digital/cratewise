# Roadmap V2: Cratewise

Status date: 2026-06-11

This roadmap replaces the phase plan in `ROADMAP.md` for all work after Phase 8.
The original roadmap stays as a historical record of the MVP plan.

## Platform scope

In scope:

- Android
- iPhone
- iPad

Out of scope:

- Windows desktop
- macOS desktop
- Web

## Where the project stands today

Done (Phases 0 through 8Y):

- Flutter foundation for Android and iOS/iPadOS with clean architecture layers.
- Discogs API v2 client (`api.discogs.com`, versioned Accept header, User-Agent, pagination, rate-limit handling).
- Token mode authentication with secure storage, masking, and removal.
- Release search, barcode search, and release detail.
- Local collection and wantlist with offline-first Drift database.
- Discogs collection and wantlist import with progress, history, pagination, and undo.
- CSV import and export.
- Search polish: debounce, in-flight cancellation (US-51), local result caching (US-52).
- Around 2,256 tests across 89 test files.

Not done yet:

- No beta or store release. Everything in the changelog is still "Unreleased".
- Stale Windows references remain in several agent, skill, and prompt files.
- No privacy policy or store listing material.

## Phase 9: Workspace and docs consistency

Status: done (2026-06-11, handled manually — see `CHANGELOG.md`).

Goal:

- Make every config and doc file match the Android + iPhone + iPad scope.

Deliverables:

- Remove Windows references from `.github/agents/` (product planner, QA reviewer, UI designer).
- Remove Windows references from `.github/skills/` (flutter-feature, flutter-testing, airbnb-ui-flutter, release-checklist, secure-token-storage).
- Remove Windows references from `.github/prompts/review-code.prompt.md`.
- Add the base URL `https://api.discogs.com` and the v2 Accept header to `docs/api/DISCOGS_API.md`.
- Verify the `tools:` names in agent files against current VS Code agent mode docs.
- Decide whether `.github/skills/` content should move to `.github/instructions/*.instructions.md` so it loads automatically.

Done criteria:

- A repo-wide search for "Windows" returns no scope-related hits.
- Agent mode loads all agents, prompts, and instructions without warnings.

## Phase 10: Device validation

Status: in progress (2026-06-11) — QA checklist prepared at
`docs/qa/PHASE_10_DEVICE_VALIDATION.md`; test baseline confirmed green
(2256/2256). Awaiting manual QA passes on physical Android phone, iPhone,
and iPad.

Goal:

- Prove the app works well on real hardware for all three targets.

Deliverables:

- Manual QA pass on a physical Android phone.
- Manual QA pass on a physical iPhone.
- Manual QA pass on a physical iPad, including landscape and split view.
- Barcode scanning verified on all three device types.
- iPad layout review: navigation rail, two-pane layouts where useful, text scaling.
- Fix list from QA turned into user stories.

Done criteria:

- QA checklist completed per device with no open blocking issues.

## Phase 11: Release readiness

Goal:

- Prepare everything stores require before a beta.

Deliverables:

- App icons and splash screens final for Android and iOS.
- Privacy policy text and hosting.
- Play Console listing (screenshots, description, data safety form).
- App Store Connect listing (screenshots for iPhone and iPad, privacy nutrition labels).
- Versioning and release build configuration (signing, obfuscation choices).
- Release checklist skill updated for Android + iOS instead of Android + Windows.

Done criteria:

- A signed release build installs and runs on Android and iOS.
- All store metadata is drafted and reviewed.

## Phase 12: Beta

Goal:

- Test with real users on both platforms.

Deliverables:

- Play Console internal/closed testing track build.
- TestFlight build for iPhone and iPad.
- Feedback channel and triage process.
- Crash and issue follow-up stories.

Done criteria:

- At least one full beta cycle completed with feedback processed.

## Phase 13: Version 1.0

Goal:

- Ship a stable 1.0 to both stores.

Deliverables:

- Final branding pass.
- Store review submissions for Google Play and the App Store.
- `CHANGELOG.md` consolidated into a 1.0.0 release entry.
- Tagged release in git.

Done criteria:

- Cratewise 1.0 is live in both stores.

## Phase 14: Growth (post-1.0)

Possible features, to be prioritised after 1.0:

- Collection statistics and insights.
- Advanced filters and saved searches.
- Full Discogs OAuth login flow (with backend proxy if secrets require it).
- Two-way sync improvements between local data and Discogs.
- Duplicate detection.
- DJ fields: BPM, key, energy, gig crates.
- iPad-specific power features: drag and drop, keyboard shortcuts, multitasking.
