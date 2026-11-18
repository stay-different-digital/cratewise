# Story Checklist

Volg deze checklist bij **elke** user story, van selectie tot afsluiting.
Sla geen stap over; de volgorde is bewust.

---

## 1. Selectie

- [ ] Kies een story uit de open backlog (`docs/user-stories/`)
- [ ] Controleer of er **[Fred]-afhankelijkheden** zijn die eerst moeten; zo ja, stop en meld dit
- [ ] Lees de volledige story inclusief **alle acceptance criteria**

## 2. In Progress markeren

- [ ] Voeg `**Status: In Progress**` toe aan de story in het stories-bestand
- [ ] Commit: `chore: mark US-xxx in progress`

## 3. Oriëntatie

- [ ] Draai `graphify query "<vraag>"` of `graphify explain "<concept>"` om relevante code te lokaliseren
- [ ] Lees alleen de specifieke bestanden die graphify aanwijst

## 4. Implementatie

- [ ] Werk laag-voor-laag: domain → infrastructure → presentation
- [ ] Voeg `getAll()` / nieuwe interface-methoden toe aan **alle** fake-implementaties in `test/`
- [ ] Geen abstracties, scaffolding of features die de AC niet vereisen (ponytail)
- [ ] `schemaVersion` opgehoogd? Dump het nieuwe schema en genereer de testhelpers (commando's bovenaan `test/infrastructure/local_database/migration_test.dart`); bestaande `drift_schemas/*.json` nooit aanpassen

## 5. Tests schrijven

- [ ] Schrijf unit-tests voor nieuwe domeinlogica
- [ ] Schrijf widget-tests voor nieuwe UI

## 6. Lokale CI

- [ ] `tool/ci_local.sh` — format, analyze (nul issues), alle tests, Android release-build met KGP-check, iOS-build. Alles groen. (`--skip-ios` alleen als de story iOS niet raakt.)
- [ ] GitHub Actions draait niet bij een push; dit is de controle.

## 7. Acceptance criteria toetsen

- [ ] Loop elk AC-punt langs en bevestig expliciet dat het gedekt is (door code én test)
- [ ] Als een punt niet gedekt is: terug naar stap 4

## 8. Graph bijwerken

- [ ] `graphify update .`

## 9. Code commit

- [ ] `git commit`: `Resolved: US-xxx: <korte omschrijving>`

## 10. Versie bumpen

- [ ] `pubspec.yaml`: ServiceRelease +1 (of Minor bij significante featurebatch) per ADR-0003
- [ ] `CHANGELOG.md`: nieuwe sectie `## [X.Y.Z] — YYYY-MM-DD` boven de vorige release
- [ ] `git commit`: `Bump version to X.Y.Z — <korte omschrijving>`

## 11. Story afsluiten

- [ ] Vervang `In Progress` door `✅ Resolved (YYYY-MM-DD)` in het stories-bestand
- [ ] `git commit`: `chore: close US-xxx`

## 12. Memory bijwerken

- [ ] Werk het memory-bestand van de huidige fase bij (`project_phaseNN_status.md`): story ✅ en de lijst met open stories
