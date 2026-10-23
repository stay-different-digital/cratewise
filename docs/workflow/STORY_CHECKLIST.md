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

## 5. Statische analyse

- [ ] `flutter analyze` — nul warnings/errors

## 6. Tests

- [ ] Schrijf unit-tests voor nieuwe domeinlogica
- [ ] Schrijf widget-tests voor nieuwe UI
- [ ] `flutter test` — alle tests groen

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

- [ ] Zet story als ✅ in `memory/project_phase14_status.md`
- [ ] Update open-stories-lijst in datzelfde bestand
