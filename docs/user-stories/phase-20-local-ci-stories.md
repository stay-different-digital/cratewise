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
| US-172 | Repo openbaar maken: voorbereiden en goed instellen | Medium | 3 | US-173, US-174, US-175 |
| US-173 | Commits voortaan met het GitHub-noreply-adres | High | 1 | — |
| US-174 | Oude commits herschrijven naar het noreply-adres | High | 3 | US-173 |
| US-175 | GPL-3.0-licentie toevoegen | Medium | 1 | — |
| US-176 | `CONTRIBUTING.md` herschrijven: eerst issue en akkoord, dan PR | Medium | 2 | US-168 |
| US-177 | Lege issues uitzetten; beveiligingsmeldingen naar `SECURITY.md` | Low | 1 | — |
| US-178 | PR-template aanscherpen: issuenummer verplicht | Low | 1 | US-176 |
| US-179 | Code of conduct toevoegen | Low | 1 | US-172 |

Totaal: 15 SP. Volgorde: US-173 → US-174 (blokkeert pushen, zie daar) → US-175 → US-172 → US-168 → US-169 → US-171 → US-170 (documentatie als laatste).

## Besluiten

**Van Fred (2026-11-18):**
- CI draait lokaal. GitHub Actions draait de Flutter-pipeline alleen bij een major release (tag `vX.0.0`) en via een handmatige start.
- Deploy Pages blijft zoals het is: die draait alleen als `site/`, `CHANGELOG.md` of `README.md` verandert, en is nodig om de site bij te werken.

- **Licentie: GPL-3.0 (2026-11-18)** (US-175).
- **E-mailadres (2026-11-18):** voortaan `2884813+stay-different-digital@users.noreply.github.com` (US-173), en de oude commits herschrijven vóór de repo openbaar wordt (US-174). Op GitHub staan "Keep my email addresses private" en "Block command line pushes that expose my email" aan.
- **iOS-job blijft (2026-11-18)**, maar start alleen handmatig, zodat Fred bepaalt wanneer er macOS-minuten worden gebruikt (zie US-169).

**Open, voorstel tot Fred beslist:**
- **Openbaar maken verandert US-169.** Voor openbare repo's is GitHub Actions op de standaard runners gratis, ook macOS. Wordt de repo openbaar (US-172), dan kost CI bij elke push geen tegoed meer. Het lokale script (US-168) blijft nuttig, maar CI bij elke push kan dan terug. Beslis US-172 daarom vóór US-169.
- De iOS-job (macOS) bij een major release houden. Een major release komt zelden voor, dus de kosten blijven laag, en het is de enige controle op een schone machine.

---

### US-168: Lokaal CI-script met dezelfde stappen als de pipeline

**Status: ✅ Resolved (2026-11-18)** — `tool/ci_local.sh [--skip-ios]`: dezelfde stappen als `flutter-ci.yml`, stopt bij de eerste fout met naam van de stap en exitcode 1, gebruikt de JDK van Android Studio als `JAVA_HOME` leeg is, geen tokens. Groene run in ~2 minuten (met iOS); een slecht geformatteerd testbestand faalt op "Check formatting" (daarna verwijderd).

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

**Status: ✅ Resolved (2026-11-18)** — `flutter-ci.yml` start alleen bij een tag `v[0-9]*.0.0` en via `workflow_dispatch` (input `ios`, standaard uit); iOS-job alleen bij handmatige start met `ios: true`; buildnummer uit `pubspec.yaml`. Gecontroleerd: met de workflow aan startte een push naar master geen run; handmatige run (ios=false) groen, iOS-job overgeslagen. De workflow staat weer aan.

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

**Status: ✅ Resolved (2026-11-18)** — nieuw `docs/release/RELEASE.md`; store- en oude release-documenten bovenaan als historisch gemarkeerd (niet verwijderd); ADR-0003-aanvulling (buildnummer uit `pubspec.yaml`, geen `github.run_number`); `STORY_CHECKLIST.md` draait `tool/ci_local.sh` (en memory-stap per fase); README: lokale CI, wanneer GitHub CI draait, apparaattests, sectie Releases, bijdragen via issues; `CLAUDE.md`: lokale CI, release, noreply-adres, beschermde `master`. `.env.example` opgeschoond (Cloudflare Worker/OAuth bestonden nooit). Geen verwijzingen meer naar CI bij elke push.

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

**Status: ✅ Resolved (2026-11-18)** — `tool/release.sh <versie>`: controleert dat de tag op origin staat, dat er nog geen release is, dat HEAD op de tag staat en de werkmap schoon is, en dat `pubspec.yaml` en `CHANGELOG.md` bij de versie passen; bouwt de APK, controleert versionName/versionCode en de releasesleutel (`apksigner`), en publiceert `Cratewise-<versie>.apk` met de CHANGELOG-sectie en SHA-256 als notities. Uitgevoerd voor 1.4.3 (de huidige versie; tag `v1.4.3` daarvoor aangemaakt): gedownloade APK = versie 1.4.3 (16), releasesleutel, checksum klopt. Weigert getest: onbekende tag, bestaande release.

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

**Status: ✅ Resolved (2026-11-18)** — Fred heeft de repo op Public gezet. Daarna aangezet en gecontroleerd: secret scanning en push protection (0 meldingen), privé melden van kwetsbaarheden, goedkeuring voor workflows van alle externe bijdragers, ruleset "Protect master" actief (deletion, non_fast_forward). Repo-pagina, GitHub Pages en de release-APK v1.4.3 publiek bereikbaar (HTTP 200); 7 tags. Communityprofiel 85% (geen code of conduct; issue-templates staan op GitHub, profiel nog niet bijgewerkt). Optioneel nog: GitHub Support vragen oude commits van vóór US-174 op te ruimen.

**Gedaan:**
- Gitleaks over de hele geschiedenis: 117 vondsten, allemaal vals alarm (bestandshashes in `graphify-out/cache/stat-index.json`). In de werkmap: twee iOS-certificaten (`ios/*.p12`), in `.gitignore` en nooit gecommit. `.env`, `key.properties` en de keystore nooit gecommit. Apple Team-ID staat in het Xcode-project; gangbaar, geen geheim.
- Besluiten Fred: `graphify-out/` en `.claude/settings.json` uit git (lokaal blijven ze); `.forge/`, `.serena/`, `.remember/`, `skills-lock.json` genegeerd; `docs/` blijft helemaal; alleen Issues aan (geen Wiki, Discussions, Projects).
- E-mailadres: US-173/174. Licentie: US-175.
- `SECURITY.md` (privé melden). README: Discogs-token aanmaken, graphify optioneel en lokaal.
- Dependabot-meldingen en automatische security-fixes aan.

**Na het openbaar maken (Claude):** secret scanning en push protection aan; privé melden van kwetsbaarheden aan; ruleset op `master` (geen force-push, niet verwijderen); Actions: goedkeuring nodig voor workflows van forks; GitHub Pages, tags en zichtbaarheid controleren.

**Optioneel (Fred):** GitHub Support vragen oude, onbereikbare commits van vóór US-174 op te ruimen. Let op: de oude versies van `graphify-out/` en `.claude/settings.json` blijven in de (herschreven) geschiedenis staan; dat is bewust geaccepteerd.

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
- **E-mailadres:** geregeld in US-173 en US-174; vóór openbaar maken gecontroleerd dat geen commit meer het persoonlijke Gmail-adres bevat.
- **Licentie:** GPL-3.0, geregeld in US-175.
- **`SECURITY.md`:** hoe je een beveiligingsprobleem meldt.
- **Instellingen na openbaar maken:**
  - Secret scanning en push protection aan.
  - Dependabot-meldingen aan.
  - Branch protection op `master`: geen force-push, niet verwijderen.
  - Actions: workflows van forks alleen na goedkeuring.
  - Issues, Discussions en Wiki aan of uit volgens de keuze van Fred.
- **README** geschikt voor buitenstaanders: wat de app is, hoe je hem bouwt (eigen Discogs-token, nooit in de repo), waar de releases staan (US-171).
- **De laatste stap doet Fred zelf:** de repo op Public zetten. Daarna controleert Claude dat GitHub Pages, de tags en de releases werken.

---

### US-173: Commits voortaan met het GitHub-noreply-adres

**Status: ✅ Resolved (2026-11-18)** — `user.email` in deze repo is het noreply-adres; `user.name` (globaal) is `Fred Duzink`. Testcommit: auteur en committer beide noreply. De globale instelling is bewust niet aangepast; dat beslist Fred apart (raakt al zijn repo's).

**Priority: High · 1 SP**

> Als eigenaar,
> wil ik dat nieuwe commits mijn noreply-adres gebruiken,
> zodat mijn persoonlijke e-mailadres niet in openbare commits komt.

**Context:**
Op 2026-11-18 is in deze repo al `git config user.email 2884813+stay-different-digital@users.noreply.github.com` gezet (alleen deze repo). De globale git-instelling staat nog op het persoonlijke Gmail-adres. Omdat "Block command line pushes that expose my email" aan staat, weigert GitHub elke push met een commit op het Gmail-adres.

**Acceptance criteria:**
- `git config user.email` in deze repo geeft het noreply-adres; `git config user.name` is `Fred Duzink`.
- Fred beslist of ook de globale instelling (`git config --global user.email`) naar het noreply-adres gaat; dat raakt al zijn andere repo's.
- Een testcommit heeft het noreply-adres als auteur en committer.

---

### US-174: Oude commits herschrijven naar het noreply-adres

**Status: ✅ Resolved (2026-11-18)** — met `git filter-repo` herschreven: mailmap naar het noreply-adres (ook het oude `itris`-noreply-adres), en het persoonlijke adres in bestanden en 2 commitberichten vervangen door het teamadres uit US-87. Gecontroleerd: het adres komt nergens meer voor; alle tags bestaan nog en verschillen van vóór alleen in die adreswissel; `.env`, `key.properties` en keystore intact. Force-push van `master` en tags met toestemming van Fred; GitHub is gelijk aan lokaal. Flutter CI daarvoor tijdelijk uitgezet. Back-up: `~/Projects/Cratewise-backup-before-US-174.git`.

**Priority: High · 3 SP**

> Als eigenaar,
> wil ik mijn Gmail-adres uit alle bestaande commits laten vervangen,
> zodat het niet zichtbaar wordt als de repo openbaar is.

**Context:**
- 403 commits hebben het persoonlijke Gmail-adres van Fred als auteur; 1 commit `Fred <2884813+itris@users.noreply.github.com>` (een oud noreply-adres onder de vroegere gebruikersnaam).
- Herschrijven met `git filter-repo --mailmap` (installeren: `brew install git-filter-repo`). Een mailmap zet beide oude adressen om naar `Fred Duzink <2884813+stay-different-digital@users.noreply.github.com>`.
- **Gevolgen:** alle commit-hashes en tags krijgen een nieuwe waarde; daarna is een force-push van `master` en alle tags nodig. Andere clones (andere computers) moeten opnieuw worden gecloned. Commit-hashes die in docs of stories staan, kloppen niet meer.
- **Dit blokkeert pushen:** zolang er lokale commits op het Gmail-adres staan, weigert GitHub de push. Daarom vóór de andere stories.
- Nu kan het nog goedkoop: Fred werkt alleen en er zijn geen forks.

**Acceptance criteria:**
- **Back-up eerst:** een volledige mirror-kopie (`git clone --mirror`) buiten het project, en controle dat die compleet is.
- Het persoonlijke adres staat ook in bestanden (tot US-87 in app, site en docs) en in 2 commitberichten; die worden met `--replace-text`/`--replace-message` vervangen door het teamadres uit US-87.
- Herschreven met `git filter-repo --mailmap`, in een verse clone (filter-repo verwacht dat); daarna de bestaande map erop aangesloten of vervangen, zonder lokale bestanden te verliezen die niet in git staan (`.env`, `android/key.properties`, de keystore, `.claude/` enz.).
- Na het herschrijven: `git log --all --format='%ae %ce' | sort -u` toont alleen het noreply-adres (en eventueel `noreply@github.com` voor commits die GitHub zelf maakte).
- Alle tags (`v1.0.0` … `v1.4.2`) bestaan nog en wijzen naar dezelfde inhoud: `git diff <oude tag> <nieuwe tag>` is leeg (vergeleken met de back-up).
- De inhoud van `master` is gelijk aan vóór het herschrijven (`git diff` tegen de back-up is leeg).
- **De force-push alleen na expliciete toestemming van Fred** (`git push --force origin master` en `git push --force --tags`). Daarna staat dezelfde geschiedenis op GitHub, en is CI/Pages nog werkend.
- Commit-hashes in docs en stories die naar oude commits verwijzen, zijn bijgewerkt (of als historisch gemarkeerd).
- Oude GitHub-tags of releases zonder lokale tegenhanger zijn er niet meer.
- Opmerking: GitHub kan oude commits nog een tijd bewaren via hun oude hash. Wil Fred die echt weg, dan kan GitHub Support dat opruimen; vóór openbaar maken is dat niet nodig zolang de repo privé is tijdens het herschrijven.

---

### US-175: GPL-3.0-licentie toevoegen

**Status: ✅ Resolved (2026-11-18)** — `LICENSE` met de officiële tekst van gnu.org (674 regels, SHA-256 `3972dc97…`). README: licentie, naam/logo vallen er niet onder, Discogs-gegevens onder de Discogs API-voorwaarden. Het "Over"-venster vermeldt "Free software under the GNU GPL v3.0" (de knop "View licenses" toont de package-licenties). Directe dependencies: MIT (`csv`, `file_picker`, `drift`, `uuid`) en BSD-3-Clause (`flutter`, `flutter_localizations`, `flutter_secure_storage`, `go_router`, `http`, `intl`, `material_ui`, `package_info_plus`, `path`, `path_provider`, `sensors_plus`, `share_plus`, `url_launcher`); alle verenigbaar met GPL-3.0.

**Priority: Medium · 1 SP**

> Als eigenaar,
> wil ik de code onder GPL-3.0 uitbrengen,
> zodat anderen de code mogen gebruiken en aanpassen, maar een verspreide aangepaste versie ook open source moet blijven.

**Context:**
Besluit van Fred (2026-11-18). Afhankelijkheden van de app gebruiken vrije licenties (MIT, BSD, Apache-2.0) die samengaan met GPL-3.0; nagaan bij uitvoeren. De licentie gaat over de code, niet over de naam en het logo "Cratewise", en niet over Discogs-gegevens (die vallen onder de API-voorwaarden van Discogs).

**Acceptance criteria:**
- `LICENSE` in de projectroot met de officiële GPL-3.0-tekst (van gnu.org, ongewijzigd).
- `pubspec.yaml` blijft `publish_to: none`; de README noemt de licentie en dat naam en logo er niet onder vallen.
- Licenties van alle directe dependencies nagelopen op verenigbaarheid met GPL-3.0; resultaat in de story vastgelegd.
- De in-app licentiepagina (`showLicensePage` of vergelijkbaar, als die er is) toont de licentie van de app; anders wordt dat als vervolgstap genoteerd.

---

### US-176: `CONTRIBUTING.md` herschrijven: eerst issue en akkoord, dan PR

**Status: ✅ Resolved (2026-11-18)** — `CONTRIBUTING.md` herschreven: issue → label `accepted` → fork/branch vanaf `master` → PR met `Closes #`; PR zonder geaccepteerd issue kan gesloten worden (typo's uitgezonderd); lokaal testen met `tool/ci_local.sh`; eigen Discogs-token; conventies (lagen, analyze, 5 talen in `lib/l10n`, migraties, changelog, geen geheimen); GPL-3.0. Alle verwijzingen gecontroleerd. Labels `accepted` en `technical` aangemaakt.

**Priority: Medium · 2 SP**

> Als buitenstaander die wil bijdragen,
> wil ik in één document lezen hoe ik dat doe,
> zodat mijn werk aansluit bij wat de eigenaar wil en niet voor niets is.

**Context:**
De huidige `CONTRIBUTING.md` is verouderd: noemt de app "Crate", werkt vanuit `main` (de branch is `master`) en verwijst naar bestanden die niet bestaan (`AGENT.md`, `docs/project/...`). GitHub kan "eerst een issue" niet afdwingen; het document en de templates (US-177, US-178) moeten het duidelijk maken.

**Acceptance criteria:**
- Werkwijze in volgorde:
  1. Open eerst een issue met een template (bug, feature of technische taak).
  2. Wacht op een akkoord van de eigenaar op het issue (bijvoorbeeld een label `accepted` of een reactie).
  3. Fork en maak een branch vanaf `master`.
  4. Maak een kleine, gerichte wijziging met tests.
  5. Open een PR die naar het issue verwijst (`Closes #<nummer>`).
- Duidelijk vermeld: een PR zonder issue of zonder akkoord kan worden gesloten; kleine typfouten in docs mogen zonder issue.
- **Lokaal testen:** vereisten (Flutter-versie, CocoaPods voor iOS), `tool/ci_local.sh` (US-168) of de losse stappen (`dart format`, `flutter analyze`, `flutter test`), en dat CI op GitHub niet bij elke PR draait.
- **Discogs-token:** gebruik je eigen persoonlijke token; nooit tokens, `.env`, keystores of certificaten committen.
- Conventies kort: commitberichten, codestijl (`analysis_options.yaml`), lagen domain → infrastructure → presentation, nieuwe teksten in beide talen (`l10n`).
- Beveiligingsproblemen: niet via een issue, maar volgens `SECURITY.md`.
- Bijdragen vallen onder GPL-3.0 (`LICENSE`).
- Geen verwijzingen naar bestanden die niet bestaan; alle links in het document gecontroleerd.
- Label `accepted` bestaat in de repo (aanmaken als het er niet is).

---

### US-177: Lege issues uitzetten; beveiligingsmeldingen naar `SECURITY.md`

**Status: ✅ Resolved (2026-11-18)** — `config.yml` met `blank_issues_enabled: false` en een link naar het privé-meldformulier (`security/advisories/new`, werkt zodra privé melden aan staat na US-172). Templates ingekort en bijgewerkt (geen login, Cloudflare Worker of `AGENT.md` meer; bug vraagt versie, platform, stappen). Controle van "New issue" op GitHub volgt na openbaar maken (US-172).

**Priority: Low · 1 SP**

> Als eigenaar,
> wil ik dat iedereen een issue-template moet kiezen,
> zodat meldingen compleet zijn en beveiligingsproblemen niet openbaar gemeld worden.

**Context:**
`.github/ISSUE_TEMPLATE/` heeft al `bug_report.md`, `feature_request.md` en `technical_task.md`. Er is nog geen `config.yml`, dus een leeg issue kan nog.

**Acceptance criteria:**
- `.github/ISSUE_TEMPLATE/config.yml` met `blank_issues_enabled: false`.
- Een contactlink "Report a security vulnerability" die naar het privé-meldformulier van GitHub of naar `SECURITY.md` wijst.
- De drie bestaande templates nagelopen: verwijzen naar de huidige app (geen "Crate", geen verouderde paden) en vragen bij een bug om versie, platform en stappen.
- Gecontroleerd op GitHub: "New issue" toont alleen de templates en de beveiligingslink, geen leeg issue.

---

### US-178: PR-template aanscherpen: issuenummer verplicht

**Status: ✅ Resolved (2026-11-18)** — PR-template: bovenaan `Closes #` (verplicht) met uitleg over het label `accepted`; PR zonder geaccepteerd issue kan zonder review gesloten worden; korte checklist (tests, `tool/ci_local.sh`, vertalingen, CHANGELOG, geen geheimen).

**Priority: Low · 1 SP**

> Als eigenaar,
> wil ik dat elke PR naar een goedgekeurd issue verwijst,
> zodat ik geen PR's krijg voor werk dat ik niet wil.

**Context:**
`.github/PULL_REQUEST_TEMPLATE.md` heeft al een veld `Closes: #`, maar dat is vrijblijvend.

**Acceptance criteria:**
- Bovenaan het template: "This PR closes #___ (required)", met de uitleg dat het issue een akkoord moet hebben (label `accepted`, zie `CONTRIBUTING.md`).
- Duidelijk vermeld: een PR zonder issue of zonder akkoord kan zonder review gesloten worden.
- Checklist: tests toegevoegd of aangepast, lokaal gecontroleerd (`tool/ci_local.sh` of losse stappen), CHANGELOG bijgewerkt bij een zichtbare wijziging, geen geheimen gecommit.
- Het template is kort genoeg om in te vullen: geen secties die voor een kleine PR niet gelden.

---

### US-179: Code of conduct toevoegen

**Status: In Progress**

**Priority: Low · 1 SP**

> Als eigenaar van een openbare repo,
> wil ik vastleggen hoe mensen met elkaar omgaan in issues en pull requests,
> zodat ik ongewenst gedrag kan aanspreken en het communityprofiel compleet is.

**Context:**
Na US-172 staat het communityprofiel van GitHub op 85%; alleen een code of conduct ontbreekt. De gangbare keuze is de Contributor Covenant (versie 2.1), die GitHub zelf ook aanbiedt.

**Acceptance criteria:**
- `CODE_OF_CONDUCT.md` in de projectroot met de officiële tekst van Contributor Covenant 2.1, ongewijzigd behalve de contactgegevens.
- Meldingen gaan naar het teamadres `hellowerecratewise@gmail.com` (geen persoonlijk adres).
- `CONTRIBUTING.md` verwijst ernaar.
- Het communityprofiel van GitHub herkent de code of conduct.
