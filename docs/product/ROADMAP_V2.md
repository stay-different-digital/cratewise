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

- Collection statistics and insights (US-115).
- Advanced filters (US-116) and saved searches (US-117).
- Full Discogs OAuth login flow (US-118, with backend proxy if secrets require it).
- Two-way sync improvements between local data and Discogs (US-72, US-119).
- Duplicate detection (US-120).
- DJ fields: BPM, key, energy, gig crates (US-121).
- iPad-specific power features: drag and drop, keyboard shortcuts, multitasking (US-122).
- Easter eggs: shake on Search → Rick Roll (US-109), shake on Collection → random record (US-110), shake on Wishlist → random record (US-111).

## Phase 15: Meertaligheid (i18n)

Goal:

- De app standaard in het Engels aanbieden en ondersteuning voor vijf talen inbouwen: Engels, Duits, Frans, Spaans en Nederlands.
- Gebruikers kunnen de taal handmatig overschrijven via de instellingen.

Package-keuze: `flutter_localizations` (Flutter SDK, geen nieuwe dependency) + `intl` (al aanwezig) + `flutter gen-l10n`.

Deliverables:

- US-112: i18n-infrastructuur opzetten (ARB-bestanden, `l10n.yaml`, `flutter gen-l10n`, `MaterialApp` configureren).
- US-113: Kernsschermen vertalen naar alle vijf talen + widget-tests bijwerken.
- US-114: Taalvoorkeur-instelling in het instellingenscherm met directe omschakeling en persistentie.

Done criteria:

- Een gebruiker met een Duits apparaat ziet de app volledig in het Duits.
- Een gebruiker kan de taal overschrijven in de instellingen zonder app-herstart.
- Alle kernsschermen zijn vertaald; geen hardcoded Engelse strings meer zichtbaar voor eindgebruikers.
- `flutter analyze` geeft 0 issues en `flutter test` blijft groen.

## Phase 18: Cratewise op de nieuwste Flutter

Goal: Cratewise draait schoon en toekomstbestendig op Flutter 3.50. De basis-upgrade (material_ui, go_router 18, Gradle 9.5/AGP 9.3, JDK 21) zit in 1.2.1; deze fase ruimt plugins met de losse Kotlin-plugin, verouderde majors en de eol-SQLite-bibliotheek op.

Deliverables: US-150 t/m US-158, zie `docs/user-stories/phase-18-flutter-350-stories.md`.

Done criteria: geen KGP-waarschuwing in de Android-build, `flutter pub outdated` zonder onverklaarde achterstand, CI groen met release-build, live Discogs-test groen op Android en iOS.

## Phase 19: Filteren en sorteren gelijk op Zoeken, Collectie en Verlanglijst

Goal: gebruikersfeedback. Eén filterknop per lijstscherm, met in de bottom sheet bovenaan de sortering (Zoeken: Relevantie, Nieuwste eerst, Oudste eerst op datum toegevoegd aan Discogs; Collectie/Verlanglijst: Nieuwste/Oudste eerst op datum toegevoegd aan de eigen collectie) en daaronder de filters. DJ-velden BPM, Key, Energy en gig crates verdwijnen.

Deliverables: US-161 t/m US-166, zie `docs/user-stories/phase-19-unified-filter-sort-stories.md`.

Done criteria: op Zoeken, Collectie en Verlanglijst staat geen los sorteer- of chipelement meer; de sorteersectie is één gedeelde widget; alle tests en de live Discogs-test groen.

