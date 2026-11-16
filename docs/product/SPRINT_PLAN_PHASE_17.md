# Sprintplanning fase 17

Opgesteld: 2026-11-16 · Stories: [phase-17-search-and-scan-removal-stories.md](../user-stories/phase-17-search-and-scan-removal-stories.md)

De fase is in twee sprints geknipt langs de releasegrens. Sprint 1 bevat alles wat het scherm en het zoeken verandert en levert 1.1.0. Sprint 2 bevat de automatische sync en levert 1.2.0. De sync staat apart omdat de app daarmee voor het eerst zelfstandig naar iemands Discogs-account schrijft; dat verdient een eigen testronde met een echt account en mag de rest niet ophouden.

De data zijn een voorstel. Schuif ze gerust; de volgorde en de inhoud per sprint zijn wat telt.

## Capaciteit

| Wie | Rol | Beschikbaar | Opmerking |
|---|---|---|---|
| Fred | Product owner, toesteltests, store-indiening | deeltijd | Alleen Fred kan US-146 doen en builds op echte toestellen controleren |
| Claude Code | Implementatie, tests, documentatie | op afroep | Werkt per story volgens `docs/workflow/STORY_CHECKLIST.md` |

Referentie: fase 16 (US-124 t/m US-132, 9 stories, 31 SP) is op één dag afgerond. Storypoints zijn dus niet de beperkende factor. De doorlooptijd wordt bepaald door drie dingen die niet te versnellen zijn: controleren op echte toestellen (Android, iPhone, iPad), de store-review, en voor sprint 2 het testen tegen een echt Discogs-account. De sprints zijn daarop gepland, met ruimte ertussen.

## Sprint 1: Zoeken, menu en scanner eruit (v1.1.0)

**Data:** ma 16 november – vr 20 november 2026
**Sprintdoel:** een gebruiker vindt de vinylreleases van een label in de volgorde die hij wil, en het hoofdmenu bevat Statistieken in plaats van de scanner.

### Sprint backlog

| # | Prio | Story | SP | Hangt af van |
|---|---|---|---|---|
| 1 | P0 | US-141 Geen "Set condition"-venster meer | 1 | — |
| 2 | P0 | US-135 Scannen uit het hoofdmenu | 2 | — |
| 3 | P0 | US-140 Statistieken in het hoofdmenu | 3 | US-135 |
| 4 | P0 | US-133 Sorteren op releasedatum | 3 | — |
| 5 | P0 | US-142 Zoeken beperken tot vinyl | 3 | na US-133 |
| 6 | P0 | US-134 Vanuit een release naar het label | 3 | US-133 |
| 7 | P1 | US-139 Opnieuw op "Zoeken" tikken wist de zoekbalk | 2 | — |
| 8 | P1 | US-143 Collectie filteren op formaattype | 2 | — |
| 9 | P1 | US-136 Scanner-code en dependency verwijderen | 2 | US-135 |
| 10 | P1 | US-137 Android: camerapermissie verwijderen | 1 | US-136 |
| 11 | P1 | US-138 iOS: cameratoestemming verwijderen | 1 | US-136 |
| 12 | P1 | US-145 Documentatie en store-teksten zonder scanner | 1 | US-136 |
| 13 | P2 | US-147 Verlanglijst filteren op formaattype | 1 | US-143 |
| — | [Fred] | US-146 Store-vermeldingen bijwerken in de consoles | — | US-145 + release-build |

**Sprintlast:** 25 SP in 13 stories, plus één [Fred]-story.

De volgorde begint met US-141 omdat het de kleinste story is met het meest gevoelde effect, en doet daarna US-135 en US-140 direct achter elkaar zodat er geen tussenstand met vier tabs blijft hangen. De drie zoekstories (133, 142, 134) raken dezelfde code en gaan in die volgorde.

**Als er iets af moet:** US-147 eerst (niet gevraagd), daarna US-139. De P0-stories en de volledige scannerverwijdering (135, 136, 137, 138, 145) horen bij elkaar in dezelfde release: een app zonder Scan-tab die nog wel cameratoegang declareert is slechter dan beide uitstellen.

### Belangrijke momenten

| Datum | Wat |
|---|---|
| ma 16 nov | Start; US-133 en US-142 beginnen met het verifiëren van de Discogs-parameters |
| wo 18 nov | Tussenstand: P0 klaar, begin aan scannerverwijdering |
| do 19 nov | Release-builds Android en iOS; Fred controleert op toestellen |
| vr 20 nov | Versie naar 1.1.0, CHANGELOG, indienen; Fred doet US-146 |

## Sprint 2: Automatisch synchroniseren (v1.2.0)

**Data:** ma 23 november – vr 27 november 2026
**Sprintdoel:** met de instelling aan staat een plaat die je in de app toevoegt binnen enkele seconden op Discogs, en een plaat die je op Discogs toevoegt na het openen van de app in de app.

### Sprint backlog

| # | Prio | Story | SP | Hangt af van |
|---|---|---|---|---|
| 1 | P0 | US-144 Instelling auto-sync + direct versturen | 3 | US-141 (sprint 1) |
| 2 | P1 | US-148 Niet-verstuurde items opnieuw proberen | 2 | US-144 |
| 3 | P1 | US-149 Automatisch importeren van Discogs | 5 | US-144 |

**Sprintlast:** 10 SP in 3 stories.

**Als er iets af moet:** US-149. US-144 en US-148 samen zijn een complete uitgaande sync en kunnen zonder de import als 1.2.0 uit; de import volgt dan als 1.2.1.

### Belangrijke momenten

| Datum | Wat |
|---|---|
| ma 23 nov | Start met US-144 |
| wo 25 nov | US-144 en US-148 klaar; Fred test uitgaand met eigen Discogs-account |
| do 26 nov | US-149 klaar; Fred test import met de eigen (grote) collectie |
| vr 27 nov | Versie naar 1.2.0, CHANGELOG, indienen |

## Risico's

| Risico | Gevolg | Maatregel |
|---|---|---|
| Discogs accepteert `sort=year` of `format=Vinyl` niet op de zoek-endpoint | US-133, US-142 en daarmee US-134 kunnen niet zoals beschreven | Als eerste stap van sprint 1 verifiëren met één echte request. Werkt het niet: story stoppen en overleggen, niet in de app sorteren of filteren |
| Store-review keurt 1.1.0 af omdat tekst of screenshots de scanner nog tonen | Release vertraagd | US-145 en US-146 zitten in dezelfde sprint als de code; niet indienen voordat US-146 af is |
| Auto-sync maakt dubbele exemplaren in iemands Discogs-collectie | Vervuilde collectie bij de gebruiker, alleen handmatig te herstellen | Duplicaatregel is acceptatiecriterium in US-144 en US-148; instelling staat standaard uit; Fred test eerst met het eigen account |
| Automatische import loopt tegen de rate limit bij grote collecties | Trage of afgebroken sync, andere Discogs-calls in de app haperen | Acceptatiecriterium in US-149 voor meer dan 1000 items en hervatten; testen met Freds eigen collectie |
| Tabvolgorde verandert twee keer (scan weg, statistieken erbij) | Tests en screenshots die op tabpositie leunen breken | US-135 en US-140 direct na elkaar; `test/widget_test.dart` en de integratietest in beide stories genoemd |
| US-91 ([Fred], Pages Source) staat nog open uit fase 14 | Website toont mogelijk het bijgewerkte privacybeleid niet | Vóór het indienen van 1.1.0 controleren of de site bouwt; anders US-91 eerst |

## Definition of Done

Per story, volgens `docs/workflow/STORY_CHECKLIST.md`:

- [ ] Alle acceptatiecriteria aantoonbaar gedekt door code en test
- [ ] `flutter analyze` zonder issues, `flutter test` groen
- [ ] `graphify update .` gedraaid
- [ ] Commit `Resolved: US-xxx: …`, versie en CHANGELOG bijgewerkt, buildnummer opgehoogd
- [ ] Story op `✅ Resolved (datum)` gezet

Per sprint daarbovenop:

- [ ] Release-build gecontroleerd op een Android-toestel, een iPhone en een iPad
- [ ] Store-teksten en privacyverklaring kloppen met de build
- [ ] Sprint 2: uitgaande en inkomende sync getest tegen een echt Discogs-account

## Niet in deze fase

- Wijzigingen en conflicten synchroniseren, remote verwijderingen overnemen (US-119).
- Exact zoeken op label-id in plaats van labelnaam (vervolg op US-134, alleen als de tekstmatch in de praktijk stoort).
- Een conditiewaarde "niet opgegeven" (zie besluit bij US-141).
- Vrije formaatkeuze in het zoeken, sortering of vinylfilter in opgeslagen zoekopdrachten.
