# Phase 20: CI lokaal, GitHub Actions alleen bij een major release (november 2026)

Aangemaakt: 2026-11-18

Doel: GitHub Actions-minuten besparen. De repo is privé, dus elke run gaat van Freds tegoed af, en de macOS-job telt 10× zo zwaar als Linux. Alles wat CI controleert, draait voortaan lokaal met één script. GitHub Actions draait de Flutter-pipeline alleen nog bij een major release en als iemand hem handmatig start. Nummering loopt door vanaf US-167.

## Overzicht

| Story | Titel | Prio | SP | Hangt af van |
|---|---|---|---|---|
| US-168 | Lokaal CI-script `tool/ci_local.sh` met dezelfde stappen als de pipeline | High | 2 | — |
| US-169 | Flutter CI op GitHub alleen bij een major-release-tag of handmatige start | High | 1 | US-168 |
| US-170 | Projectdocumentatie bijwerken voor lokale CI en releases zonder stores | Medium | 2 | US-168, US-169 |
| US-171 | Release-APK als GitHub Release publiceren | Medium | 2 | US-168 |
| US-172 | Repo openbaar maken: voorbereiden en goed instellen | Medium | 3 | — |

Totaal: 10 SP. Volgorde: US-172 eerst beslissen (zie hieronder), dan US-168 → US-169 → US-171 → US-170 (documentatie als laatste, zodat die alles beschrijft).

## Besluiten

**Van Fred (2026-11-18):**
- CI draait lokaal. GitHub Actions draait de Flutter-pipeline alleen bij een major release (tag `vX.0.0`) en via een handmatige start.
- Deploy Pages blijft zoals het is: die draait alleen als `site/`, `CHANGELOG.md` of `README.md` verandert, en is nodig om de site bij te werken.

- **iOS-job blijft (2026-11-18)**, maar start alleen handmatig, zodat Fred bepaalt wanneer er macOS-minuten worden gebruikt (zie US-169).

**Open, voorstel tot Fred beslist:**
- **Openbaar maken verandert US-169.** Voor openbare repo's is GitHub Actions op de standaard runners gratis, ook macOS. Wordt de repo openbaar (US-172), dan kost CI bij elke push geen tegoed meer. Het lokale script (US-168) blijft nuttig, maar CI bij elke push kan dan terug. Beslis US-172 daarom vóór US-169.
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
- De iOS-job (macOS) draait alleen bij een handmatige start, via een keuze in `workflow_dispatch` (bijvoorbeeld `ios: true/false`, standaard uit). Bij een major-tag draait alleen de Android-job; iOS start Fred zelf.
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

---

### US-171: Release-APK als GitHub Release publiceren

**Priority: Medium · 2 SP**

> Als eigenaar,
> wil ik elke release-APK als GitHub Release bij de tag zetten,
> zodat elke versie op één vaste plek te downloaden is, en niet alleen op mijn bureaublad.

**Context (uitgezocht 2026-11-18):**
- Het kan. Een GitHub Release hoort bij een tag (`v1.4.2` enz. bestaan al) en kan bestanden bevatten tot 2 GB per stuk; de APK is ~70 MB.
- Lokaal, zonder Actions-minuten: `gh release create v1.4.2 Cratewise-1.4.2.apk --title "Cratewise 1.4.2" --notes-file <notities>`. De notities zijn de sectie van die versie uit `CHANGELOG.md`.
- Ondertekening: de APK wordt lokaal met de release-sleutel ondertekend. De sleutel komt niet op GitHub, dus releases uit CI zouden niet met dezelfde sleutel ondertekend zijn en niet als update installeren. Daarom: altijd lokaal bouwen en uploaden.
- Zichtbaarheid: bij een privé-repo kan alleen wie toegang heeft de release downloaden. Na US-172 is hij voor iedereen te downloaden. Dan installeert iedereen de app via "onbekende bronnen". Dat is een bewuste keuze (de app gebruikt alleen het Discogs-token van de gebruiker zelf).

**Acceptance criteria:**
- `tool/release.sh <versie>` (of een stap in de release-instructie) haalt de CHANGELOG-sectie op, controleert de APK (versionName/versionCode gelijk aan `pubspec.yaml`, ondertekend met de release-sleutel via `apksigner`) en maakt de GitHub Release met de APK als `Cratewise-<versie>.apk`.
- Het script weigert als de tag niet op origin staat of als er al een release voor die tag bestaat.
- Een SHA-256-checksum van de APK staat in de releasenotities.
- Uitgevoerd voor de huidige versie (1.4.2); de release is zichtbaar met `gh release list`.
- Oudere tags krijgen geen release met terugwerkende kracht, tenzij Fred dat vraagt.

---

### US-172: Repo openbaar maken: voorbereiden en goed instellen

**Priority: Medium · 3 SP**

> Als eigenaar,
> wil ik de repo veilig openbaar maken,
> zodat anderen de code en releases kunnen zien zonder dat er iets vrijkomt wat privé moet blijven.

**Context (uitgezocht 2026-11-18):**
- Al gecontroleerd: het echte Discogs-test-token komt nergens in de git-geschiedenis voor. Er is nooit een keystore (`.jks`/`.keystore`), `key.properties` of `.env` gecommit; die staan in `.gitignore`.
- Openbaar maken maakt de **hele geschiedenis** zichtbaar, niet alleen de laatste versie.
- 402 commits staan op Freds persoonlijke e-mailadres. Die worden bij openbaar maken zichtbaar.
- Er is geen `LICENSE`. Zonder licentie mag niemand de code hergebruiken (alleen bekijken).
- De repo hoort bij de organisatie `stay-different-digital`; openbaar maken is een instelling van de repo (Settings → General → Danger Zone → Change visibility) en vraagt eigenaarsrechten in de organisatie.
- Openbaar maken is terug te draaien, maar wat eenmaal openbaar was, kan al gekopieerd of geïndexeerd zijn.

**Acceptance criteria:**
- **Geheimen-scan over de hele geschiedenis** met een tool (bijvoorbeeld `gitleaks detect` of `trufflehog git`), resultaat besproken met Fred. Bij een vondst: het geheim intrekken en vervangen; de geschiedenis herschrijven alleen na besluit van Fred.
- **Inhoud nagelopen** op wat niet openbaar hoort: `docs/` (store-documenten, persoonlijke notities), `.claude/`, `.forge/`, `.serena/`, `graphify-out/`, `skills-lock.json`. Wat niet openbaar hoort: verwijderen of in `.gitignore`. Besluit van Fred per map.
- **E-mailadres:** Fred kiest: zo laten, of voortaan het GitHub-noreply-adres gebruiken (`git config user.email`). De oude commits worden niet herschreven, tenzij Fred dat expliciet wil.
- **Licentie:** Fred kiest er een (bijvoorbeeld MIT, of "alle rechten voorbehouden"); `LICENSE` toegevoegd en in de README genoemd.
- **`SECURITY.md`:** hoe je een beveiligingsprobleem meldt.
- **Instellingen na openbaar maken:**
  - Secret scanning en push protection aan.
  - Dependabot-meldingen aan.
  - Branch protection op `master`: geen force-push, niet verwijderen.
  - Actions: workflows van forks alleen na goedkeuring.
  - Issues, Discussions en Wiki aan of uit volgens de keuze van Fred.
- **README** geschikt voor buitenstaanders: wat de app is, hoe je hem bouwt (eigen Discogs-token, nooit in de repo), waar de releases staan (US-171).
- **De laatste stap doet Fred zelf:** de repo op Public zetten. Daarna controleert Claude dat GitHub Pages, de tags en de releases werken.
