# Code Review — User Stories

Derived from an external developer code review (2026-06-17).
Numbering continues from US-93.

Stories are ordered by priority: High → Medium → Low.

---

### US-94: Repositories en database worden app-scope beheerd via dependency injection

**Priority: High · 5 SP**

> Als ontwikkelaar,
> wil ik dat de `AppDatabase` en repositories één keer worden aangemaakt op app-niveau en via dependency injection in screens worden geïnjecteerd,
> zodat er geen race conditions of databasecorruptie ontstaan door meerdere gelijktijdige `AppDatabase`-instanties in de presentation layer.

**Context:**
Op dit moment maakt elke screen zijn eigen `AppDatabase(openAppDatabase())` aan:
[main.dart:11](lib/main.dart#L11), [search_screen.dart:157](lib/presentation/screens/search_screen.dart#L157), [collection_screen.dart:80](lib/presentation/screens/collection_screen.dart#L80), [settings_screen.dart:184](lib/presentation/screens/settings_screen.dart#L184). Dit is in strijd met de architectuurregel "presentation not direct to database" en genereert Drift race-condition-waarschuwingen tijdens tests.

**Acceptance criteria:**
- Er bestaat precies één `AppDatabase`-instantie in de gehele app, aangemaakt in een composition root (bijv. `main.dart` of een dedicated `AppProviders`-widget).
- Alle repositories (`LocalCollectionRepository`, `LocalWishlistRepository`, `LocalThumbnailRepository`, etc.) worden op app-niveau aangemaakt en geïnjecteerd in screens via constructor-parameters of een provider (Riverpod of `InheritedWidget`).
- Geen enkel presentation-bestand (`lib/presentation/`) importeert nog `app_database.dart` om zelf een instantie aan te maken.
- `flutter analyze` en `flutter test` blijven groen na de wijziging.
- De bestaande Drift race-condition-waarschuwingen in de test-output verdwijnen.
- `widget.repository != null`-guards in screens blijven werken voor testinjectie.

---

### US-95: `flutter analyze` geeft 0 issues

**Priority: High · 3 SP**

> Als ontwikkelaar,
> wil ik dat `flutter analyze` slaagt zonder issues,
> zodat de analyzer-gate in de commit- en release-checklist weer betrouwbaar werkt en nieuwe issues direct opvallen.

**Context:**
`flutter analyze` faalt nu met 51 issues. Voorbeelden:
- Deprecated `DropdownButtonFormField.value` in [release_detail_screen.dart:1561](lib/presentation/screens/release_detail_screen.dart#L1561)
- Analyzer warnings in tests
- Lint issues zoals [collection_screen.dart:165](lib/presentation/screens/collection_screen.dart#L165)

**Acceptance criteria:**
- `flutter analyze` geeft `No issues found!` (exit code 0).
- Geen enkel issue is gesuppressed met `// ignore:` tenzij er een gedocumenteerde reden is die niet anders opgelost kan worden.
- Deprecated API-aanroepen zijn vervangen door de aanbevolen alternatieven.
- Alle lint issues (zoals onnodige `setState`-aanroepen, ongebruikte imports, etc.) zijn opgelost.
- De fix wordt gecommit als los commit vóór andere feature-work, zodat de baseline schoon is.

---

### US-96: Integration smoke test `qa_section_a_test.dart` is betrouwbaar

**Priority: High · 2 SP**

> Als ontwikkelaar,
> wil ik dat de integration smoke test in `qa_section_a_test.dart` betrouwbaar slaagt,
> zodat device-validatie op echte hardware vertrouwd kan worden als kwaliteitsgate.

**Context:**
`flutter test integration_test` faalt op [qa_section_a_test.dart:56](integration_test/qa_section_a_test.dart#L56). De test zoekt op "Aphex Twin" en verwacht exact één widget, maar vindt er vier — waarschijnlijk omdat de finder te breed is en meerdere text-instanties matcht.

**Acceptance criteria:**
- De test slaagt op een fysiek Android-apparaat en in de iOS-simulator.
- De finder op regel 56 is specifiek genoeg: gebruik een `Key`, een specifieke widget-type-check, of valideer de `TextEditingController`-waarde in plaats van een tekstmatch die ook in andere widgets kan voorkomen.
- De rest van de smoke test blijft ongewijzigd qua dekking.
- `flutter test integration_test` geeft 0 failures.

---

### US-97: Startup-cleanup in `main.dart` wordt niet fire-and-forget uitgevoerd

**Priority: Medium · 2 SP**

> Als ontwikkelaar,
> wil ik dat de startup-cleanup in `main.dart` gecontroleerd wordt afgewacht,
> zodat race conditions tussen cleanup en screen-initialisatie worden voorkomen.

**Context:**
[main.dart:11-12](lib/main.dart#L11) start cleanup-taken fire-and-forget (niet awaited). In combinatie met meerdere eigen `AppDatabase`-instanties per screen vergroot dit lifecycle-ruis en maakt het moeilijker om opstartvolgorde te redeneren. Dit hangt samen met US-94 (gedeelde database): als US-94 klaar is, heeft cleanup al een gedeelde instantie om op te werken.

**Acceptance criteria:**
- `main()` is `async` en de cleanup-aanroepen worden geawait voor `runApp()` wordt aangeroepen, óf cleanup wordt gedelegeerd aan een app-service die op de gedeelde database werkt (zie US-94).
- Als cleanup te lang duurt om voor `runApp()` te doen, wordt er een verantwoorde keuze gemaakt (bijv. cleanup na eerste frame met uitleg in een comment) — de keuze is expliciet, niet per ongeluk fire-and-forget.
- `flutter test` en `flutter analyze` blijven groen.

---

### US-98: HTTP-clients krijgen een gecontroleerde lifecycle

**Priority: Medium · 3 SP**

> Als ontwikkelaar,
> wil ik dat `http.Client`-instanties centraal worden beheerd en netjes worden gesloten,
> zodat er geen resource-lekken ontstaan door clients die nooit worden gesloten.

**Context:**
[discogs_api_client.dart:31](lib/infrastructure/discogs/discogs_api_client.dart#L31) en [thumbnail_cache_service.dart:14](lib/application/services/thumbnail_cache_service.dart#L14) maken elk hun eigen `http.Client()` aan zonder `close()`. Als deze services op app-niveau leven (zie US-94) is dit minder urgent, maar de clients zelf hebben nog geen lifecycle-beheer.

**Acceptance criteria:**
- Elke service die een `http.Client` aanmaakt, accepteert een optionele geïnjecteerde client (voor testbaarheid) en heeft een `close()`-methode of wordt aangemaakt als singleton op app-niveau die bij app-shutdown wordt gesloten.
- In de testsuites wordt een mock/fake client geïnjecteerd; geen echte HTTP-aanroepen in unit tests.
- Er zijn geen `http.Client`-instanties meer die worden aangemaakt in `build()`-methodes of constructors die per-screen worden aangeroepen.
- `flutter analyze` en `flutter test` blijven groen.

---

### US-100: Consistente itemweergave en spacing in Search, Collection en Wishlist

**Priority: Medium · 2 SP**

> Als gebruiker die tussen de Search-, Collection- en Wishlist-tabs navigeert,
> wil ik dat items in alle drie schermen visueel consistent zijn opgemaakt,
> zodat de app één samenhangend geheel voelt en ik me nooit afvraag waarom iets er anders uitziet.

**Context:**
Uit code-analyse blijkt dat spacing en padding al grotendeels consistent zijn (separator `8dp`, lijst padding `fromLTRB(16,0,16,16)`, card interne padding `all(12)`, thumbnail `72×72` met `borderRadius: 6`, texthiërarchie `labelLarge` → `bodyMedium` → `bodySmall`). Twee zaken wijken af:

1. **Meta-volgorde:** [`release_search_result_card.dart`](lib/presentation/widgets/release_search_result_card.dart) toont `format · label` op regel 1 en `year · country` op regel 2. [`collection_item_card.dart`](lib/presentation/widgets/collection_item_card.dart) en [`wishlist_item_card.dart`](lib/presentation/widgets/wishlist_item_card.dart) tonen `label · year · format` op één regel.
2. **Kaarthoogte:** De search card heeft twee meta-regels met een extra `SizedBox(height: 4)` ertussen, waardoor hij structureel hoger is dan de collection/wishlist card bij dezelfde data.

**Buiten scope:** wishlist-specifieke `_PriorityBadge` en search-specifieke membership badges — deze zijn functioneel verschillend en mogen visueel afwijken.

**Acceptance criteria:**
- De gemeenschappelijke metavelden (label, year, format) worden in dezelfde volgorde getoond in alle drie cards: `label · year · format`.
- Een release zonder wishlist- of search-specifieke extra data (geen priority badge, geen membership icons, geen land) heeft in alle drie tabs dezelfde kaarthoogte.
- De wijziging raakt alleen [`release_search_result_card.dart`](lib/presentation/widgets/release_search_result_card.dart) — de collection- en wishlist cards zijn al correct.
- Bestaande widget tests voor de search result card blijven groen; pas ze aan waar nodig.
- `flutter analyze` geeft 0 issues na de wijziging.

**QA-checklist:**
- [ ] Zet een identieke release in Collection én Wishlist, zoek hem op in Search — vergelijk de drie cards naast elkaar op een fysiek apparaat.
- [ ] Controleer of `label · year · format` in dezelfde volgorde staat in alle drie tabs.
- [ ] Controleer of de kaarthoogte voor een minimale release (alleen artist + title, geen land) gelijk is in alle drie tabs.
- [ ] Breed scherm (≥700dp): grid in Collection en Wishlist, lijst in Search — horizontale padding gelijk?

---

### US-99: Platform dependency-waarschuwingen zijn gedocumenteerd en ingepland

**Priority: Low · 1 SP**

> Als ontwikkelaar,
> wil ik dat bekende platform dependency-waarschuwingen gedocumenteerd zijn met een actieplan,
> zodat ze niet plotseling een blocker worden bij een volgende build of store-submission.

**Context:**
Huidige waarschuwingen (geen blocker vandaag):
- Android plugins gebruiken nog de verouderde Kotlin Gradle Plugin (AGP-migratie).
- iOS: `flutter_secure_storage` ondersteunt nog geen Swift Package Manager (SPM).

**Acceptance criteria:**
- `docs/archive/known_limitations.md` (of een equivalent bestand) bevat een sectie "Platform dependency warnings" met per waarschuwing: de naam, de impact, de verwachte fix-datum of de upstream tracking issue, en of er een workaround beschikbaar is.
- Er is een korte notitie in de release checklist (`docs/release/RELEASE_CHECKLIST.md`) dat deze waarschuwingen worden gecheckt bij elke release.
- Er hoeft geen code te worden gewijzigd als de upstream packages nog geen fix bieden — documentatie is voldoende voor deze story.

---

### US-101: GitHub Pages site geeft 404

**Priority: High · 1 SP**

> Als bezoeker of ontwikkelaar die de Cratewise-projectsite wil bekijken,
> wil ik dat `https://itris.github.io/Cratewise/` correct laadt,
> zodat de site bereikbaar is en de README, changelog en privacypagina toegankelijk zijn.

**Context:**
De GitHub Pages-instelling stond op `build_type: legacy` (serveer bestanden direct vanaf een branch), terwijl de CI-workflow `deploy-pages.yml` gebruikmaakt van `actions/deploy-pages@v5`. Dit vereist `build_type: workflow`. Doordat de twee instellingen niet overeenkwamen, negeerde GitHub Pages het door Actions gebouwde artifact en zocht het naar een `index.html` in de root van de `master`-branch — die bestaat niet. Resultaat: elke pagina gaf HTTP 404.

**Acceptance criteria:**
- `https://itris.github.io/Cratewise/` laadt de homepage zonder fout.
- De subpagina's `/about/`, `/changelog/` en `/privacy/` zijn alle bereikbaar.
- De GitHub Pages-instelling staat permanent op `build_type: workflow` zodat toekomstige pushes naar `master` (met wijzigingen in `site/**`, `CHANGELOG.md` of `README.md`) automatisch deployen.
- `deploy-pages.yml` hoeft niet te worden gewijzigd — de workflow was al correct.

**QA-checklist:**
- [ ] Open `https://itris.github.io/Cratewise/` — pagina laadt.
- [ ] Navigeer naar About, Changelog en Privacy — alle drie bereikbaar.
- [ ] Verifieer in GitHub → Settings → Pages dat "Source" op "GitHub Actions" staat.

---

### US-102: `Crate`-map wordt aangemaakt naast de projectdirectory

**Priority: Low · 1 SP**

> Als ontwikkelaar die tests draait of een Android-build uitvoert,
> wil ik dat er geen map `/Users/fred/Projects/Crate/` wordt aangemaakt naast het project,
> zodat mijn werkruimte schoon blijft en er geen verwarring ontstaat met de oude projectnaam.

**Context:**
Na de hernoeming van het project van `Crate` naar `Cratewise` (US-93) bestaat er nog een lege map op `/Users/fred/Projects/Crate/build/app/intermediates/flutter/`. Deze bevat geen bronbestanden — alleen `.DS_Store`-bestanden van Finder. De directorystructuur `build/app/intermediates/flutter/` is identiek aan de Android Gradle-tussenbestanden die de Flutter Gradle plugin aanmaakt. De instelling in [`android/build.gradle.kts`](android/build.gradle.kts):

```kotlin
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
```

lost normaal op naar `Cratewise/build/`. Vermoeden: de map is een restant van de oude projectlocatie en kan worden (her)aangemaakt door de Gradle-daemon of Flutter-tools wanneer deze een gecachte verwijzing naar het oude pad nog kennen.

**Acceptance criteria:**
- De map `/Users/fred/Projects/Crate/` is verwijderd.
- Na het uitvoeren van `flutter test` en `flutter build apk --debug` bestaat `/Users/fred/Projects/Crate/` niet opnieuw.
- Als de map wél opnieuw verschijnt: de oorzaak is geïdentificeerd (Gradle-daemon-cache, init-script, of hardcoded pad) en structureel verholpen — niet alleen genegeerd.
- `flutter analyze` en `flutter test` blijven groen.

**QA-checklist:**
- [ ] Verwijder `/Users/fred/Projects/Crate/` handmatig.
- [ ] Draai `flutter test` — controleer of de map terugkomt.
- [ ] Draai `flutter build apk --debug` — controleer opnieuw.
- [ ] Controleer `~/.gradle/` op init-scripts of cached projectpaden die naar `Crate` verwijzen.

---

### US-103: Afbeeldingen op detailpagina's zijn scrollbaar

**Priority: Medium · 3 SP**

> Als gebruiker die een release bekijkt,
> wil ik door alle beschikbare afbeeldingen kunnen scrollen op de Search-, Collection- en Wishlist-detailpagina,
> zodat ik de hoes, labels en andere foto's van een release kan bekijken zonder de app te verlaten.

**Context:**
De Discogs API levert bij een release-detail een `images`-array met meerdere afbeeldings-URL's (`uri`). Momenteel slaat [`release_detail.dart`](lib/domain/models/release_detail.dart) slechts één `coverUrl` op en tonen alle drie detailschermen ([`release_detail_screen.dart`](lib/presentation/screens/release_detail_screen.dart), [`collection_detail_screen.dart`](lib/presentation/screens/collection_detail_screen.dart), [`wishlist_detail_screen.dart`](lib/presentation/screens/wishlist_detail_screen.dart)) alleen die ene afbeelding. Overige foto's (labelfoto's, achterkant) zijn niet toegankelijk.

**Acceptance criteria:**
- `ReleaseDetail` heeft een nieuw veld `imageUrls: List<String>` dat alle afbeeldings-URL's uit de Discogs API-response bevat (op volgorde zoals de API ze levert). `coverUrl` blijft behouden als convenience-getter (`imageUrls.firstOrNull`).
- De Discogs API-client mappt het `images`-array uit de response naar `imageUrls`.
- Alle drie detailschermen tonen een horizontaal scrollbare `PageView` voor de afbeeldingen, met een dots-indicator die aangeeft hoeveel afbeeldingen er zijn en welke actief is.
- Bij precies één afbeelding is er geen dots-indicator zichtbaar en is scrollen uitgeschakeld.
- Bij nul afbeeldingen toont de widget de huidige placeholder (albumicoontje).
- De `PageView` is toegankelijk via semantics: elke pagina heeft een label "Afbeelding X van Y".
- `flutter analyze` geeft 0 issues en `flutter test` blijft groen; nieuwe widget tests voor de image gallery worden toegevoegd.

**QA-checklist:**
- [ ] Open een release met meerdere afbeeldingen in Search — verifieer dat je kunt scrollen en de dots correct bewegen.
- [ ] Controleer hetzelfde in Collection en Wishlist voor dezelfde release.
- [ ] Open een release met slechts één afbeelding — verifieer dat er geen dots zichtbaar zijn.
- [ ] Open een release zonder afbeeldingen — verifieer dat de placeholder wordt getoond.
- [ ] Controleer dat de `PageView` niet schuift terwijl je verticaal scrollt in het detailscherm.

---

### US-104: Begeleide onboarding voor nieuwe gebruikers

**Priority: Medium · 5 SP**

> Als nieuwe gebruiker die de app voor het eerst opent,
> wil ik stap voor stap worden begeleid bij het instellen van mijn Discogs-account en het importeren van mijn collectie en verlanglijst,
> zodat ik zonder handleiding direct aan de slag kan en meteen mijn eigen data zie.

**Context:**
Nieuwe gebruikers landen nu rechtstreeks op de Search-tab zonder enige begeleiding. De benodigde bouwstenen bestaan al: [`discogs_token_section.dart`](lib/presentation/widgets/discogs_token_section.dart) voor het koppelen van een Discogs-account, en [`import_export_screen.dart`](lib/presentation/screens/import_export_screen.dart) voor het importeren van collectie en verlanglijst. Er is echter geen wizard die deze stappen achtereenvolgens aanbiedt, en er is geen detectie of een gebruiker al eerder heeft geconfigureerd. In [`settings_screen.dart`](lib/presentation/screens/settings_screen.dart) bevindt zich al een link naar Import/Export, maar geen optie om de onboarding opnieuw te starten.

**Acceptance criteria:**
- Bij de eerste app-start (geen Discogs-token aanwezig) wordt automatisch een `OnboardingScreen` getoond in plaats van de hoofdnavigatie.
- De onboarding bestaat uit drie stappen:
  1. **Welkomstscherm** — korte uitleg van Cratewise en wat de gebruiker gaat doen.
  2. **Discogs-token koppelen** — hergebruikt de bestaande `DiscogsTokenSection`-widget; de "Volgende"-knop wordt pas actief nadat het token succesvol is gevalideerd.
  3. **Collectie & verlanglijst importeren** — geeft directe toegang tot de Discogs-import voor collectie én verlanglijst; de gebruiker kan deze stap overslaan met een expliciete "Sla over"-link.
- Na voltooiing (of overslaan van stap 3) navigeert de app naar de normale hoofdnavigatie.
- De onboarding-status wordt persistent opgeslagen (bijv. via `shared_preferences` of `flutter_secure_storage`) zodat de wizard niet opnieuw verschijnt bij herstart.
- De `SettingsScreen` bevat een nieuwe tegel **"Rondleiding opnieuw starten"** die de onboarding opnieuw toont (nuttig bij account-wissel of reset). De tegel is altijd zichtbaar, ongeacht of er een token is ingesteld.
- `flutter analyze` geeft 0 issues en `flutter test` blijft groen; er zijn widget tests voor:
  - de onboarding toont bij eerste start (geen token),
  - de onboarding toont niet bij herstart als al geconfigureerd,
  - de "Volgende"-knop in stap 2 is uitgeschakeld totdat het token gevalideerd is,
  - de "Sla over"-link in stap 3 navigeert naar de hoofdnavigatie.

**QA-checklist:**
- [ ] Verwijder app-data / installeer vers — verifieer dat de onboarding automatisch verschijnt.
- [ ] Doorloop alle drie stappen inclusief een echte token-validatie — verifieer dat de app naar de hoofdnavigatie gaat.
- [ ] Herstart de app na voltooide onboarding — verifieer dat de onboarding niet opnieuw verschijnt.
- [ ] Gebruik de tegel "Rondleiding opnieuw starten" in de instellingen — verifieer dat de onboarding weer verschijnt.
- [ ] Sla stap 3 (import) over — verifieer dat de app direct naar de hoofdnavigatie gaat.

---

### US-105: Projectbestanden staan op de juiste plek

**Priority: Low · 2 SP**

> Als ontwikkelaar,
> wil ik dat alle projectbestanden logisch en consistent zijn georganiseerd,
> zodat de repository overzichtelijk blijft en nieuwe bijdragers snel kunnen navigeren.

**Context:**
Een inspectie van de projectstructuur (2026-06-18) toont een aantal bestanden die op de verkeerde plek staan of verouderd zijn:

| Bestand / map | Huidige locatie | Probleem |
|---|---|---|
| `flutter_01.png` | root | 163 KB screenshot zonder verwijzing in README of docs |
| `primer.md` | root | Verouderde sessie-context uit Jun 2026; root is geen archief |
| `package-lock.json` | root | Leeg npm-lockfile (`packages: {}`); Flutter gebruikt geen npm |
| `docs/product/ROADMAP.md` | `docs/product/` | V1-roadmap (jun 2) wordt overschaduwd door `ROADMAP_V2.md` (jun 11) |
| `beta-user-stories.md` / `-m` / `-s` | `docs/user-stories/` | Pre-fase backlog-bronmateriaal; niet dezelfde categorie als fase-stories |

**Acceptance criteria:**
- `flutter_01.png` is verplaatst naar `docs/assets/screenshots/` of verwijderd als het nergens naar verwezen wordt.
- `primer.md` is verplaatst naar `docs/archive/` of verwijderd (inhoud is verouderd en niet operationeel relevant).
- `package-lock.json` is verwijderd uit de root (geen npm-afhankelijkheden in dit project).
- `docs/product/ROADMAP.md` (V1) is verplaatst naar `docs/archive/`; `ROADMAP_V2.md` blijft de enige actieve roadmap in `docs/product/`.
- `beta-user-stories.md`, `beta-user-stories-m.md` en `beta-user-stories-s.md` zijn verplaatst van `docs/user-stories/` naar `docs/archive/` (het zijn bronbestanden, geen actieve sprints).
- `flutter analyze` geeft 0 issues en `flutter test` blijft groen na de wijzigingen.
- `.gitignore` wordt indien nodig bijgewerkt (bijv. als `flutter_01.png` nooit gecommit had mogen worden).

**QA-checklist:**
- [ ] Verifieer dat `git status` na de wijzigingen schoon is (geen onverwachte ongetrackte bestanden).
- [ ] Verifieer dat `docs/product/` alleen `PROJECT_BRIEF.md` en `ROADMAP_V2.md` bevat.
- [ ] Verifieer dat `docs/archive/` de gearchiveerde bestanden bevat.

---

### US-106: Fix — camera blijft zwart na toestemmingsdialoog bij barcode-scanner

**Priority: High · 2 SP · Status: Resolved**

> Als gebruiker,
> wil ik dat de camera direct actief is nadat ik cameratoestemming heb verleend,
> zodat ik meteen een barcode kan scannen zonder de app opnieuw te openen.

**Spike-bevinding (2026-06-18):**
De oorzaak ligt niet in de Discogs API maar in de camera-lifecycle. Op Android triggert de
toestemmingsdialoog de `AppLifecycleState.paused`-state. De `MobileScanner`-widget verwerkt intern
alleen `inactive` (iOS), niet `paused` (Android). Hierdoor stopt de camera bij het openen van de
dialoog, maar start hij niet opnieuw na het verlenen van toestemming — de camera blijft zwart.

| Vraag | Bevinding |
|---|---|
| Is het probleem in de camera of in de lookup? | **Camera** — de scanner bereikt de lookup nooit. |
| Waarom blijft het scherm zwart? | `MobileScanner.useAppLifecycleState` handelt `paused` niet af. |
| Betere API-route nodig? | Nee — de API is niet bereikt; search-endpoint is voldoende. |
| Oplossing? | `WidgetsBindingObserver` zelf beheren; `useAppLifecycleState: false` op widget. |

**Geïmplementeerde fix (`_CameraScanAreaState`):**
- `WidgetsBindingObserver` mixin toegevoegd; handmatig `addObserver`/`removeObserver` in `initState`/`dispose`.
- `didChangeAppLifecycleState`: `paused`/`inactive` → `stop()`, `resumed` → `start()` (met `hasCameraPermission`-guard).
- `MobileScanner(useAppLifecycleState: false, …)` — ingebouwde handler uitgeschakeld om dubbele aanroepen te voorkomen.
- `AndroidManifest.xml`: `<uses-feature android:name="android.hardware.camera" android:required="false" />` toegevoegd.

**Acceptance criteria:**
- [x] Spike-bevinding gedocumenteerd.
- [x] Oorzaak vastgesteld: camera lifecycle, niet de API.
- [x] Fix geïmplementeerd en gecommit.

**QA-checklist:**
- [x] Na toestemming verlenen start de camera opnieuw (geen zwart scherm).
- [x] Op iOS: camera stopt bij notificatiebalk/telefoongesprek, hervat na terugkeer.
- [ ] Handmatige barcode-invoer geeft resultaten (bevestigt dat de API-kant werkt).

---

### US-107: Spike — onderzoek KGP-waarschuwing bij `flutter build apk`

**Priority: Medium · 1 SP (spike) · Status: Resolved**

> Als ontwikkelaar,
> wil ik weten wat de Kotlin Gradle Plugin-waarschuwing betekent en of er al fixes beschikbaar zijn,
> zodat toekomstige Flutter-versies de build niet breken.

**Spike-bevinding (2026-06-18):**

De KGP-waarschuwing zit volledig aan de **plugin-kant** — het is niet oplosbaar vanuit de app.
Elke plugin heeft in zijn eigen `build.gradle` nog `apply plugin: 'kotlin-android'` staan.
Zodra Flutter `android.builtInKotlin=true` verplicht stelt (AGP 9.0+ default), breekt de build.

**Mitigatie is al aanwezig:** `android/gradle.properties` bevat al:
```
android.builtInKotlin=false
```
Dit is de door Flutter aanbevolen opt-out. De build slaagt en blijft slagen zolang deze flag actief is.

**Onderzoeksresultaten per plugin:**

| Plugin | Huidig | Getest | KGP-warning weg? | Opmerking |
|---|---|---|---|---|
| `file_picker` | ^10.0.0 | 11.0.2 | Nee | 11.x slaat KGP over op AGP 9+ maar compileert dan niet omdat `builtInKotlin=false` ook built-in Kotlin uitschakelt — teruggedraaid |
| `package_info_plus` | ^8.3.1 | 9.0.1 | Nee | Past KGP nog steeds toe — warning blijft |
| `mobile_scanner` | ^7.2.0 | 7.2.0 | Nee | Al op laatste versie, geen upstream-fix beschikbaar |
| `share_plus` | ^10.0.0 | 12.0.2 | Nee | 12.x compileert niet (bug: `ShareSuccessManager`), 13.x heeft win32-conflict met `flutter_secure_storage` |

**Kritieke bevinding — migratie is alles-of-niets:**
`file_picker 11.x` laat zien waarom losse upgrades niet werken: de plugin past slim conditioneel geen KGP toe op AGP 9+, maar `android.builtInKotlin=false` schakelt ook de built-in Kotlin uit. Resultaat: geen KGP én geen built-in Kotlin → Kotlin-code wordt niet gecompileerd → build breekt.

Alle vier de plugins moeten simultaan naar Built-in Kotlin migreren vóór `builtInKotlin=true` gezet kan worden. Zodra `mobile_scanner` en `share_plus` gereed zijn, moet ook `flutter_secure_storage` naar ^10.x (win32 v6) om `share_plus ^13.x` te kunnen gebruiken.

**Alle wijzigingen zijn teruggedraaid** — `pubspec.yaml` en codebasis staan op originele versies.

**Vervolgactie:** volg GitHub-issues voor `mobile_scanner` (#KGP) en `share_plus` (#KGP). Plan een gecombineerde upgrade zodra alle vier plugins gereed zijn.

**Acceptance criteria:**
- [x] Per plugin vastgesteld of een compatibele versie beschikbaar is.
- [x] Aanbeveling: wacht op plugin-releases; `android.builtInKotlin=false` is de huidige mitigatie.

**QA-checklist:**
- [x] Spike-bevinding gedocumenteerd.
- [x] `flutter build apk` slaagt na de upgrades (warning blijft, is verwacht).
- [ ] KGP-warning verdwenen — te doen zodra plugin-auteurs hun fix publishen.
