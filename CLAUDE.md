## Story workflow

Bij elke user story: lees `docs/workflow/STORY_CHECKLIST.md` en volg alle stappen in volgorde.
Sla geen stap over, ook niet als de story klein lijkt.

## Testen met een echt Discogs-account

Het echte test-token van Fred staat in `.env` in de projectroot (`DISCOGS_TEST_TOKEN`, gitignored, rechten 600). Gebruik bij elke test die Discogs of een gekoppeld account nodig heeft dít token:

- Live end-to-end: `flutter test integration_test/discogs_live_test.dart -d <device> --dart-define-from-file=.env`. Zonder `.env` slaat die test zichzelf over.
- Losse API-check: lees het token uit `.env`; zet het nooit in een commando-argument dat gelogd wordt, nooit in een commit, nooit in code, docs of memory, en filter het uit getoonde output.
- Het token hoort bij Freds echte account. Tests die naar Discogs **schrijven** (toevoegen, verwijderen, auto-sync aanzetten) alleen na expliciete toestemming van Fred.
- Nooit gebruiken in release-builds (`--dart-define-from-file=.env` alleen bij tests).

---

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
