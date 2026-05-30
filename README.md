# Crate Project Guide

## Doel van dit bestand

Dit bestand legt uit hoe je de projectbestanden gebruikt tijdens het vibe coding proces.

Gebruik dit als startpunt wanneer je met een AI coding agent aan Crate werkt.

Crate is een Flutter app voor iPhone, iPad, Android phones en Android tablets.

De app is een alternatief voor de mobiele Discogs ervaring.

De eerste focus is collection management.

## Belangrijkste regel

Gebruik altijd:

```text
AGENT.md
```

als hoofdbestand voor je coding agent.

Dit bestand vertelt de agent:

- Wat Crate is
- Welke documenten gelezen moeten worden
- Welke technische keuzes leidend zijn
- Hoe de agent moet werken
- Hoe pull requests, tests en changelog gebruikt moeten worden

## Aanbevolen leesvolgorde voor de agent

Laat de agent deze volgorde gebruiken:

```text
1. AGENT.md
2. docs/project/decisions/
3. docs/project/architecture/
4. docs/project/prompts/crate_project_prompt.md
5. docs/project/roadmap/roadmap.md
6. docs/project/backlog/feature_backlog.md
7. docs/project/changelog/changelog.md
```

Gebruik deze volgorde vooral bij:

- Nieuwe features
- Refactors
- API werk
- OAuth werk
- UI werk
- Pull requests
- Releases

## Waarvoor gebruik je welk bestand?

## AGENT.md

Gebruik dit altijd als startpunt.

Dit is het centrale instructiebestand voor je coding agent.

Gebruik dit bij elke vibe coding taak.

Voorbeeldprompt:

```text
Read AGENT.md first. Then implement the task in a small branch and prepare a pull request summary.
```

## docs/project/prompts/crate_project_prompt.md

Gebruik dit als productbriefing.

Dit bestand bevat:

- Productvisie
- MVP scope
- Discogs API regels
- UX richting
- Design richting
- Technische richting
- Output afspraken

Gebruik dit bij:

- Nieuwe features
- Productkeuzes
- UX keuzes
- Nieuwe chat met een AI-agent
- Scope discussies

Voorbeeldprompt:

```text
Read AGENT.md and docs/project/prompts/crate_project_prompt.md. Build the collection overview screen based on the MVP scope.
```

## docs/project/prompts/flutter_folder_setup_prompt.md

Gebruik dit vooral voor projectstructuur.

Dit bestand bevat:

- Flutter folderstructuur
- Feature-based architecture
- Starter files
- Test folderstructuur
- Package richting

Gebruik dit bij:

- Eerste Flutter setup
- Controleren van de folderstructuur
- Nieuwe feature folders
- Refactor van de projectstructuur

Gebruik dit niet bij elke kleine taak.

Voorbeeldprompt:

```text
Read AGENT.md and docs/project/prompts/flutter_folder_setup_prompt.md. Check if the current folder structure matches the project standard.
```

## docs/project/decisions/

Gebruik deze map voor ADR’s.

ADR betekent Architecture Decision Record.

Deze bestanden leggen vast welke keuzes al gemaakt zijn.

Voorbeelden:

- Waarom we Cloudflare Worker gebruiken
- Waarom we Discogs API v2.0 gebruiken
- Waarom we Riverpod gebruiken
- Waarom we go_router gebruiken
- Waarom offline cache buiten MVP valt

Gebruik ADR’s altijd bij technische keuzes.

Voorbeeldprompt:

```text
Read AGENT.md and the relevant ADRs in docs/project/decisions before changing the API architecture.
```

## docs/project/architecture/

Gebruik deze map voor technische uitleg.

Belangrijke bestanden:

```text
docs/project/architecture/oauth_architecture.md
docs/project/architecture/api_architecture.md
```

Gebruik deze bij:

- Discogs OAuth
- Cloudflare Worker
- API client
- Error handling
- Rate limits
- Token storage

Voorbeeldprompt:

```text
Read AGENT.md, docs/project/architecture/oauth_architecture.md, and docs/project/decisions/0001-use-cloudflare-worker-for-discogs-oauth.md. Implement the OAuth start flow.
```

## docs/project/roadmap/roadmap.md

Gebruik dit voor de bouwvolgorde.

De roadmap geeft fases aan.

Gebruik dit bij:

- Planning
- Prioriteit bepalen
- Nieuwe taken kiezen
- Release voorbereiding

Voorbeeldprompt:

```text
Read the roadmap and suggest the next 3 small pull requests for Phase 1.
```

## docs/project/backlog/feature_backlog.md

Gebruik dit voor epics en user stories.

Dit bestand bevat:

- Epics
- Stories
- Acceptatiecriteria
- Prioriteit

Gebruik dit bij:

- Feature selectie
- PR scope
- Taken maken
- Issue schrijven

Voorbeeldprompt:

```text
Read the backlog and create a small implementation plan for Story 3.1: View collection.
```

## docs/project/changelog/changelog.md

Gebruik dit na betekenisvolle wijzigingen.

Update de changelog bij:

- Nieuwe feature
- Bug fix
- Refactor
- API wijziging
- Architectuurwijziging
- Test setup wijziging
- Documentatie update

Gebruik deze secties:

- Added
- Changed
- Fixed
- Removed
- Technical

Voorbeeldprompt:

```text
Update docs/project/changelog/changelog.md for this change under Unreleased.
```

## docs/project/prompts/agent/

Deze map bevat herbruikbare prompts voor de agent.

Gebruik de prompt die past bij je taak.

Belangrijke prompts:

```text
feature_implementation_prompt.md
bug_fix_prompt.md
screen_ui_prompt.md
api_integration_prompt.md
test_generation_prompt.md
refactor_prompt.md
code_review_prompt.md
adr_creation_prompt.md
changelog_update_prompt.md
release_preparation_prompt.md
cloudflare_worker_prompt.md
accessibility_review_prompt.md
pull_request_prompt.md
```

## Wanneer gebruik je welke agent prompt?

### Nieuwe feature

Gebruik:

```text
docs/project/prompts/agent/feature_implementation_prompt.md
```

Voorbeeld:

```text
Use docs/project/prompts/agent/feature_implementation_prompt.md to build the collection list screen.
```

### Bug oplossen

Gebruik:

```text
docs/project/prompts/agent/bug_fix_prompt.md
```

### UI screen bouwen

Gebruik:

```text
docs/project/prompts/agent/screen_ui_prompt.md
```

### Discogs API werk

Gebruik:

```text
docs/project/prompts/agent/api_integration_prompt.md
```

### Tests maken

Gebruik:

```text
docs/project/prompts/agent/test_generation_prompt.md
```

### Refactor

Gebruik:

```text
docs/project/prompts/agent/refactor_prompt.md
```

### Code review

Gebruik:

```text
docs/project/prompts/agent/code_review_prompt.md
```

### Nieuwe ADR maken

Gebruik:

```text
docs/project/prompts/agent/adr_creation_prompt.md
```

### Changelog bijwerken

Gebruik:

```text
docs/project/prompts/agent/changelog_update_prompt.md
```

### Release voorbereiden

Gebruik:

```text
docs/project/prompts/agent/release_preparation_prompt.md
```

### Cloudflare Worker bouwen

Gebruik:

```text
docs/project/prompts/agent/cloudflare_worker_prompt.md
```

### Accessibility check

Gebruik:

```text
docs/project/prompts/agent/accessibility_review_prompt.md
```

### Pull request voorbereiden

Gebruik:

```text
docs/project/prompts/agent/pull_request_prompt.md
```

## Procesbestanden

## docs/project/working-agreement.md

Gebruik dit om de werkwijze te bewaken.

Belangrijkste regels:

- Werk in kleine stappen
- Gebruik branches
- Gebruik pull requests
- Eén feature of fix per PR
- Niet direct op main werken
- Tests draaien
- Changelog bijwerken

## docs/project/definition-of-ready.md

Gebruik dit voordat je een taak start.

Een taak is ready als duidelijk is:

- Wat gebouwd moet worden
- Wat in scope is
- Wat out of scope is
- Welke acceptatiecriteria gelden
- Welke tests nodig zijn
- Welke documenten relevant zijn

## docs/project/definition-of-done.md

Gebruik dit voordat je een PR afrondt.

Een taak is done als:

- Code werkt
- Tests slagen
- UI states aanwezig zijn
- Changelog is bijgewerkt
- Documentatie is bijgewerkt waar nodig
- Geen secrets zijn toegevoegd
- PR-template is ingevuld

## docs/project/branching-strategy.md

Gebruik dit voor branch namen.

Voorbeelden:

```text
feature/collection-list
feature/discogs-oauth-login
fix/oauth-callback-error
docs/update-roadmap
refactor/api-error-mapping
test/collection-parser
```

## docs/project/testing-strategy.md

Gebruik dit voor testkeuzes.

Test vooral:

- OAuth state handling
- Token storage
- Discogs API client
- Error mapping
- Collection parsing
- Search parsing
- Release detail parsing
- Theme switching
- Main widget states

## docs/project/release-checklist.md

Gebruik dit voor beta of release builds.

Controleer onder andere:

- OAuth werkt
- Collection laadt
- Search werkt
- Release detail werkt
- Logout werkt
- Theme mode werkt
- Geen secrets zijn committed
- Changelog is bijgewerkt

## docs/project/environment-setup.md

Gebruik dit voor lokale setup.

Bevat:

- Flutter setup
- Dependencies installeren
- App draaien
- Tests draaien
- Environment variables
- OAuth setup regels

## GitHub bestanden

## .github/PULL_REQUEST_TEMPLATE.md

Gebruik deze voor elke PR.

De template helpt je controleren:

- Is de PR klein genoeg?
- Zijn tests gedaan?
- Is de changelog bijgewerkt?
- Is er een ADR nodig?
- Zijn er geen secrets toegevoegd?
- Gebruikt de code Discogs API v2.0?

## .github/ISSUE_TEMPLATE/

Gebruik deze voor issues.

Beschikbare templates:

```text
feature_request.md
bug_report.md
technical_task.md
```

## .github/workflows/flutter-ci.yml

Deze workflow draait automatisch op GitHub.

Checks:

- Dart format
- Flutter analyze
- Flutter test
- Android debug build

## .env.example

Gebruik dit als voorbeeld voor lokale environment variables.

Belangrijk:

- Kopieer naar `.env`
- Zet geen echte secrets in Git
- Discogs consumer secret hoort in Cloudflare Worker secrets
- Niet in Flutter

Voorbeeld:

```bash
cp .env.example .env
```

## CONTRIBUTING.md

Gebruik dit als algemene bijdragehandleiding.

Dit is handig als je later met anderen werkt of een agent duidelijke repo-regels wilt geven.

## SECURITY.md

Gebruik dit voor security regels.

Belangrijkste regels:

- Geen secrets committen
- Geen Discogs consumer secret in Flutter
- Geen tokens loggen
- Secrets alleen in Cloudflare Worker
- Discogs API v2.0 only
- Niet scrapen

## Aanbevolen vibe coding workflow

Gebruik deze flow voor bijna elke taak:

```text
1. Kies een story uit de backlog
2. Maak een issue
3. Maak een branch
4. Laat de agent AGENT.md lezen
5. Laat de agent relevante ADR’s lezen
6. Laat de agent een klein plan maken
7. Laat de agent code schrijven
8. Laat de agent tests toevoegen
9. Laat de agent de changelog bijwerken
10. Open een pull request
11. Review de wijzigingen
12. Merge naar main
```

## Voorbeeld: nieuwe feature bouwen

Prompt:

```text
Read AGENT.md, docs/project/backlog/feature_backlog.md, and docs/project/prompts/agent/feature_implementation_prompt.md.

Build Story 3.1: View collection.

Keep the PR small. Use Discogs API v2.0 only. Do not scrape Discogs. Add loading, empty, error, and success states. Add tests and update the changelog.
```

## Voorbeeld: API integratie bouwen

Prompt:

```text
Read AGENT.md, docs/project/architecture/api_architecture.md, docs/project/architecture/oauth_architecture.md, and docs/project/prompts/agent/api_integration_prompt.md.

Implement the collection endpoint integration through the Cloudflare Worker. Use Discogs API v2.0 only. Handle rate limits, unauthorized responses, not found responses, and network errors.
```

## Voorbeeld: UI screen maken

Prompt:

```text
Read AGENT.md, docs/project/decisions/0002-use-airbnb-inspired-figma-design-direction.md, and docs/project/prompts/agent/screen_ui_prompt.md.

Create the collection list screen. Use large artwork cards, clean spacing, rounded corners, loading skeletons, empty state, error state, light mode, dark mode, phone layout, and tablet layout.
```

## Voorbeeld: PR laten voorbereiden

Prompt:

```text
Read AGENT.md and docs/project/prompts/agent/pull_request_prompt.md.

Prepare this change as a small pull request. Run formatting, analysis, and tests. Update the changelog. Give me the PR summary.
```

## Harde projectregels

Deze regels gelden altijd:

- Gebruik Discogs API v2.0 only.
- Gebruik nooit Discogs API v1.0.
- Scrape Discogs niet.
- Zet geen secrets in Flutter.
- Commit geen echte secrets.
- Gebruik Cloudflare Worker voor OAuth signing en secret handling.
- Werk niet direct op main.
- Maak kleine PR’s.
- Update de changelog bij betekenisvolle wijzigingen.
- Maak of update een ADR bij grote keuzes.
- Houd offline collection cache buiten MVP.

## Wanneer maak je een nieuwe ADR?

Maak een ADR bij keuzes over:

- Architectuur
- State management
- Navigatie
- API aanpak
- OAuth aanpak
- Storage
- Design direction
- Testing strategy
- Grote packages
- MVP scope

Gebruik:

```text
docs/project/prompts/agent/adr_creation_prompt.md
```

Nieuwe ADR’s komen in:

```text
docs/project/decisions/
```

Bestandsnaam voorbeeld:

```text
0013-use-sentry-for-crash-reporting.md
```

## Snelle start bij vibe coding

Gebruik dit als standaardprompt:

```text
Read AGENT.md first.

Then read the relevant ADRs, architecture docs, roadmap, backlog, and changelog.

Work on this task in a small branch.

Follow the Definition of Done.

Use Discogs API v2.0 only.

Do not use Discogs API v1.0.

Do not scrape Discogs.

Do not commit secrets.

Update tests, documentation, and changelog when needed.

Task:
[describe task]
```


## Extra tips voor vibe coding

Gebruik deze tips om je agent beter te sturen en om je project schoon te houden.

## 1. Werk met kleine coding sessions

Maak per sessie één duidelijk doel.

Voorbeeld:

```text
Session goal:
Build the collection list screen shell only.

Out of scope:
No API integration.
No filters.
No sorting.
No release detail.
```

Waarom dit helpt:

- De agent blijft gefocust.
- Je krijgt kleinere pull requests.
- Je voorkomt half afgemaakte grote features.
- Je kunt sneller reviewen.

## 2. Gebruik een vaste startprompt per sessie

Gebruik bijvoorbeeld altijd dit format:

```text
Read AGENT.md first.

Then read:
- docs/project/roadmap/roadmap.md
- docs/project/backlog/feature_backlog.md
- relevant ADRs
- relevant architecture docs

Work on this task:
[task]

Rules:
- Keep the change small.
- Use Discogs API v2.0 only.
- Do not use Discogs API v1.0.
- Do not scrape Discogs.
- Do not commit secrets.
- Add or update tests.
- Update the changelog if needed.
- Prepare a pull request summary.
```

## 3. Laat de agent eerst een plan maken

Vraag niet direct om code.

Gebruik eerst:

```text
Make a short implementation plan first. Do not write code yet.
```

Daarna kun je sturen op scope.

Voorbeeld:

```text
Make the plan smaller. This PR should only create the UI shell and widget states.
```

## 4. Splits features in mini PR’s

Voorbeeld voor collection management:

```text
PR 1: Add collection route and screen shell
PR 2: Add collection item card
PR 3: Add loading, empty, error states
PR 4: Add collection API model
PR 5: Add collection repository
PR 6: Connect collection screen to real API
PR 7: Add pagination
PR 8: Add search inside collection
PR 9: Add filters
PR 10: Add sorting
```

Vermijd grote opdrachten zoals:

```text
Build collection management
```

Die opdracht is te groot.

## 5. Voeg een Do not touch sectie toe aan taken

Dit voorkomt dat de agent onnodig veel wijzigt.

Voorbeeld:

```text
Do not touch:
- OAuth files
- Cloudflare Worker files
- Release detail feature
- Existing ADRs
```

## 6. Gebruik review mode na elke wijziging

Laat de agent zichzelf controleren.

Prompt:

```text
Review your own changes against:
- AGENT.md
- Definition of Done
- Relevant ADRs
- PR template

List any issues before I commit.
```

## 7. Laat de agent altijd een rollback-notitie geven

Handig als iets fout gaat.

Prompt:

```text
Add a rollback note. Explain how I can undo this change safely.
```

Voorbeeld output:

```text
Rollback:
- Revert this PR.
- No database changes were added.
- No environment changes are required.
```

## 8. Gebruik assumption logging

Vraag de agent om aannames expliciet te noemen.

Prompt:

```text
List all assumptions before coding.
```

Voorbeeld:

```text
Assumptions:
- The Cloudflare Worker base URL is available through environment config.
- The collection endpoint will return paginated results.
- The UI can use fake state objects in widget tests.
```

Dit helpt om foute aannames vroeg te zien.

## 9. Maak eerst screen skeletons

Voor screens werkt deze volgorde goed:

```text
Step 1: Screen shell
Step 2: Reusable widgets
Step 3: Loading, empty, error states
Step 4: State controller
Step 5: Repository integration
Step 6: Real API
```

Je gebruikt echte Discogs API calls vanaf het begin.

Voor UI previews mag je tijdelijke testdata gebruiken, zolang dit duidelijk mock of test data is.

## 10. Gebruik labels voor issues

Aanbevolen GitHub labels:

```text
feature
bug
technical
documentation
adr
ui
api
auth
collection
search
barcode
wantlist
settings
good-first-agent-task
needs-review
blocked
```

Handig label:

```text
good-first-agent-task
```

Gebruik dit voor kleine, veilige taken.

## 11. Maak een agent safe task template

Een goede agent-taak bevat altijd:

```markdown
## Goal

## Scope

## Out of scope

## Relevant docs

## Acceptance criteria

## Test expectations

## Changelog needed

## Do not touch
```

Voorbeeld:

```markdown
## Goal

Create the collection list screen shell.

## Scope

- Add route
- Add screen
- Add loading state
- Add empty state
- Add error state
- Add success state with static preview items

## Out of scope

- Real API integration
- Pagination
- Search
- Filters
- Sorting

## Relevant docs

- AGENT.md
- ADR 0002
- feature_backlog.md

## Acceptance criteria

- Screen is reachable through go_router
- Screen supports light and dark mode
- Screen has all UI states
- Widget test covers loading and error state

## Test expectations

- Add widget tests

## Changelog needed

Yes

## Do not touch

- OAuth
- Cloudflare Worker
- API client
```

## 12. Werk met vertical slices

Een vertical slice bouwt een klein stuk functionaliteit van UI tot data.

Voorbeeld:

```text
Collection list MVP slice:
- Route
- Screen
- Controller
- Repository
- API model
- Error mapping
- Loading state
- Test
```

Houd de slice klein.

Voeg niet direct filters, sorting en detail toe.

## 13. Voeg visuele testmomenten toe

Vraag de agent bij UI werk om handmatige checkpunten.

Prompt:

```text
Add a manual visual checklist for:
- iPhone
- iPad
- Android phone
- Android tablet
- Light mode
- Dark mode
```

## 14. Maak vaste stopregels

Zet dit in je prompt bij complexe taken:

```text
Stop and report before continuing if:
- A new package is needed
- An ADR decision conflicts with the task
- Secrets are needed
- The task becomes larger than expected
- More than 15 files need changes
```

Dit voorkomt dat de agent doorschiet.

## 15. Gebruik een vaste commitstijl

Goede commit messages:

```text
Add collection list screen shell
Add Discogs API error mapper
Fix OAuth callback state handling
Update Crate roadmap
Add tests for token storage
```

Vermijd:

```text
fix stuff
update files
final changes
wip
```

## 16. Beste volgorde voor de eerste vibe coding PR’s

Aanbevolen volgorde:

```text
1. Add Flutter project structure
2. Add theme tokens
3. Add go_router setup
4. Add shared UI states
5. Add app release card
6. Add environment config
7. Add secure storage abstraction
8. Add base API client
9. Add API error mapping
10. Add OAuth flow shell
11. Add Cloudflare Worker OAuth start endpoint
12. Add collection screen shell
```

## 17. Gebruik de kleinste nuttige stap

Gebruik je agent niet als:

```text
Build the whole app.
```

Gebruik je agent als:

```text
Make the smallest useful change for this task.
```

Dat houdt het project schoon, controleerbaar en schaalbaar.

## Snelle vibe coding prompt

Gebruik deze prompt als standaard startpunt:

```text
Read AGENT.md first.

Then read the relevant ADRs, architecture docs, roadmap, backlog, and changelog.

Work on this task in a small branch.

Follow the Definition of Done.

Use Discogs API v2.0 only.

Do not use Discogs API v1.0.

Do not scrape Discogs.

Do not commit secrets.

Update tests, documentation, and changelog when needed.

Before coding, list your assumptions and make a short implementation plan.

Stop and report before continuing if:
- A new package is needed
- An ADR decision conflicts with the task
- Secrets are needed
- The task becomes larger than expected
- More than 15 files need changes

Task:
[describe task]
```

## Mijn praktische advies

Gebruik `AGENT.md` dagelijks.

Gebruik `crate_project_prompt.md` voor productcontext.

Gebruik `flutter_folder_setup_prompt.md` alleen voor setup en structuur.

Gebruik ADR’s als harde beslissingen.

Gebruik roadmap en backlog om te bepalen wat je bouwt.

Gebruik changelog om bij te houden wat veranderd is.

Gebruik pull requests om vibe coding veilig en controleerbaar te houden.
