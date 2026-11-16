# Phase 17: Zoeken verbeteren en Scannen verwijderen (november 2026)

Aangemaakt: 2026-11-16

Doel: backlog voor de volgende release na v1.0.4. Twee thema's: (1) zoeken op label prettiger maken, (2) de barcodescanner uit de app halen omdat die te weinig gebruikt wordt. Nummering loopt door vanaf US-132.

Gegroomd: 2026-11-16. Sprintplanning: [SPRINT_PLAN_PHASE_17.md](../product/SPRINT_PLAN_PHASE_17.md).

## Overzicht na grooming

| Story | Titel | Prio | SP | Hangt af van |
|---|---|---|---|---|
| US-133 | Zoekresultaten sorteren op releasedatum | High | 3 | — |
| US-134 | Vanuit een release naar het label gaan | High | 3 | US-133 |
| US-135 | Scannen uit het hoofdmenu halen | High | 2 | — |
| US-136 | Barcodescanner-code en dependency verwijderen | Medium | 2 | US-135 |
| US-137 | Android: camerapermissie verwijderen | Medium | 1 | US-136 |
| US-138 | iOS: cameratoestemming verwijderen | Medium | 1 | US-136 |
| US-139 | Opnieuw op "Zoeken" tikken maakt de zoekbalk leeg | Medium | 2 | — |
| US-140 | Collectiestatistieken als item in het hoofdmenu | High | 3 | US-135 |
| US-141 | Geen "Set condition"-venster meer bij toevoegen | High | 1 | — |
| US-142 | Zoeken beperken tot vinyl | High | 3 | na US-133 |
| US-143 | Collectie filteren op formaattype | Medium | 2 | — |
| US-144 | Instelling auto-sync + direct versturen naar Discogs | Medium | 3 | US-141 |
| US-145 | Documentatie en store-teksten zonder scanner | Medium | 1 | US-136 |
| US-146 | [Fred] Store-vermeldingen bijwerken in de consoles | Medium | — | US-145 |
| US-147 | Verlanglijst filteren op formaattype | Low | 1 | US-143 |
| US-148 | Niet-verstuurde items automatisch opnieuw proberen | Medium | 2 | US-144 |
| US-149 | Automatisch importeren van Discogs | Medium | 5 | US-144 |

Totaal: 35 SP over 16 implementeerbare stories, plus één [Fred]-story.

## Groomingbesluiten

Gegroomd vanuit vier invalshoeken (product, ontwikkeling, test, UX). Wat er is veranderd ten opzichte van de eerste versie:

- **US-136 → US-136 + US-145.** Code verwijderen en documentatie bijwerken zijn los van elkaar op te leveren. De store-teksten stonden bovendien dubbel in US-137 en US-138 ("wie eerst komt doet het"); die staan nu één keer in US-145.
- **US-137 / US-138 → + US-146.** De console-acties in Play Console en App Store Connect kan alleen Fred doen en ze horen bij het indienen van de release, niet bij de code. Als eigen [Fred]-story blokkeren ze het afsluiten van de platformstories niet meer. US-137 en US-138 zijn daardoor elk 1 SP.
- **US-141: besluit genomen.** Standaardconditie blijft `Very Good` (optie a). Dat is exact wat er nu gebeurt als je op "Skip" tikt, dus geen gedragswijziging voor bestaande data. Een waarde "niet opgegeven" komt pas op de backlog als gebruikers erom vragen. Schatting naar 1 SP: het is alleen verwijderen.
- **US-143 → US-143 + US-147.** Collectie (gevraagd) en verlanglijst (niet gevraagd, zelfde afleiding) gesplitst. Besluit over oude opgeslagen filtersets: de typeafleiding wordt ook op de opgeslagen waarden toegepast bij het laden, dus `Vinyl, 12", 33 ⅓ RPM` wordt `Vinyl`. Geen migratie nodig.
- **US-144 → US-144 + US-148 + US-149.** Drie afzonderlijk bruikbare stappen: (1) de schakelaar en direct versturen bij toevoegen, (2) niet-verstuurde items later opnieuw proberen, (3) automatisch importeren. Na stap 1 heeft de gebruiker al wat hij het vaakst nodig heeft.
- **Niet gesplitst:** US-140 (verplaatsen zonder verversen levert een tab met verouderde cijfers op, dat is geen opleverbare tussenstap) en US-135/US-140 (blijven twee stories, maar worden direct na elkaar gedaan zodat er geen release met vier tabs uitgaat).
- **US-133 en US-142** beginnen elk met het verifiëren van de Discogs-parameter (`sort=year`, `format=Vinyl`) met één echte request. Werkt de parameter niet, dan stopt de story en volgt overleg; sorteren of filteren in de app is geen acceptabele terugvaloptie vanwege de paginering.

## Volgorde

- **Zoeken:** US-133 → US-142 → US-134. US-133 en US-142 raken dezelfde zoekparameters en cache-sleutel; US-134 gebruikt de sortering uit US-133. US-139 is onafhankelijk.
- **Scannen verwijderen:** US-135 → US-140 → US-136 → US-137, US-138, US-145 (die drie in willekeurige volgorde) → US-146 [Fred] bij het indienen.
- **Formaat:** US-143 → US-147.
- **Toevoegen en sync:** US-141 → US-144 → US-148 → US-149.

Versie: sprint 1 levert 1.1.0 (Minor per ADR-0003: featurebatch plus een verwijderde feature), sprint 2 levert 1.2.0 (auto-sync).

---

### US-133: Zoekresultaten sorteren op releasedatum

**Status: ✅ Resolved (2026-11-16)**

**Priority: High · 3 SP**

> Als verzamelaar,
> wil ik zoekresultaten kunnen sorteren op jaar (nieuwste eerst of oudste eerst),
> zodat ik bij het zoeken op een label snel de nieuwste of juist de vroegste releases vind.

**Context:**
[`searchReleases`](lib/infrastructure/discogs/discogs_api_client.dart#L71) stuurt nu geen sorteerparameter mee; Discogs geeft de resultaten dan op relevantie terug. Resultaten komen gepagineerd binnen (50 per pagina), dus sorteren in de app zou alleen de al geladen pagina's sorteren en bij doorscrollen verspringen. De sortering moet daarom server-side.

**Technische aanpak:**
- Discogs `/database/search` accepteert `sort=year` met `sort_order=asc|desc`. Dit staat niet in [DISCOGS_API.md](docs/api/DISCOGS_API.md): eerst met één echte request verifiëren en daarna daar vastleggen.
- Nieuwe enum (bijvoorbeeld `SearchSort { relevance, newestFirst, oldestFirst }`) naast [`SearchFilter`](lib/domain/models/search_filter.dart), doorgegeven via `DiscogsSearchService.search` naar de API-client.
- De sortering hoort bij de cache-sleutel in [`search_query_cache.dart`](lib/application/services/search_query_cache.dart), anders toont de cache resultaten in de verkeerde volgorde.

**Acceptance criteria:**
- Op het zoekscherm staat een sorteerkeuze met drie opties: Relevantie (standaard), Nieuwste eerst, Oudste eerst.
- De keuze werkt bij elk zoekfilter (alles, release, artiest, label), niet alleen bij label.
- Wisselen van sortering voert de huidige zoekopdracht opnieuw uit vanaf pagina 1; verder scrollen (volgende pagina's) houdt dezelfde sortering aan.
- Resultaten zonder jaar breken de lijst niet (ze staan waar Discogs ze plaatst).
- Gecachete resultaten van een andere sortering worden niet getoond voor de gekozen sortering.
- De labels zijn vertaald in alle vijf talen (ARB).
- Unit-test: de API-client stuurt de juiste `sort`/`sort_order` per optie en geen van beide bij Relevantie. Widget-test: wisselen van sortering triggert een nieuwe zoekopdracht.

**Buiten scope:** de sorteerkeuze bewaren in opgeslagen zoekopdrachten (US-117) of tussen app-sessies.

---

### US-134: Vanuit een release naar het label gaan

**Status: ✅ Resolved (2026-11-16)**

**Priority: High · 3 SP**

> Als verzamelaar,
> wil ik vanuit de release-informatie naar het label kunnen gaan,
> zodat ik alle releases van dat label overzichtelijk kan bekijken en meteen zie welke ik al heb.

**Context:**
[release_detail_screen.dart:1197-1202](lib/presentation/screens/release_detail_screen.dart#L1197-L1202) toont het label als platte tekst (`Label — catno`). Het zoekscherm kan al op label zoeken (`SearchFilter.label`) en toont per resultaat al of het in de collectie of op de verlanglijst staat ([search_screen.dart:993](lib/presentation/screens/search_screen.dart#L993)). Een aparte labelpagina is dus niet nodig: "naar het label gaan" is het zoekscherm openen met het labelfilter en de labelnaam ingevuld.

**Technische aanpak:**
- Labelregel in de release-informatie klikbaar maken (zichtbaar als link, met een chevron of link-icoon). Geen extra knop naast "Add to Collection" / "Add to Wishlist": die rij is al vol op smalle telefoons.
- Tik → terug naar de root van de zoektab met query = labelnaam, filter = Label en sortering = Nieuwste eerst (US-133).
- Het releasedetail zit onder `/search/release/:id`, dus dit blijft binnen dezelfde tab.

**Acceptance criteria:**
- De labelnaam in de release-informatie is klikbaar en als zodanig herkenbaar; het catalogusnummer hoort niet bij de zoekterm.
- Een tik opent de zoekresultaten voor dat label, met het Label-filter actief en de labelnaam in de zoekbalk.
- In die lijst is per release zichtbaar of hij al in de collectie staat (en of hij op de verlanglijst staat), met dezelfde iconen als bij gewoon zoeken.
- Voeg je vanuit die lijst een release toe en ga je terug, dan klopt de collectie-indicatie direct.
- Terugnavigeren vanaf de labelresultaten werkt voorspelbaar: de eerdere zoekopdracht is vervangen, er ontstaat geen stapel van detailschermen.
- Is er geen label bekend, dan is er geen klikbaar element.
- De klikbare regel heeft een semantisch label voor screenreaders ("Toon releases van <label>") en een raakvlak van minimaal 48 dp.
- Widget-tests: tik op het label → zoekscherm met juiste query, filter en sortering; release zonder label → geen link.

**Bekende beperking (vastleggen, niet oplossen):** zoeken op labelnaam is een tekstmatch. Labels met een veelvoorkomende naam geven ook releases van andere labels met dezelfde naam. Exact zoeken op label-id (`/labels/{id}/releases`) is een vervolgstory als dit in de praktijk stoort.

---

### US-135: Scannen uit het hoofdmenu halen

**Status: ✅ Resolved (2026-11-16)**

**Priority: High · 2 SP**

> Als gebruiker,
> wil ik een hoofdmenu zonder de weinig gebruikte Scannen-tab,
> zodat de navigatie alleen bevat wat ik echt gebruik.

**Context:**
De Scan-bestemming staat in [app_bottom_nav.dart](lib/presentation/widgets/app_bottom_nav.dart) (telefoon) en [app_nav_rail.dart](lib/presentation/widgets/app_nav_rail.dart) (breed scherm / iPad), en is branch 3 van de `StatefulShellRoute` in [router.dart](lib/app/router.dart). De navigatie-index is gelijk aan de branch-index: het verwijderen van alleen de bestemming laat Instellingen naar het scanscherm wijzen. Bestemming en branch moeten dus samen weg.

**Acceptance criteria:**
- Het hoofdmenu heeft vier items: Zoeken, Collectie, Verlanglijst, Instellingen. Dit geldt voor de onderbalk én de zijbalk.
- De Barcode-branch en de route `/barcode` zijn uit de router verwijderd; Instellingen opent Instellingen.
- Er is nergens in de app nog een ingang naar het scanscherm.
- `test/widget_test.dart` en `integration_test/qa_section_a_test.dart` (stap `a4_scan_tab`) zijn aangepast aan vier tabs.
- De l10n-sleutel `navScan` is verwijderd uit alle vijf ARB-bestanden.

**Buiten scope:** het scherm en de onderliggende code zelf (US-136).

---

### US-136: Barcodescanner-code en dependency verwijderen

**Status: ✅ Resolved (2026-11-16)**

**Priority: Medium · 2 SP**

> Als ontwikkelaar,
> wil ik dat alle code van de barcodescanner weg is,
> zodat we geen ongebruikte code, vertalingen en camera-dependency onderhouden.

**Context:**
Na US-135 is het scherm onbereikbaar. Wat overblijft:
- [barcode_scan_screen.dart](lib/presentation/screens/barcode_scan_screen.dart) (1136 regels) en de bijbehorende test;
- [barcode_lookup_use_case.dart](lib/application/use_cases/barcode_lookup_use_case.dart) en de test;
- `searchByBarcode` in [discogs_api_client.dart](lib/infrastructure/discogs/discogs_api_client.dart#L138) en de tests daarvan;
- 18 `barcode*`-sleutels per taal in de vijf ARB-bestanden;
- de dependency `mobile_scanner: ^7.2.0` in `pubspec.yaml`.

**Acceptance criteria:**
- De hierboven genoemde bestanden, methode en ARB-sleutels zijn verwijderd; `flutter gen-l10n` is opnieuw gedraaid.
- `mobile_scanner` staat niet meer in `pubspec.yaml` en `pubspec.lock`; de gegenereerde plugin-registraties (Android/iOS) bevatten de plugin niet meer.
- Een zoektocht naar `barcode`, `scan` en `mobile_scanner` in `lib/` en `test/` levert alleen nog treffers op die niets met de scanner te maken hebben (bijvoorbeeld het Discogs-veld `barcode` in release-metadata, als dat getoond wordt).
- Commentaar dat naar barcode-lookups verwijst (onder andere in [search_query_cache.dart](lib/application/services/search_query_cache.dart)) is bijgewerkt.
- Geen wijziging aan het Drift-schema; `schemaVersion` blijft gelijk. Eventuele oude barcode-rijen in de zoekcache blijven staan en verlopen vanzelf.
- `flutter analyze` 0 issues, `flutter test` groen.
- CHANGELOG vermeldt de scanner onder "Removed". Overige documentatie: US-145.

---

### US-137: Android — camerapermissie verwijderen

**Status: ✅ Resolved (2026-11-16)**

**Uitkomst:** release-APK vraagt alleen `INTERNET` (gecontroleerd met `aapt dump permissions`). Gevonden en opgelost: `INTERNET` kwam tot en met 1.0.4 alleen binnen via de ML Kit-dependency van de scanner (`transport-backend-cct`); zonder die dependency zou de release-build Discogs niet meer bereiken. De app declareert `INTERNET` nu zelf. Op een Pixel 10-emulator start de release-build en bereikt token-validatie Discogs. **Nog open voor [Fred]:** de tabs op een echt toestel doorlopen met een gekoppeld account (onboarding vraagt een echt token); hoort bij de toesteltest van de sprint.

**Priority: Medium · 1 SP**

> Als Android-gebruiker,
> wil ik dat de app geen cameratoegang meer vraagt of declareert,
> zodat de app niet meer rechten heeft dan hij gebruikt.

**Context:**
[AndroidManifest.xml:2-3](android/app/src/main/AndroidManifest.xml#L2-L3) declareert `android.permission.CAMERA` en `uses-feature android.hardware.camera`. Vereist US-136 (anders voegt de plugin de permissie opnieuw toe via manifest-merge).

**Acceptance criteria:**
- `CAMERA`-permissie en de camera-`uses-feature` zijn uit het manifest verwijderd.
- Het samengevoegde manifest van een release-build bevat geen camerapermissie (controleren met `aapt dump permissions` op de APK, of de merged-manifest-weergave).
- Release-build (`flutter build appbundle`) slaagt en de app start op een Android-toestel; alle tabs in het hoofdmenu werken.

**Buiten scope:** store-teksten en privacybeleid (US-145), Play Console (US-146).

---

### US-138: iOS — cameratoestemming verwijderen

**Status: ✅ Resolved (2026-11-16)**

**Uitkomst:** `NSCameraUsageDescription` verwijderd, `pod install` gedraaid (`Podfile.lock` bevatte de scanner nooit; die kwam via Swift Package Manager). Op besluit van Fred is de minimale iOS-versie naar 15.0 gegaan: de geïnstalleerde Xcode (SDK 27.2) bouwt niet meer voor 13.0. `flutter build ios --release --no-codesign` slaagt; de gebouwde app heeft geen camerasleutel, geen scanner-frameworks en `MinimumOSVersion` 15.0. De build start op een iPhone 17 Pro- en een iPad-simulator. **Nog open voor [Fred]:** `flutter build ipa` faalt op signing (lokaal provisioning-profiel "cratewise" hoort bij app-ID `cratewise`, de bundle is `app.cratewise`), en de tabs op een echt toestel doorlopen met een gekoppeld account. Bekend gereedschapsprobleem: `flutter build ios --simulator` (beide architecturen) faalt in Flutters framework-kopieerstap; bouwen voor één simulatortoestel werkt.

**Priority: Medium · 1 SP**

> Als iOS-gebruiker,
> wil ik dat de app geen cameratoestemming meer declareert,
> zodat de app niet meer rechten heeft dan hij gebruikt.

**Context:**
[Info.plist:44-45](ios/Runner/Info.plist#L44-L45) bevat `NSCameraUsageDescription`. Vereist US-136.

**Acceptance criteria:**
- `NSCameraUsageDescription` is uit `Info.plist` verwijderd.
- `pod install` is opnieuw gedraaid; `Podfile.lock` bevat `mobile_scanner` en de bijbehorende pods niet meer.
- Release-build (`flutter build ipa`) slaagt en de app start op iPhone en iPad; alle tabs werken in zowel de onderbalk als de zijbalk.

**Buiten scope:** store-teksten en privacybeleid (US-145), App Store Connect (US-146).

---

### US-139: Opnieuw op "Zoeken" tikken maakt de zoekbalk leeg

**Status: ✅ Resolved (2026-11-16)**

**Priority: Medium · 2 SP**

> Als gebruiker,
> wil ik dat een tik op "Zoeken" in het hoofdmenu, terwijl ik al op het zoekscherm ben, de zoekbalk leegmaakt,
> zodat ik met één tik aan een nieuwe zoekopdracht kan beginnen.

**Context:**
[`_onTabSelected`](lib/presentation/screens/home_shell_screen.dart#L14) roept bij een tik op de actieve tab `goBranch(index, initialLocation: true)` aan. Dat brengt je terug naar de root van de tab, maar het zoekscherm zelf merkt er niets van: query en resultaten blijven staan. Het zoekscherm heeft al een wis-knop in de zoekbalk (`_controller.clear`); deze story koppelt hetzelfde gedrag aan de tab.

**Acceptance criteria:**
- Sta je op het zoekscherm zelf (root van de tab) en tik je op "Zoeken", dan wordt de zoekbalk leeg, verdwijnen de resultaten (lege begintoestand) en krijgt de zoekbalk focus.
- Sta je op een releasedetail binnen de zoektab, dan brengt de eerste tik je terug naar de resultaten, zonder iets te wissen (bestaand gedrag). Pas een volgende tik wist.
- Een lopende zoekopdracht wordt geannuleerd, zodat er na het wissen geen resultaten alsnog binnenkomen.
- Het gekozen zoekfilter (Release / Artiest / Label) en de sortering blijven staan.
- Kom je van een andere tab naar Zoeken, dan wordt er niets gewist.
- Werkt hetzelfde in de onderbalk en in de zijbalk.
- Widget-tests dekken: tik op actieve tab op root → leeg; tik vanaf andere tab → query blijft; tik vanaf detail → terug naar resultaten met query intact.

---

### US-140: Collectiestatistieken als item in het hoofdmenu

**Status: ✅ Resolved (2026-11-16)**

**Priority: High · 3 SP**

> Als verzamelaar,
> wil ik de collectiestatistieken rechtstreeks vanuit het hoofdmenu openen,
> zodat ik ze niet hoef te zoeken achter een icoon op het collectiescherm.

**Context:**
De statistieken zijn nu een subroute van de collectietab (`/collection/statistics`, [router.dart:125](lib/app/router.dart#L125)) en alleen bereikbaar via het staafdiagram-icoon rechtsboven op het collectiescherm ([collection_screen.dart:310-315](lib/presentation/screens/collection_screen.dart#L310-L315)). Na US-135 is de vierde plek in het hoofdmenu vrij.

Twee dingen veranderen doordat het scherm een tab wordt:
- [collection_statistics_screen.dart:48](lib/presentation/screens/collection_statistics_screen.dart#L48) heeft een eigen `AppBar` met terugknop. Tab-schermen hebben sinds US-83 geen vaste titelbalk meer en een terugknop heeft daar geen betekenis.
- De shell is een `IndexedStack`: een tab blijft in het geheugen staan. Het scherm laadt de cijfers nu één keer bij het openen en zou als tab dus verouderde cijfers tonen nadat je iets aan de collectie toevoegt.

**Acceptance criteria:**
- Het hoofdmenu is: Zoeken, Collectie, Verlanglijst, Statistieken, Instellingen. Statistieken staat op de plek waar Scannen stond, in de onderbalk én in de zijbalk.
- De tab heeft een eigen icoon (staafdiagram) en een vertaald label in alle vijf talen (nieuwe ARB-sleutel `navStatistics`).
- Het statistiekenicoon rechtsboven op het collectiescherm is verwijderd; het icoon voor opgeslagen filters ernaast blijft.
- De subroute `/collection/statistics` en `AppRoutes.collectionStatistics` bestaan niet meer; de statistieken hebben een eigen branch (`/statistics`).
- Het scherm heeft als tab geen terugknop en volgt dezelfde opzet zonder vaste titelbalk als de andere tabs.
- De cijfers zijn actueel telkens als de tab zichtbaar wordt: voeg een release toe of verwijder er één, ga naar Statistieken, en het totaal klopt zonder de app te herstarten.
- De inhoud van het scherm (totalen, genre- en stijlstatistieken uit US-115 / US-123) verandert niet.
- Tests: `test/widget_test.dart` verwacht de vijf tabs in de nieuwe volgorde; een widget-test bewijst dat de statistieken verversen na een wijziging in de collectie; de test op `collection-stats-button` is verwijderd of aangepast.

**Buiten scope:** statistieken voor de verlanglijst, nieuwe grafieken.

---

### US-141: Geen "Set condition"-venster meer bij toevoegen aan collectie

**Status: ✅ Resolved (2026-11-16)**

**Priority: High · 1 SP**

> Als verzamelaar,
> wil ik dat een release direct in mijn collectie staat nadat ik op "Add to Collection" tik,
> zodat ik niet bij elke plaat eerst een venster moet wegklikken.

**Context:**
[`_handleAdd`](lib/presentation/screens/release_detail_screen.dart#L250) opent na elke geslaagde toevoeging `_showConditionPrompt`: een bottom sheet "Set condition" met twee keuzelijsten (Media, Sleeve) en de knoppen Skip / Save. Het item is op dat moment al opgeslagen met de standaardwaarden uit [add_to_collection_use_case.dart:60-61](lib/application/use_cases/add_to_collection_use_case.dart#L60-L61) (`veryGood` voor beide); het venster overschrijft die alleen. Conditie achteraf aanpassen kan al op het collectiedetail via "Edit conditions" ([collection_detail_screen.dart:354](lib/presentation/screens/collection_detail_screen.dart#L354)).

**Acceptance criteria:**
- Na "Add to Collection" verschijnt geen venster meer: de knop gaat naar "In Collection" en de melding "Added to your collection" verschijnt direct.
- `_showConditionPrompt`, `_ConditionPromptSheet` en `_ConditionDropdown` zijn uit `release_detail_screen.dart` verwijderd, voor zover ze nergens anders gebruikt worden.
- Media- en sleeve-conditie blijven bestaan als gegevens: aanpassen via "Edit conditions" op het collectiedetail, filteren (US-116), CSV-import/-export en Discogs-sync werken ongewijzigd.
- Geen wijziging aan het Drift-schema.
- Tests in `release_detail_screen_test.dart` die `condition-prompt-sheet`, `condition-skip-button` of `condition-save-button` gebruiken zijn verwijderd of herschreven naar het nieuwe gedrag; er is een test die bewijst dat na toevoegen geen bottom sheet opent.

**Besluit (grooming 2026-11-16):** nieuwe items houden de standaardwaarde `Very Good` voor media en sleeve. Dat is hetzelfde als nu op "Skip" tikken. Een waarde "niet opgegeven" raakt het domeinmodel, de CSV-mapping en de Discogs-sync en komt pas op de backlog als gebruikers erom vragen.

---

### US-142: Zoeken beperken tot vinyl

**Status: ✅ Resolved (2026-11-16)**

**Priority: High · 3 SP**

> Als vinylverzamelaar,
> wil ik in het zoeken kunnen kiezen dat ik alleen vinylreleases zie,
> zodat digitale releases ("File") de resultaten niet vervuilen.

**Context:**
[`searchReleases`](lib/infrastructure/discogs/discogs_api_client.dart#L71) stuurt `type=release` en geen formaat mee, dus Discogs geeft alle formaten terug: Vinyl, CD, Cassette en ook File (digitale releases). Het zoekresultaat bewaart alleen het eerste formaat ([discogs_search_result.dart:78-79](lib/infrastructure/discogs/dto/discogs_search_result.dart#L78-L79)). Filteren in de app zou per pagina van 50 een wisselend aantal resultaten overlaten en lege pagina's kunnen geven; het filter moet daarom server-side.

**Technische aanpak:**
- Discogs `/database/search` accepteert `format=Vinyl`. Vastleggen in [DISCOGS_API.md](docs/api/DISCOGS_API.md).
- Eén schakelaar "Alleen vinyl" naast de bestaande filterchips (Release / Artiest / Label). Deze is te combineren met die chips en met de sortering uit US-133; het is geen vierde waarde van `SearchFilter`.
- De keuze hoort bij de cache-sleutel in [`search_query_cache.dart`](lib/application/services/search_query_cache.dart).

**Acceptance criteria:**
- Op het zoekscherm staat een schakelaar "Alleen vinyl", te combineren met elk zoekfilter en elke sortering.
- Staat hij aan, dan bevatten de resultaten alleen releases met formaat Vinyl; releases met alleen "File" verschijnen niet. Dit geldt ook voor de volgende pagina's bij doorscrollen.
- Een release die zowel Vinyl als een ander formaat bevat (bijvoorbeeld LP + downloadcode) blijft zichtbaar.
- Omschakelen voert de huidige zoekopdracht opnieuw uit vanaf pagina 1.
- De keuze blijft bewaard tussen app-sessies. Standaard staat hij uit, zodat bestaande gebruikers na de update geen ander gedrag zien.
- Geen resultaten met het filter aan → de lege toestand noemt het filter en biedt aan het uit te zetten.
- Gecachete resultaten van de andere stand worden niet getoond.
- Vertaald in alle vijf talen.
- Tests: API-client stuurt `format=Vinyl` alleen als de schakelaar aan staat; widget-test voor omschakelen → nieuwe zoekopdracht; test voor de cache-sleutel.

**Buiten scope:** een vrije formaatkeuze (CD, Cassette, …); de schakelaar opnemen in opgeslagen zoekopdrachten (US-117).

---

### US-143: Collectie filteren op formaattype

**Status: ✅ Resolved (2026-11-16)**

**Priority: Medium · 2 SP**

> Als vinylverzamelaar,
> wil ik mijn collectie kunnen beperken tot vinyl,
> zodat digitale releases die via een Discogs-import zijn meegekomen niet tussen mijn platen staan.

**Context:**
Het filterblad heeft al een sectie "Format" ([collection_filter_sheet.dart:268-279](lib/presentation/widgets/collection_filter_sheet.dart#L268-L279), US-116), maar die is voor dit doel onbruikbaar. Het veld `format` van een collectie-item is een samengestelde tekst: per formaat `naam, omschrijvingen`, meerdere formaten gescheiden door een regeleinde ([discogs_collection_item.dart:83-101](lib/infrastructure/discogs/dto/discogs_collection_item.dart#L83-L101)), bijvoorbeeld `Vinyl, 12", 33 ⅓ RPM` of `File, MP3, 320 kbps`. Het filter vergelijkt op de exacte tekst ([collection_filter_set.dart:92-93](lib/domain/models/collection_filter_set.dart#L92-L93)), dus elke variant is een eigen chip en "alle vinyl" vraagt tientallen aangevinkte chips.

**Technische aanpak:**
- Formaat*type* afleiden uit de bestaande tekst: het deel vóór de eerste komma van elke regel (`Vinyl`, `File`, `CD`, …). Dit is pure domeinlogica op `CollectionItem`; geen schemawijziging en geen nieuwe import nodig.
- De Format-sectie in het filterblad toont formaattypes in plaats van volledige formaatteksten. "Alleen vinyl" is dan één chip.

**Acceptance criteria:**
- De Format-sectie in het collectiefilter toont één chip per formaattype dat in de collectie voorkomt (Vinyl, File, CD, …), niet per volledige formaattekst.
- Kies je alleen "Vinyl", dan toont de collectie uitsluitend items met minstens één vinylformaat; items met alleen "File" zijn verborgen.
- Een item met meerdere formaten (bijvoorbeeld Vinyl + File) telt mee bij elk van die types.
- Items zonder formaat verschijnen niet zodra er een formaatfilter actief is (bestaand gedrag).
- Het filter combineert met de andere filters, de sortering en het zoekveld van de collectie, en telt mee in de teller van actieve filters.
- Opgeslagen filtersets (US-117) met formaatwaarden in het oude formaat blijven werken: bij het laden wordt dezelfde typeafleiding op de opgeslagen waarden toegepast (`Vinyl, 12", 33 ⅓ RPM` → `Vinyl`). Geen datamigratie.
- De afleiding staat op één plek en is herbruikbaar voor de verlanglijst (US-147).
- Unit-tests voor het afleiden van het type: één formaat, meerdere formaten, alleen een naam zonder omschrijving, leeg/null. Widget-test: chip "Vinyl" verbergt een File-item.

**Buiten scope:** de verlanglijst (US-147).

---

### US-144: Instelling voor automatisch synchroniseren en direct versturen naar Discogs

**Status: ✅ Resolved (2026-11-16)**

**Priority: Medium · 3 SP**

> Als verzamelaar met een gekoppeld Discogs-account,
> wil ik een instelling waarmee een toevoeging aan mijn collectie of verlanglijst direct naar Discogs gaat,
> zodat ik niet na elke aankoop handmatig hoef te exporteren.

**Context:**
Toevoegen is nu puur lokaal: [`AddToCollectionUseCase`](lib/application/use_cases/add_to_collection_use_case.dart#L43) slaat het item op met `SyncStatus.localOnly` en doet geen API-call (de wishlist-variant werkt hetzelfde). Naar Discogs gaat het pas via Instellingen → Import & Export, met een preview en bevestiging. De call bestaat al: `addToCollection` / `addToWantlist` in de API-client, met back-off in [execute_collection_export_use_case.dart](lib/application/use_cases/execute_collection_export_use_case.dart#L248) en de wishlist-tegenhanger; na succes wordt het item `synced` en krijgt een collectie-item zijn `discogsInstanceId`. Wat ontbreekt is de trigger en de instelling. Voorkeuren worden nu bewaard via `FlutterSecureStorage` (zie [onboarding_service.dart](lib/application/services/onboarding_service.dart)); er is geen aparte settings-opslag.

Dit is de eerste van drie stories: US-148 (opnieuw proberen) en US-149 (importeren) hangen aan dezelfde schakelaar.

**Acceptance criteria:**

*Instelling*
- In Instellingen staat een schakelaar "Automatisch synchroniseren met Discogs", met een ondertitel die uitlegt wat er gebeurt. Vertaald in alle vijf talen.
- Standaard uit. De app schrijft pas zelfstandig naar iemands Discogs-account nadat de gebruiker dat heeft aangezet.
- Zonder gekoppeld Discogs-account is de schakelaar uitgeschakeld, met een verwijzing naar het koppelen.
- De keuze blijft bewaard tussen app-sessies.

*Direct versturen*
- Met de instelling aan gaat een nieuw collectie- of verlanglijstitem direct na het lokaal opslaan naar Discogs. Bij succes krijgt het `synced` (en de collectie het `discogsInstanceId`).
- Het toevoegen zelf wacht niet op Discogs: de knop en de melding reageren even snel als nu. De gebruiker hoeft niets te bevestigen.
- Mislukt de call (offline, rate limit, serverfout), dan blijft het item lokaal bewaard met de juiste syncstatus (`offline` of `failed`). Er gaat nooit een lokale toevoeging verloren door een netwerkfout. Handmatig exporteren pakt het item daarna gewoon op.
- Een release die al in de Discogs-collectie staat wordt niet nog een keer toegevoegd (Discogs staat meerdere exemplaren toe; de app mag geen duplicaten maken). Het lokale item neemt dan het bestaande `discogsInstanceId` over.
- Bij 401/403 gaat de schakelaar uit en ziet de gebruiker in Instellingen waarom.
- De call gebruikt dezelfde rate-limit- en back-off-policy als de handmatige export (ADR-0011).
- Met de instelling uit is het gedrag exact zoals nu: geen enkele API-call bij toevoegen.
- Tests: succes → `synced`; fout → item blijft met juiste status; al op Discogs → geen tweede exemplaar; instelling uit → geen API-call. Widget-test voor de schakelaar met en zonder gekoppeld account.

**Buiten scope:** automatisch opnieuw proberen (US-148), importeren (US-149), verwijderingen doorzetten (blijft de bewuste keuze uit US-72).

---

### US-145: Documentatie en store-teksten zonder scanner

**Status: ✅ Resolved (2026-11-16)**

**Priority: Medium · 1 SP**

> Als gebruiker die de store-pagina of het privacybeleid leest,
> wil ik dat daar alleen functies en rechten staan die de app echt heeft,
> zodat ik niet iets verwacht of toesta dat er niet meer is.

**Context:**
Afgesplitst uit US-136, US-137 en US-138. De scanner en het cameragebruik worden genoemd in `README.md`, `docs/store/STORE_LISTINGS.md`, `docs/store/STORE_COPY_OPTIONS.md`, `docs/store/PRIVACY_POLICY.md`, `docs/release/STORE_REVIEW.md`, `docs/release/RELEASE_BUILD.md` en `docs/release/RELEASE_CHECKLIST.md`.

**Acceptance criteria:**
- Geen van deze bestanden noemt barcodescannen nog als functie.
- Het privacybeleid en de store-reviewnotities vermelden geen cameragebruik meer.
- De release-checklist bevat geen teststap voor de scanner of de cameratoestemming meer.
- Staat het privacybeleid ook op de Cratewise-website (11ty), dan is die pagina uit dezelfde bron bijgewerkt.
- De nieuwe functies van deze release (sorteren, alleen vinyl, statistieken in het menu) staan in de store-teksten waar de scanner eerst stond, in alle talen waarin de store-teksten bestaan.

---

### US-146: [Fred] Store-vermeldingen bijwerken in Play Console en App Store Connect

**Status: ⛔ Gesloten — vervallen (2026-11-16)**

**Reden:** besluit van Fred: er gaan geen nieuwe releases meer naar de App Store en Google Play. Daarmee hoeven de store-vermeldingen niet meer bijgewerkt te worden.

**Priority: Medium · [Fred]**

> Als uitgever van de app,
> wil ik dat de store-vermeldingen overeenkomen met de app zonder scanner,
> zodat de review niet wordt afgekeurd op een onjuiste beschrijving of privacyverklaring.

**Context:**
Afgesplitst uit US-137 en US-138. Dit kan alleen in de consoles en hoort bij het indienen van 1.1.0. Vereist US-145 voor de teksten en een build waarin US-136, US-137 en US-138 zitten.

**Acceptance criteria:**
- Play Console: beschrijving bijgewerkt, screenshots met de Scan-tab vervangen, Data safety-verklaring zonder camera.
- App Store Connect: beschrijving bijgewerkt, screenshots met de Scan-tab vervangen (iPhone en iPad), App Privacy-antwoorden zonder camera.
- De ingediende build vraagt op geen van beide platforms cameratoegang.

---

### US-147: Verlanglijst filteren op formaattype

**Status: ✅ Resolved (2026-11-16)**

**Priority: Low · 1 SP**

> Als vinylverzamelaar,
> wil ik mijn verlanglijst op formaattype kunnen filteren,
> zodat het filter daar hetzelfde werkt als in mijn collectie.

**Context:**
Afgesplitst uit US-143. De verlanglijst vergelijkt net als de collectie op de volledige formaattekst ([wishlist_filter_set.dart:63-64](lib/domain/models/wishlist_filter_set.dart#L63-L64)). Vereist de typeafleiding uit US-143.

**Acceptance criteria:**
- De Format-sectie in het verlanglijstfilter toont één chip per formaattype, met dezelfde afleiding als US-143 (geen tweede implementatie).
- Kies je "Vinyl", dan zijn items met alleen "File" verborgen; een item met meerdere formaten telt mee bij elk type.
- Opgeslagen verlanglijst-filtersets met oude formaatwaarden blijven werken, op dezelfde manier als in US-143.
- Unit-test op het filter en een widget-test dat de chip "Vinyl" een File-item verbergt.

---

### US-148: Niet-verstuurde items automatisch opnieuw proberen

**Status: ✅ Resolved (2026-11-16)**

**Afwijking van de AC (bewust):** een item dat blijft mislukken staat met de reden in de geschiedenisregel van die run (Import/Export-geschiedenis), niet bij "Mislukte acties". Dat scherm is voor mislukte lokale opslag; de knop Opnieuw proberen slaat daar opnieuw lokaal op, wat voor een verzending naar Discogs de verkeerde actie is. Het item zelf blijft `failed`/`offline` en gaat bij de volgende run opnieuw mee.

**Priority: Medium · 2 SP**

> Als verzamelaar die platen toevoegt zonder bereik (in een platenzaak, op een beurs),
> wil ik dat items die niet naar Discogs konden alsnog vanzelf verstuurd worden,
> zodat ik er niet aan hoef te denken om later te exporteren.

**Context:**
Afgesplitst uit US-144. Na US-144 blijft een item waarvan de call mislukte op `offline` of `failed` staan tot de gebruiker handmatig exporteert. Vereist US-144.

**Acceptance criteria:**
- Met de instelling aan worden bij het openen van de app, en bij terugkeer naar de voorgrond (hooguit één keer per 15 minuten), alle collectie- en verlanglijstitems met status `localOnly`, `failed` of `offline` naar Discogs gestuurd.
- Dit geldt ook voor items die al lokaal stonden voordat de instelling werd aangezet. Bij het aanzetten van de schakelaar ziet de gebruiker hoeveel bestaande items daardoor verstuurd gaan worden en bevestigt dat één keer.
- De run loopt op de achtergrond; de app blijft bruikbaar. Hij start niet terwijl een handmatige import of export loopt.
- Zelfde duplicaatregel als US-144: wat al op Discogs staat wordt niet nog eens toegevoegd.
- Een item dat blijft mislukken houdt de run niet tegen; het blijft `failed` en is zichtbaar bij de bestaande mislukte acties.
- De run staat in de Import/Export-geschiedenis met het aantal verstuurde en mislukte items.
- Met de instelling uit gebeurt er niets.
- Tests: mix van statussen → alleen niet-verstuurde items gaan; één fout blokkeert de rest niet; binnen 15 minuten geen tweede run; instelling uit → geen API-call.

---

### US-149: Automatisch importeren van Discogs

**Status: ✅ Resolved (2026-11-16)**

**Uitkomst:** de automatische import hergebruikt de stappen van de handmatige import (ophalen, classificeren, uitvoeren), dus dezelfde regels voor duplicaten, koppelen en openstaande verwijderingen. Alleen nieuwe releases en koppelingen gaan mee; al aanwezige platen leveren geen geschiedenisregels op. Automatische imports staan in de geschiedenis als "Import collection/wishlist from Discogs", zonder onderscheid met handmatige imports.

**Priority: Medium · 5 SP**

> Als verzamelaar die ook op de Discogs-website platen toevoegt,
> wil ik dat die toevoegingen vanzelf in de app verschijnen,
> zodat mijn collectie en verlanglijst in de app compleet zijn zonder handmatige import.

**Context:**
Afgesplitst uit US-144. De import-use-cases bestaan en weten al dat een lokaal verwijderde release (tombstone, US-72) niet opnieuw geïmporteerd mag worden, maar ze draaien alleen na een preview en bevestiging. Deze story laat het toevoegende deel daarvan automatisch lopen. Vereist US-144; deelt het startmoment en de 15-minutengrens met US-148.

**Acceptance criteria:**
- Met de instelling aan haalt de app bij het openen (en bij terugkeer naar de voorgrond, hooguit één keer per 15 minuten) collectie en verlanglijst op en voegt releases toe die op Discogs staan maar lokaal nog niet. Er is geen preview-scherm.
- De automatische import voegt alleen toe. Hij overschrijft geen lokale velden (conditie, notities, tags, DJ-velden) en verwijdert lokaal niets, ook niet als een release op Discogs is verwijderd.
- Een release met een openstaande lokale verwijdering (tombstone) wordt niet opnieuw geïmporteerd.
- Volgorde binnen één run: eerst versturen (US-148), dan importeren, zodat een net toegevoegd item niet als "nieuw op Discogs" terugkomt.
- De import loopt op de achtergrond; de app blijft bruikbaar en lijsten verversen als er items bijkomen. Zichtbaar zijn: dat er gesynchroniseerd wordt, en het resultaat of de fout van de laatste run (tijdstip, aantal toegevoegd).
- Een grote collectie (meer dan 1000 items, meerdere pagina's) blokkeert de app niet en respecteert de rate limit (ADR-0011). Wordt de run onderbroken, dan is wat al binnen is bewaard en gaat de volgende run verder zonder duplicaten.
- De run start niet terwijl een handmatige import of export loopt, en staat in de Import/Export-geschiedenis.
- De handmatige import met preview blijft bestaan.
- Tests: nieuw remote item → toegevoegd; bestaand item → ongewijzigd; tombstone → overgeslagen; onderbroken run → geen duplicaten bij herhaling; instelling uit → geen API-call.

**Buiten scope:** wijzigingen aan bestaande items overnemen, conflictoplossing en remote verwijderingen. Dat is US-119.
