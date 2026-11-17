# Phase 19: Eén filterknop op het zoekscherm (november 2026)

Aangemaakt: 2026-11-17

Doel: gebruikersfeedback verwerken. Het zoekscherm toont nu een rij chips (Release, Artiest, Label, Alleen vinyl) plus een sorteermenu (Relevantie, Nieuwste eerst, Oudste eerst). Dat wordt één filterknop die een bottom sheet opent, zoals op het collectiescherm. Nummering loopt door vanaf US-160.

Volgorde: US-161 → US-162 (US-162 bouwt voort op de sheet uit US-161).

| Story | Titel | Prio | SP | Hangt af van |
|---|---|---|---|---|
| US-161 | Zoekfilters in een bottom sheet achter één filterknop | High | 3 | — |
| US-162 | Sortering in dezelfde bottom sheet | High | 2 | US-161 |

---

### US-161: Zoekfilters in een bottom sheet achter één filterknop

**Priority: High · 3 SP**

> Als gebruiker,
> wil ik op het zoekscherm één filterknop in plaats van een rij chips,
> zodat het scherm rustiger is en filteren hetzelfde werkt als op het collectiescherm.

**Context:**
De chips Release / Artiest / Label (US-84/85) en "Alleen vinyl" (US-142) staan nu onder de zoekbalk in [search_screen.dart](lib/presentation/screens/search_screen.dart) (`_SearchFilterChips`). Het collectiescherm heeft al het gewenste patroon: een `IconButton` met `Icons.filter_list_outlined` en een `Badge` met het aantal actieve filters ([collection_screen.dart:274](lib/presentation/screens/collection_screen.dart#L274)), die een bottom sheet opent.

**Acceptance criteria:**
- De chiprij onder de zoekbalk is weg. Naast de zoekbalk staat één filterknop met hetzelfde icoon als op het collectiescherm.
- De knop opent een bottom sheet met:
  - "Zoeken in": Release, Artiest, Label (één keuze; niets gekozen = alles, zoals nu);
  - de schakelaar "Alleen vinyl".
- Een wijziging in de sheet voert de huidige zoekopdracht opnieuw uit vanaf pagina 1 (bestaand gedrag van de chips). De sheet volgt het patroon van het collectiefilter (Toepassen-knop en "Alles wissen"), tenzij direct toepassen bij het uitwerken eenvoudiger blijkt; kies één en leg het vast in de story.
- De knop toont een badge met het aantal actieve filters (gekozen zoekveld = 1, Alleen vinyl = 1); zonder actieve filters geen badge.
- Bestaand gedrag blijft: "Alleen vinyl" wordt onthouden tussen sessies; het zoekveld leegmaken zet "Zoeken in" terug naar alles; de label-link vanuit een release (US-134) zet het Label-filter; opnieuw tikken op de Zoeken-tab (US-139) behoudt de filters; opgeslagen zoekopdrachten herstellen hun filter.
- Werkt in het smalle zoekpaneel op iPad (320 dp) en op de telefoon.
- Teksten vertaald in alle vijf talen; knop heeft een tooltip/semantisch label.
- Tests: widget-tests voor openen van de sheet, kiezen van elk filter → nieuwe zoekopdracht met dat filter, badge-telling, en de bestaande chip-tests herschreven naar de sheet. De live Discogs-test (`integration_test/discogs_live_test.dart`) is aangepast aan de nieuwe bediening.

---

### US-162: Sortering in dezelfde bottom sheet

**Priority: High · 2 SP**

> Als gebruiker,
> wil ik de sortering (Relevantie, Nieuwste eerst, Oudste eerst) in dezelfde filter-sheet,
> zodat ik op het zoekscherm maar één knop zie voor filteren en sorteren.

**Context:**
De sortering (US-133) is nu een apart menu (`_SearchSortMenu`) rechts van de chips. Na US-161 is dat het enige overgebleven bedieningselement naast de filterknop.

**Acceptance criteria:**
- Het losse sorteermenu op het zoekscherm is weg; de sheet uit US-161 heeft een sectie "Sorteren" met Relevantie (standaard), Nieuwste eerst en Oudste eerst (één keuze).
- Een andere sortering voert de zoekopdracht opnieuw uit vanaf pagina 1; doorscrollen houdt de sortering aan (bestaand gedrag).
- Een niet-standaard sortering telt mee in de badge op de filterknop, zodat zichtbaar is dat de resultaten niet op relevantie staan.
- "Alles wissen" zet de sortering terug op Relevantie.
- De label-link (US-134) zet nog steeds "Nieuwste eerst".
- Het zoekscherm heeft daarna precies één knop voor filteren en sorteren.
- Tests: sortering kiezen in de sheet → nieuwe zoekopdracht met die sortering; badge telt de sortering mee; bestaande sorteertests herschreven; live Discogs-test aangepast.
