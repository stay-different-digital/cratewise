# Phase 20: CI lokaal, GitHub Actions alleen bij een major release (november 2026)

Aangemaakt: 2026-11-18

Doel: GitHub Actions-minuten besparen. De repo is privé, dus elke run gaat van Freds tegoed af, en de macOS-job telt 10× zo zwaar als Linux. Alles wat CI controleert, draait voortaan lokaal met één script. GitHub Actions draait de Flutter-pipeline alleen nog bij een major release en als iemand hem handmatig start. Nummering loopt door vanaf US-167.

## Overzicht

| Story | Titel | Prio | SP | Hangt af van |
|---|---|---|---|---|
| US-168 | Lokaal CI-script `tool/ci_local.sh` met dezelfde stappen als de pipeline | High | 2 | — |
| US-169 | Flutter CI op GitHub alleen bij een major-release-tag of handmatige start | High | 1 | US-168 |
| US-170 | Projectdocumentatie bijwerken voor lokale CI en releases zonder stores | Medium | 2 | US-168, US-169 |

Totaal: 5 SP. Volgorde: US-168 → US-169 → US-170.

## Besluiten

**Van Fred (2026-11-18):**
- CI draait lokaal. GitHub Actions draait de Flutter-pipeline alleen bij een major release (tag `vX.0.0`) en via een handmatige start.
- Deploy Pages blijft zoals het is: die draait alleen als `site/`, `CHANGELOG.md` of `README.md` verandert, en is nodig om de site bij te werken.

**Open, voorstel tot Fred beslist:**
- De iOS-job (macOS) bij een major release houden. Een major release komt zelden voor, dus de kosten blijven laag, en het is de enige controle op een schone machine.

---

### US-168: Lokaal CI-script met dezelfde stappen als de pipeline

**Priority: High · 2 SP**

> Als ontwikkelaar,
> wil ik de hele CI-controle met één commando op mijn Mac draaien,
> zodat ik geen GitHub Actions-minuten nodig heb voor de dagelijkse controle.

**Context:**
`.github/workflows/flutter-ci.yml` doet nu bij elke push: format-check, `flutter analyze`, `flutter test`, release-APK bouwen, controleren dat geen plugin de Kotlin Gradle Plugin (KGP) toepast, en een iOS-debugbuild op macOS. Alles daarvan kan ook op Freds Mac. Hulpmiddel dat er al is: `tool/run_ios_simulator.sh`.

**Acceptance criteria:**
- `tool/ci_local.sh` doet dezelfde stappen als `flutter-ci.yml`: format-check, analyze, alle tests, release-APK met KGP-check, iOS-debugbuild (`--no-codesign`).
- Het script stopt bij de eerste fout met een exitcode ≠ 0 en zegt welke stap faalde.
- Met een optie (bijvoorbeeld `--skip-ios`) kan de iOS-build worden overgeslagen.
- Het script gebruikt de JDK van Android Studio als `JAVA_HOME` niet gezet is.
- Het script gebruikt geen tokens of `.env`.
- Gecontroleerd: een groene run en een run die faalt op een bewust slecht geformatteerd bestand (daarna teruggedraaid).

---

### US-169: Flutter CI op GitHub alleen bij een major release of handmatig

**Priority: High · 1 SP**

> Als eigenaar van de repo,
> wil ik dat de Flutter-pipeline op GitHub alleen bij een major release draait,
> zodat gewone pushes en PR's geen minuten meer kosten.

**Context:**
`flutter-ci.yml` start nu bij elke push en PR naar `main`, `master` en `develop`. `deploy-pages.yml` blijft ongewijzigd.

**Acceptance criteria:**
- `flutter-ci.yml` start alleen bij een tag die op een major release past (`v*.0.0`) en via `workflow_dispatch`. Niet meer bij `push` naar branches of bij `pull_request`.
- Het buildnummer in de workflow komt niet meer uit `github.run_number`, maar uit `pubspec.yaml`. Zo komt de APK uit CI overeen met de lokale build.
- De jobs en stappen blijven verder gelijk, ook de strikte KGP-check.
- Gecontroleerd: een push naar master start geen Flutter CI-run. Eén handmatige start (`gh workflow run`) is groen.

---

### US-170: Projectdocumentatie bijwerken

**Priority: Medium · 2 SP**

> Als ontwikkelaar (en als Claude in een volgende sessie),
> wil ik dat de documentatie klopt met hoe het project nu werkt,
> zodat niemand stappen volgt die niet meer gelden.

**Context:**
Sinds 2026-11-16 gaat er niets meer naar App Store of Google Play, en na US-168/169 draait CI lokaal. Documenten die CI, stores of de oude werkwijze noemen: `README.md`, `CLAUDE.md`, `docs/workflow/STORY_CHECKLIST.md`, `docs/architecture/ADR-0003-versioning-scheme.md` (buildnummers), `docs/release/STORE_PUBLISHING_GUIDE.md`, `docs/store/STORE_LISTINGS.md`, `docs/product/ROADMAP_V2.md`.

**Acceptance criteria:**
- `STORY_CHECKLIST.md` laat `tool/ci_local.sh` draaien vóór de code-commit, in plaats van losse `flutter analyze`/`flutter test`-stappen.
- `README.md` heeft een korte sectie "Ontwikkelen en testen": lokaal CI-script, upgrade-test, live Discogs-test (zonder token in de tekst) en hoe je een release-APK bouwt.
- `CLAUDE.md` noemt het lokale CI-script en dat GitHub Actions alleen bij een major release draait.
- Een release-instructie (in `README.md` of een nieuw `docs/release/RELEASE.md`) beschrijft: versie ophogen, CHANGELOG, tag, push, APK bouwen en controleren (versionCode en ondertekening), en bij een major release de GitHub-run.
- Store-documenten (`STORE_PUBLISHING_GUIDE.md`, `STORE_LISTINGS.md`) krijgen bovenaan de melding dat er sinds 2026-11-16 niet meer naar de stores wordt uitgebracht. Ze worden niet verwijderd.
- ADR-0003 krijgt een aanvulling over buildnummers zonder stores en zonder `github.run_number`.
- Geen verwijzingen meer naar CI bij elke push.
