# Phase 19: Filteren en sorteren gelijk op Zoeken, Collectie en Verlanglijst (november 2026)

Aangemaakt: 2026-11-17 · Gegroomd: 2026-11-17 · Bijgewerkt na besluiten Fred: 2026-11-17

Doel: gebruikersfeedback verwerken. Op alle drie de lijstschermen werkt filteren en sorteren hetzelfde: één filterknop naast de zoekbalk, die een bottom sheet opent met bovenaan de sortering en daaronder de filters van dat scherm. Daarnaast verdwijnen de DJ-velden (BPM, Key, Energy) uit de app. Nummering loopt door vanaf US-160.

## Overzicht

| Story | Titel | Prio | SP | Hangt af van |
|---|---|---|---|---|
| US-161 | Zoeken: filters in een bottom sheet achter één filterknop | High | 3 | — |
| US-162 | Zoeken: sortering bovenaan in de sheet; Nieuwste/Oudste eerst op datum toegevoegd aan Discogs | High | 2 | US-161 |
| US-165 | DJ-velden BPM, Key, Energy en gig crates uit de app verwijderen | High | 5 | — |
| US-166 | Collectie en Verlanglijst: datum toegevoegd overnemen bij import van Discogs | Medium | 2 | — |
| US-163 | Collectie: sorteericoon weg, Nieuwste/Oudste eerst bovenaan in "Filter collection" | High | 2 | US-162, US-165, US-166 |
| US-164 | Verlanglijst: Nieuwste/Oudste eerst bovenaan in het filter | Medium | 2 | US-162, US-166 |
| US-167 | Bug: "Ongedaan maken"-balk na verwijderen van een opgeslagen zoekopdracht verdwijnt niet | High | 1 | — |

Totaal: 17 SP. Volgorde: US-167 eerst (bug, los van de rest), daarna US-161 → US-162 → US-165 → US-166 → US-163 → US-164.

## Besluiten

**Van Fred (2026-11-17):**
- **Sorteeropties per scherm.**
  - Zoeken: Relevantie (standaard), Nieuwste eerst, Oudste eerst. Nieuwste/Oudste eerst gaat over **wanneer de release aan Discogs is toegevoegd**, niet over het releasejaar.
  - Collectie en Verlanglijst: alleen Nieuwste eerst (standaard) en Oudste eerst, op **de datum waarop je de plaat aan je eigen collectie/verlanglijst toevoegde**; niet de bewerkingsdatum op Discogs. Geen Relevantie.
- **DJ-velden weg.** BPM, Key, Energy en gig crates verdwijnen uit de hele app (eigen story, US-165). Reden: gebruikers kunnen op Discogs zelf velden toevoegen; deze velden in Cratewise maken het ingewikkeld.

**Uit de grooming (product, ontwikkeling, test, UX; voorstellen tot Fred ze bevestigt):**
- **Eén opzet voor drie schermen.** Elke sheet: (1) Sorteren, (2) de filters van dat scherm, (3) "Alles wissen" en "Toepassen". De sorteersectie is één gedeelde widget die per scherm een lijst opties krijgt (Zoeken drie, Collectie/Verlanglijst twee).
- **Toepassen-knop.** Collectie- en verlanglijstfilter werken al zo; Zoeken volgt, zodat alle drie gelijk zijn en Zoeken niet bij elke tik Discogs bevraagt.
- **Badge.** De filterknop telt actieve filters; een sortering die niet de standaard van dat scherm is (Relevantie bij Zoeken, Nieuwste eerst bij Collectie/Verlanglijst) telt als één mee.
- **Discogs-sortering geverifieerd.** `/database/search` accepteert `sort=date_added&sort_order=desc|asc` (getest 2026-11-17: aflopend geeft de hoogste release-ID's, oplopend de laagste). `sort=added` wordt genegeerd. Vastleggen in `docs/api/DISCOGS_API.md`.
- **"Zoeken, Collectie en Filter pagina"** in de feedback is gelezen als Zoeken, Collectie en Verlanglijst.
- **Buiten scope:** sortering bewaren tussen sessies of in opgeslagen filters/zoekopdrachten (US-117); nieuwe sorteeropties.

## Besloten open punten (Fred, 2026-11-17)

1. **Datum toegevoegd bij geïmporteerde platen:** akkoord. Bij import wordt de datum overgenomen waarop de plaat aan de collectie/wantlist op Discogs is toegevoegd (US-166).
2. **Gig crates:** mogen ook weg; meegenomen in US-165.

---

### US-161: Zoeken: filters in een bottom sheet achter één filterknop

**Status: ✅ Resolved (2026-11-17)** — samen met US-162 gebouwd (één sheet). Gekozen: Toepassen-knop, zoals bij Collectie.

**Priority: High · 3 SP**

> Als gebruiker,
> wil ik op het zoekscherm één filterknop in plaats van een rij chips,
> zodat het scherm rustiger is en filteren hetzelfde werkt als op het collectiescherm.

**Context:**
De chips Release / Artiest / Label (US-84/85) en "Alleen vinyl" (US-142) staan nu onder de zoekbalk in [search_screen.dart](lib/presentation/screens/search_screen.dart) (`_SearchFilterChips`). Het collectiescherm heeft al het gewenste patroon: een `IconButton` met `Icons.filter_list_outlined` en een `Badge` met het aantal actieve filters ([collection_screen.dart:274](lib/presentation/screens/collection_screen.dart#L274)).

**Acceptance criteria:**
- De chiprij onder de zoekbalk is weg. Naast de zoekbalk staat één filterknop met hetzelfde icoon en dezelfde badge als op het collectiescherm.
- De knop opent een bottom sheet met:
  - "Zoeken in": Release, Artiest, Label (één keuze; niets gekozen = alles, zoals nu);
  - de schakelaar "Alleen vinyl";
  - "Alles wissen" en "Toepassen".
- Toepassen voert de huidige zoekopdracht opnieuw uit vanaf pagina 1; sluiten zonder Toepassen verandert niets.
- Badge: gekozen zoekveld = 1, Alleen vinyl = 1; zonder actieve filters geen badge.
- Bestaand gedrag blijft: "Alleen vinyl" wordt onthouden tussen sessies; het zoekveld leegmaken zet "Zoeken in" terug naar alles; de label-link vanuit een release (US-134) zet het Label-filter; opnieuw tikken op de Zoeken-tab (US-139) behoudt de filters; opgeslagen zoekopdrachten herstellen hun filter; de lege toestand bij "Alleen vinyl" biedt nog steeds "alle formaten tonen".
- Werkt in het smalle zoekpaneel op iPad (320 dp) en op de telefoon.
- Teksten vertaald in alle vijf talen; knop heeft een tooltip/semantisch label.
- Tests: sheet openen, elk filter kiezen + Toepassen → nieuwe zoekopdracht met dat filter, sluiten zonder Toepassen → geen zoekopdracht, badge-telling; bestaande chip-tests herschreven. Live Discogs-test (`integration_test/discogs_live_test.dart`) aangepast.

---

### US-162: Zoeken: sortering bovenaan in de sheet; Nieuwste/Oudste eerst op datum toegevoegd aan Discogs

**Status: ✅ Resolved (2026-11-17)** — gedeelde `SortSection` in `filter_sheet_parts.dart`; `sort=date_added` live geverifieerd en in `DISCOGS_API.md`.

**Priority: High · 2 SP**

> Als gebruiker,
> wil ik de sortering bovenaan in de filter-sheet, en bij Nieuwste/Oudste eerst de releases zien op volgorde van toevoegen aan Discogs,
> zodat ik op het zoekscherm maar één knop heb en net toegevoegde releases makkelijk vind.

**Context:**
De sortering (US-133) is nu een apart menu (`_SearchSortMenu`) en sorteert Nieuwste/Oudste eerst op **releasejaar** (`sort=year`). Dat verandert naar datum toegevoegd aan Discogs (`sort=date_added`, geverifieerd 2026-11-17). Deze story bouwt ook de gedeelde sorteersectie voor US-163 en US-164.

**Acceptance criteria:**
- Het losse sorteermenu is weg. De sheet uit US-161 begint met "Sorteren": Relevantie (standaard), Nieuwste eerst, Oudste eerst (één keuze).
- Nieuwste/Oudste eerst sturen `sort=date_added` met `sort_order=desc|asc` naar Discogs (in plaats van `sort=year`); doorscrollen houdt de sortering aan. `DISCOGS_API.md` bijgewerkt.
- De sorteersectie is één herbruikbare widget die een lijst opties krijgt (labels en vertalingen op één plek).
- Een andere sortering dan Relevantie telt als 1 mee in de badge; "Alles wissen" zet terug op Relevantie.
- De label-link (US-134) opent de labelresultaten met Nieuwste eerst (nu: laatst aan Discogs toegevoegd).
- Het zoekscherm heeft daarna precies één knop voor filteren en sorteren (naast de knoppen voor opgeslagen zoekopdrachten).
- CHANGELOG vermeldt dat Nieuwste/Oudste eerst bij Zoeken nu op datum toegevoegd aan Discogs sorteert in plaats van op jaar.
- Tests: API-client stuurt `sort=date_added` met de juiste richting en niets bij Relevantie; sortering kiezen in de sheet → zoekopdracht met die sortering; badge telt mee; bestaande sorteertests herschreven; live Discogs-test aangepast.

---

### US-165: DJ-velden BPM, Key, Energy en gig crates uit de app verwijderen

**Status: ✅ Resolved (2026-11-17)** — schema 13; CHANGELOG/README volgen bij de versie-bump aan het eind van de fase.

**Priority: High · 5 SP**

> Als verzamelaar,
> wil ik geen BPM-, Key-, Energy- en gig-crate-velden meer in Cratewise,
> zodat de app eenvoudiger is; wie zulke gegevens wil bijhouden, doet dat met eigen velden op Discogs.

**Context:**
Toegevoegd in US-121. De velden zitten in het domeinmodel (`CollectionItem.bpm`, `musicalKey`, `energyLevel`, `gigCrates`), de database (kolommen sinds schema v11), het collectiedetail (bewerkblad en weergave), de filters (BPM min/max, Key, Energy, Gig crate), de sortering (BPM, Key, Energy in `CollectionSort`), en CSV-import/-export (`collection_csv_mapper`, `collection_csv_validator`). Gig crates zijn op verzoek van Fred meegenomen (2026-11-17).

**Acceptance criteria:**
- Nergens in de app nog BPM, Key, Energy of gig crates: niet in het collectiedetail, niet in het filter, niet in de sortering, niet in de CSV-export.
- `CollectionItem`, `CollectionFilterSet` en `CollectionSort` hebben de velden en opties (inclusief `gigCrates`) niet meer; `MusicalKey` is verwijderd als niets anders het gebruikt.
- **Database:** de kolommen worden verwijderd met een schemamigratie (`schemaVersion` + 1, nieuwe schema-dump in `drift_schemas/`, gegenereerde testhelpers volgens `migration_test.dart`). De migratietest bewijst dat alle andere velden van bestaande items intact blijven. De ingevoerde DJ-waarden en gig crates gaan daarbij bewust verloren.
- **Oude bestanden blijven werken:** een CSV-import met de oude kolommen BPM/Key/Energy/gig crates slaagt; die kolommen worden genegeerd. Opgeslagen filtersets (US-117) met die waarden laden zonder fout; die waarden vallen weg.
- CHANGELOG (onder "Removed") en README bijgewerkt; de opmerking in de CHANGELOG zegt dat eerder ingevoerde BPM/Key/Energy-waarden en gig crates verdwijnen.
- Tests: bestaande DJ-tests verwijderd of herschreven; nieuwe tests voor CSV met oude DJ-kolommen en voor oude filtersets; migratietest naar de nieuwe schemaversie; upgrade-test (`integration_test/app_upgrade_test.dart`) slaagt op Android en iOS.

---

### US-166: Collectie en Verlanglijst: datum toegevoegd overnemen bij import van Discogs

**Status: ✅ Resolved (2026-11-17)** — let op: al gekoppelde platen krijgen hun Discogs-datum bij een **handmatige** import; de automatische import slaat al aanwezige platen bewust over (US-149), dus één handmatige import corrigeert een eerder geïmporteerde collectie.

**Priority: Medium · 2 SP**

> Als verzamelaar die zijn collectie uit Discogs heeft geïmporteerd,
> wil ik dat Nieuwste/Oudste eerst de volgorde volgt waarin ik de platen aan mijn collectie toevoegde,
> zodat sorteren ook zin heeft voor platen die in één keer zijn geïmporteerd.

**Context:**
Voorwaarde voor US-163 en US-164; akkoord van Fred 2026-11-17. De Discogs-import zet nu `createdAt: now` ([execute_collection_import_use_case.dart:85](lib/application/use_cases/execute_collection_import_use_case.dart#L85), wishlist-tegenhanger idem), terwijl de Discogs-collectie en -wantlist per plaat `date_added` meeleveren (al in de DTO's: `DiscogsCollectionItemDto.dateAdded`, `DiscogsWantlistItemDto.dateAdded`).

**Acceptance criteria:**
- Nieuwe imports (handmatig en automatisch, US-149) zetten `createdAt` op de `date_added` van Discogs; als die ontbreekt of niet te lezen is, op het importmoment.
- Platen die je in de app toevoegt houden het moment van toevoegen (ongewijzigd).
- Bestaande, al geïmporteerde items worden niet stilzwijgend aangepast. Bij een volgende import van een plaat die al lokaal gekoppeld is, wordt `createdAt` bijgewerkt naar de Discogs-datum als die vroeger is dan de huidige waarde; andere velden blijven ongemoeid.
- Tests: import zet de Discogs-datum; ontbrekende datum valt terug op nu; tijdzone-notatie van Discogs (`2026-11-01T10:00:00-07:00`) wordt goed gelezen; koppeling werkt een te late datum bij en laat een vroegere staan.

---

### US-163: Collectie: sorteericoon weg, Nieuwste/Oudste eerst bovenaan in "Filter collection"

**Status: ✅ Resolved (2026-11-17)** — gedeelde `AddedDateSort`; de regel met actieve filters boven de lijst toont de sortering niet, de badge maakt hem zichtbaar (zoals bij Zoeken).

**Priority: High · 2 SP**

> Als verzamelaar,
> wil ik op de collectiepagina sorteren via het filter,
> zodat er één icoon minder staat en sorteren hetzelfde werkt als bij Zoeken.

**Context:**
Naast de zoekbalk staan drie iconen: filter, sorteren (`collection-sort-button`, [collection_screen.dart:283](lib/presentation/screens/collection_screen.dart#L283)) en opgeslagen filters. Het middelste verdwijnt. Na US-165 heeft `CollectionSort` geen DJ-opties meer; na US-166 betekent "toegevoegd" ook bij geïmporteerde platen iets.

**Acceptance criteria:**
- Het sorteericoon is weg; naast de zoekbalk staan nog twee iconen (filter, opgeslagen filters).
- "Filter collection" begint met de gedeelde sectie "Sorteren" (uit US-162) met twee opties: Nieuwste eerst (standaard) en Oudste eerst, op de datum waarop de plaat aan de collectie is toegevoegd (`createdAt`). Geen Relevantie.
- De sortering wordt met Toepassen doorgevoerd, combineert met alle filters en het zoekveld, telt als 1 mee in de badge als hij op Oudste eerst staat, en "Alles wissen" zet hem terug op Nieuwste eerst.
- Labels vertaald in alle vijf talen (de huidige sorteerlabels zijn hardcoded Engels).
- Tests: unit-test voor oplopend en aflopend op `createdAt`; widget-tests: geen sorteericoon meer, sortering kiezen in de sheet herordent de lijst, badge telt mee; bestaande tests op `collection-sort-button` herschreven.

**Buiten scope:** sortering opslaan in opgeslagen filtersets (US-117) of tussen sessies.

---

### US-164: Verlanglijst: Nieuwste/Oudste eerst bovenaan in het filter

**Status: In Progress**

**Priority: Medium · 2 SP**

> Als verzamelaar,
> wil ik mijn verlanglijst kunnen sorteren op wanneer ik platen toevoegde,
> zodat de verlanglijst hetzelfde werkt als de collectie.

**Context:**
De verlanglijst heeft een filterknop (`wishlist-filter-button`) en opgeslagen filters, maar geen sortering; de volgorde is vast (laatst toegevoegd eerst).

**Acceptance criteria:**
- Het verlanglijstfilter begint met de gedeelde sectie "Sorteren": Nieuwste eerst (standaard, = huidige volgorde) en Oudste eerst, op `createdAt`. Geen Relevantie.
- Zelfde gedrag als US-163: Toepassen, combineert met filters en zoekveld, telt mee in de badge, "Alles wissen" zet terug op Nieuwste eerst.
- Sorteren op `createdAt` gebruikt dezelfde code als US-163 (geen tweede implementatie).
- Vertaald in alle vijf talen.
- Tests: unit-test dat de gedeelde sortering op `WishlistItem` werkt; widget-test dat Oudste eerst de lijst omdraait en de badge bijwerkt.

---

### US-167: Bug: "Ongedaan maken"-balk na verwijderen van een opgeslagen zoekopdracht verdwijnt niet

**Status: ✅ Resolved (2026-11-17)** — oorzaak bevestigd: `SnackBar` met actie is sinds Flutter 3.29 standaard `persist`. Beide snackbars met een actie (opgeslagen zoekopdrachten, import/export-geschiedenis) staan op `persist: false`. In de geschiedenis werd een verwijdering daardoor ook nooit definitief; ook opgelost.

**Priority: High · 1 SP**

> Als gebruiker,
> wil ik dat de balk "… deleted · Undo" na het verwijderen van een opgeslagen zoekopdracht na een paar seconden vanzelf verdwijnt,
> zodat hij niet blijft hangen over Zoeken, Collectie en Verlanglijst.

**Context:**
Gebruikersfeedback (2026-11-17): na het verwijderen van een saved search blijft de undo-balk permanent in beeld, op Zoeken, Collectie en Verlanglijst. Waarschijnlijke oorzaak: sinds Flutter 3.29 sluit een `SnackBar` met een actie niet meer vanzelf (`persist` is dan standaard `true`). [`_delete` in saved_searches_screen.dart](lib/presentation/screens/saved_searches_screen.dart#L75) toont zo'n snackbar zonder `duration` of `persist`. Hij hangt aan de app-brede `ScaffoldMessenger`, dus hij blijft ook staan na terugkeren naar het lijstscherm. Hetzelfde patroon staat in [import_export_history_screen.dart:132](lib/presentation/screens/import_export_history_screen.dart#L132) (Undo-actie zonder werking). Eerst de oorzaak bevestigen met een test die het probleem laat zien.

**Acceptance criteria:**
- De undo-balk na het verwijderen van een opgeslagen zoekopdracht verdwijnt na ongeveer 4 seconden vanzelf, ook als de gebruiker intussen teruggaat naar Zoeken, Collectie of Verlanglijst.
- "Undo" binnen die tijd zet de opgeslagen zoekopdracht terug (bestaand gedrag).
- Dezelfde fix voor alle snackbars met een actie in de app (ten minste `import_export_history_screen.dart`); een Undo-knop die niets doet wordt weggehaald of laten werken.
- Tests: widget-test die faalt vóór de fix (balk blijft staan) en slaagt erna (balk weg na de duur); test dat Undo binnen de tijd herstelt; controle op de andere snackbar(s) met een actie.

