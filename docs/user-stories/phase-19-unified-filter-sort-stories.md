# Phase 19: Filteren en sorteren gelijk op Zoeken, Collectie en Verlanglijst (november 2026)

Aangemaakt: 2026-11-17 · Gegroomd: 2026-11-17

Doel: gebruikersfeedback verwerken. Op alle drie de lijstschermen werkt filteren en sorteren hetzelfde: één filterknop naast de zoekbalk, die een bottom sheet opent met bovenaan de sortering (Relevantie, Nieuwste eerst, Oudste eerst) en daaronder de filters van dat scherm. Nummering loopt door vanaf US-160.

## Overzicht na grooming

| Story | Titel | Prio | SP | Hangt af van |
|---|---|---|---|---|
| US-161 | Zoeken: filters in een bottom sheet achter één filterknop | High | 3 | — |
| US-162 | Zoeken: sortering bovenaan in dezelfde sheet (gedeelde sorteersectie) | High | 2 | US-161 |
| US-163 | Collectie: sorteericoon weg, sortering bovenaan in "Filter collection" | High | 3 | US-162 |
| US-164 | Verlanglijst: sortering bovenaan in het filter | Medium | 2 | US-162 |

Totaal: 10 SP. Volgorde: US-161 → US-162 → US-163 → US-164.

## Groomingbesluiten

Gegroomd vanuit vier invalshoeken (product, ontwikkeling, test, UX); er is geen apart team, dus dit zijn voorstellen tot Fred ze bevestigt.

- **Eén opzet voor drie schermen.** Elke sheet heeft dezelfde volgorde: (1) Sorteren, (2) de filters van het scherm, (3) "Alles wissen" en "Toepassen". De sorteersectie is één gedeelde widget, gebouwd in US-162 en hergebruikt in US-163 en US-164; geen drie kopieën.
- **Toepassen-knop, niet direct toepassen.** Het collectie- en verlanglijstfilter werken al met Toepassen; Zoeken volgt dat, zodat alle drie gelijk zijn. Bij Zoeken scheelt het ook onnodige Discogs-aanvragen bij elke tik.
- **Zelfde betekenis op elk scherm.** "Nieuwste eerst" en "Oudste eerst" sorteren overal op **releasejaar** (zo werkt het al bij Zoeken). Platen zonder jaar staan achteraan.
- **"Relevantie" op Collectie en Verlanglijst** is de standaardvolgorde van nu: laatst toegevoegd bovenaan. Let op: op de collectie heet die volgorde nu "Newest first" (op datum van toevoegen). Die naam verschuift dus: wat nu "Newest first" is wordt "Relevantie", en "Nieuwste eerst" gaat op releasejaar sorteren. **Te bevestigen door Fred**, zie open punt 1.
- **DJ-sorteringen blijven.** Het sorteericoon op de collectie bevat ook BPM, Key en Energy (US-121). Die verhuizen mee naar de sorteersectie van de collectie, onder de drie standaardopties, en alleen als er DJ-gegevens zijn (zoals de DJ-filters nu). Zie open punt 2.
- **Badge.** De filterknop telt actieve filters; een andere sortering dan Relevantie telt als één mee. Zo is zonder los sorteericoon toch zichtbaar dat de lijst gesorteerd is.
- **"Zoeken, Collectie en Filter pagina"** in de feedback is gelezen als Zoeken, Collectie en Verlanglijst.
- **Buiten scope voor deze fase:** sortering bewaren tussen sessies en in opgeslagen filters/zoekopdrachten (US-117); nieuwe sorteeropties (artiest, titel).

## Open punten voor Fred

1. Akkoord dat "Nieuwste/Oudste eerst" overal op releasejaar sorteert en dat "Relevantie" op Collectie en Verlanglijst "laatst toegevoegd eerst" betekent? Alternatief: daar een eigen naam ("Laatst toegevoegd"), ten koste van de gelijke labels.
2. Akkoord dat BPM, Key en Energy als extra sorteeropties in de collectie-sheet blijven? Alternatief: schrappen.

---

### US-161: Zoeken: filters in een bottom sheet achter één filterknop

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

### US-162: Zoeken: sortering bovenaan in dezelfde sheet (gedeelde sorteersectie)

**Priority: High · 2 SP**

> Als gebruiker,
> wil ik de sortering (Relevantie, Nieuwste eerst, Oudste eerst) bovenaan in de filter-sheet,
> zodat ik op het zoekscherm maar één knop zie voor filteren en sorteren.

**Context:**
De sortering (US-133) is nu een apart menu (`_SearchSortMenu`) rechts van de chips. Deze story bouwt de sorteersectie als gedeelde widget, omdat US-163 en US-164 exact dezelfde sectie bovenaan hun sheet krijgen.

**Acceptance criteria:**
- Het losse sorteermenu op het zoekscherm is weg. De sheet uit US-161 begint met een sectie "Sorteren": Relevantie (standaard), Nieuwste eerst, Oudste eerst (één keuze).
- De sectie is één herbruikbare widget (labels, volgorde, vertalingen op één plek), met ruimte voor extra opties per scherm (nodig voor US-163).
- Toepassen met een andere sortering voert de zoekopdracht opnieuw uit vanaf pagina 1; doorscrollen houdt de sortering aan.
- Een niet-standaard sortering telt als 1 mee in de badge; "Alles wissen" zet hem terug op Relevantie.
- De label-link (US-134) zet nog steeds "Nieuwste eerst".
- Het zoekscherm heeft daarna precies één knop voor filteren en sorteren (naast de knoppen voor opgeslagen zoekopdrachten).
- Tests: sortering kiezen → zoekopdracht met die sortering; badge telt mee; bestaande sorteertests herschreven; live Discogs-test aangepast.

---

### US-163: Collectie: sorteericoon weg, sortering bovenaan in "Filter collection"

**Priority: High · 3 SP**

> Als verzamelaar,
> wil ik op de collectiepagina sorteren via het filter, met dezelfde drie opties als bij Zoeken,
> zodat er één icoon minder staat en sorteren overal hetzelfde werkt.

**Context:**
Naast de zoekbalk staan drie iconen: filter, sorteren (`collection-sort-button`, [collection_screen.dart:283](lib/presentation/screens/collection_screen.dart#L283)) en opgeslagen filters. Het middelste verdwijnt. [`CollectionSort`](lib/domain/models/collection_sort.dart) heeft nu `newestFirst` (= volgorde van toevoegen), `bpm`, `musicalKey`, `energyLevel`.

**Acceptance criteria:**
- Het sorteericoon is weg; naast de zoekbalk staan nog twee iconen (filter, opgeslagen filters).
- "Filter collection" begint met de gedeelde sectie "Sorteren": Relevantie (standaard), Nieuwste eerst, Oudste eerst.
  - Relevantie = huidige standaardvolgorde (laatst toegevoegd eerst).
  - Nieuwste / Oudste eerst = op releasejaar; items zonder jaar achteraan, in beide richtingen.
- BPM, Key en Energy staan als extra opties onder de drie, alleen zichtbaar als er items met DJ-gegevens zijn; gedrag ongewijzigd (lege waarden achteraan).
- Sortering wordt met Toepassen doorgevoerd, combineert met alle filters en het zoekveld, telt als 1 mee in de badge als hij niet Relevantie is, en "Alles wissen" zet hem terug.
- De regel met actieve filters boven de lijst toont ook de actieve sortering, of de badge maakt dat voldoende duidelijk (kiezen bij het bouwen, gelijk aan Zoeken).
- Labels vertaald in alle vijf talen (de huidige sorteerlabels zijn hardcoded Engels).
- Tests: unit-tests voor sorteren op jaar (oplopend, aflopend, zonder jaar achteraan) en voor Relevantie = ongewijzigde volgorde; widget-tests: geen sorteericoon meer, sortering kiezen in de sheet herordent de lijst, DJ-opties alleen bij DJ-gegevens; bestaande tests op `collection-sort-button` herschreven.

**Buiten scope:** sortering opslaan in opgeslagen filtersets (US-117) of tussen sessies.

---

### US-164: Verlanglijst: sortering bovenaan in het filter

**Priority: Medium · 2 SP**

> Als verzamelaar,
> wil ik mijn verlanglijst kunnen sorteren met dezelfde drie opties als bij Zoeken en Collectie,
> zodat de drie schermen hetzelfde werken.

**Context:**
De verlanglijst heeft een filterknop (`wishlist-filter-button`) en opgeslagen filters, maar geen sortering. De volgorde is nu vast: laatst toegevoegd eerst.

**Acceptance criteria:**
- Het verlanglijstfilter begint met de gedeelde sectie "Sorteren": Relevantie (standaard, = huidige volgorde), Nieuwste eerst, Oudste eerst (op releasejaar; zonder jaar achteraan).
- Zelfde gedrag als US-163: Toepassen, combineert met filters en zoekveld, telt mee in de badge, "Alles wissen" zet terug op Relevantie.
- De sorteerlogica op jaar is dezelfde code als in US-163 (geen tweede implementatie).
- Vertaald in alle vijf talen.
- Tests: unit-test dat de gedeelde sortering op `WishlistItem` werkt; widget-test dat een gekozen sortering de lijst herordent en de badge bijwerkt.
