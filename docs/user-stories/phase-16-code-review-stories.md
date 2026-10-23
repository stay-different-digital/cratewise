# Phase 16: Code review (oktober 2026)

Aangemaakt: 2026-10-23

Doel: bevindingen uit de code review van Cratewise v1.0.3 omzetten naar werk. Nummering loopt door vanaf US-123.

Uitgangssituatie: `flutter analyze` geeft 0 issues, testdekking op application/infrastructure is vrijwel volledig. De bevindingen gaan daarom vooral over gedrag in randgevallen, onderhoudbaarheid en robuustheid, niet over kapotte basisfunctionaliteit.

Volgorde: High → Medium → Low. Stories zijn onafhankelijk, behalve US-126 (beter vóór US-130 doen, omdat beide de constructors van de preview-schermen raken).

---

### US-124: Pending deletions die op Discogs al weg zijn blijven niet eeuwig hangen

**Status: ✅ Resolved (2026-10-23)**

**Priority: High · 3 SP**

> Als verzamelaar,
> wil ik dat een verwijdering die op Discogs al is uitgevoerd (of niet uitgevoerd kan worden) uit de lijst "pending deletions" verdwijnt,
> zodat die lijst niet steeds groeit met items die bij elke sync opnieuw mislukken.

**Context:**
[execute_pending_deletions_use_case.dart:92-137](lib/application/use_cases/execute_pending_deletions_use_case.dart#L92-L137) beschouwt alleen HTTP 204 als succes. Daardoor blijven twee gevallen voor altijd hangen:
1. **404:** het item is op Discogs al verwijderd (bijvoorbeeld via de website). [`_checkStatus`](lib/infrastructure/discogs/discogs_api_client.dart#L310) gooit dan `UnexpectedApiError(404)`, de tombstone blijft staan en bij elke run komt er opnieuw een 404.
2. **`discogsInstanceId == null`:** de code gooit bewust `UnexpectedApiError(0)` (r. 119). Zo'n tombstone kan nooit slagen, maar blijft wel elke run terugkomen.

**Acceptance criteria:**
- Een DELETE die 404 teruggeeft geldt als geslaagd: de tombstone wordt verwijderd en telt mee in `removed`.
- Een collection-tombstone zonder `discogsInstanceId` wordt niet meer naar de API gestuurd. Kies één van deze twee opties en leg de keuze vast in de story:
  - (a) instance id opzoeken via `GET /users/{u}/collection/releases/{releaseId}`;
  - (b) tombstone verwijderen en apart tellen (bijvoorbeeld `unresolvable`), zodat de gebruiker dit in het resultaat ziet.
- **Gekozen: (a)** — instance id opzoeken; 0 exemplaren → tombstone weg (niets te verwijderen), 1 → dat exemplaar verwijderen, >1 → tombstone blijft (niet te bepalen welk exemplaar bedoeld is).
- Bij 401/403 blijft het huidige gedrag (`clearIfRevoked`) ongewijzigd.
- Unit-tests dekken: 404 → removed, null instance id → gekozen gedrag, 500 → tombstone blijft staan.

---

### US-125: Migratietests voor het Drift-schema (v1 → v12)

**Status: ✅ Resolved (2026-10-23)**

**Priority: High · 5 SP**

> Als ontwikkelaar,
> wil ik dat elke schema-migratie automatisch getest wordt,
> zodat een update van de app nooit de lokale collectie van een gebruiker beschadigt of weggooit.

**Context:**
[app_database.dart:386-433](lib/infrastructure/local_database/app_database.dart#L386-L433) heeft 11 migratiestappen (`schemaVersion => 12`). Er zijn geen schema-dumps (`drift_schemas/`) en geen tests die `SchemaVerifier` gebruiken. De lokale database is de enige bron van waarheid voor notities, DJ-velden (v11) en saved searches (v12). Een kapotte migratie betekent dus dataverlies zonder herstelmogelijkheid. Verder heeft [database_transaction_runner.dart](lib/infrastructure/local_database/database_transaction_runner.dart) geen eigen test, terwijl de import-use-cases rekenen op een rollback.

**Technische aanpak:**
`drift_dev` staat al in `dev_dependencies`, dus er is geen nieuwe dependency nodig.
1. `dart run drift_dev make-migrations` (of `schema dump` + `schema generate`) voor v12, en zo ver mogelijk met terugwerkende kracht voor oudere versies via git-history.
2. Schrijf een migratietest per stap met `SchemaVerifier`, plus een test die controleert dat er data bewaard blijft (rij in v10 → velden na upgrade naar v12 nog intact).

**Acceptance criteria:**
- `drift_schemas/` staat in git met minimaal de huidige versie (v12) en zoveel mogelijk eerdere versies.
- Er is een test die van elke beschikbare oude versie naar v12 migreert en het resultaat valideert met `SchemaVerifier`.
- Minimaal één test bewijst dat er geen data verloren gaat: een `collection_items`-rij die vóór v11 is aangemaakt, heeft na de upgrade nog dezelfde waarden en `bpm`/`musicalKey` = null.
- `DatabaseTransactionRunner` heeft een test die bewijst dat een exceptie in `run()` alle writes terugdraait.
- **Gevonden en gefixt:** upgrades vanaf v1–v4 crashten (`duplicate column name: sync_status` / `payload`), omdat `createTable()` de huidige tabelvorm gebruikt en een latere `addColumn` dezelfde kolom nog eens toevoegde. v5+ was niet geraakt. v11 is nooit los gecommit en is gereconstrueerd uit v12 zonder `saved_searches`.
- `STORY_CHECKLIST.md` of `CONTRIBUTING`/ADR beschrijft dat een schemawijziging een nieuwe dump en migratietest vereist.

---

### US-126: Eén gedeelde DiscogsApiClient met app-brede rate-limit back-off

**Status: ✅ Resolved (2026-10-23)**

**Priority: Medium · 5 SP**

> Als gebruiker met een grote collectie,
> wil ik dat de app de Discogs rate limit over alle schermen heen respecteert,
> zodat import, sync en zoeken niet tegelijk tegen 429-fouten aanlopen.

**Context:**
- `DiscogsApiClient` houdt de rate-limit-status bij in een instantievariabele (`_nextAllowedAt`), maar er worden minstens 11 losse instanties aangemaakt. Dat gebeurt via `?? DiscogsApiClient()`-defaults in use cases/services (onder andere [barcode_lookup_use_case.dart:42](lib/application/use_cases/barcode_lookup_use_case.dart#L42), [discogs_search_service.dart:13](lib/application/services/discogs_search_service.dart#L13), [token_validation_service.dart:6](lib/application/services/token_validation_service.dart#L6)) en direct in schermen ([pending_deletions_screen.dart:77](lib/presentation/screens/pending_deletions_screen.dart#L77), [collection_export_preview_screen.dart:96](lib/presentation/screens/collection_export_preview_screen.dart#L96)). De back-off werkt daardoor alleen binnen één instantie.
- De `http.Client`s uit de use-case-defaults worden nooit `close()`d.
- [`_get`/`_write`](lib/infrastructure/discogs/discogs_api_client.dart#L230-L280) roept `_checkStatus` aan vóór `_updateRateLimitState`. Bij een 429 wordt de back-off dus nooit gezet en gaat de volgende request direct de deur uit.
- `_waitIfNeeded` maakt `_nextAllowedAt` leeg vóór de `await`, waardoor gelijktijdige aanroepers de wachttijd overslaan.

**Acceptance criteria:**
- In productie bestaat precies één `DiscogsApiClient`. *Uitgevoerd als `DiscogsApiClient.shared`: alle `?? DiscogsApiClient()`-defaults en schermen gebruiken deze instantie, in plaats van hem via `AppRepositoriesScope` door ~30 constructors door te geven. Schermen sluiten hem niet.*
- Geen enkel bestand in `lib/presentation/` roept `DiscogsApiClient()` of `http.Client()` aan.
- Een 429-response zet `_nextAllowedAt` (respecteer `Retry-After` als die aanwezig is, anders 60 s) voordat `RateLimitedError` wordt gegooid.
- Gelijktijdige requests tijdens een back-off wachten allemaal tot `_nextAllowedAt`.
- Unit-tests dekken: 429 → volgende request wacht; twee gelijktijdige requests tijdens back-off wachten allebei.
- Constructor-injectie voor tests blijft werken.

---

### US-127: CSV-export is beschermd tegen formula injection

**Status: ✅ Resolved (2026-10-23)**

**Priority: Medium · 2 SP**

> Als gebruiker die een export in Excel/Numbers opent,
> wil ik dat celwaarden nooit als formule worden uitgevoerd,
> zodat een Discogs-titel of notitie die met `=` begint geen code of externe links in mijn spreadsheet kan starten.

**Context:**
[csv_file_writer.dart](lib/infrastructure/csv/csv_file_writer.dart) en de mappers schrijven velden ongewijzigd weg. Artiest, titel, label en notities komen deels van Discogs, dus van externe invoer. Waarden die beginnen met `=`, `+`, `-`, `@`, tab of CR worden door spreadsheet-apps als formule gezien (OWASP "CSV Injection").

**Acceptance criteria:**
- `TempCsvFileWriter` zet een `'` vóór elke cel die begint met `=`, `+`, `-`, `@`, `\t` of `\r`.
- Numerieke kolommen (bijvoorbeeld BPM, jaar, negatieve getallen indien van toepassing) worden niet onnodig beschadigd. Escape alleen tekstvelden, of accepteer een `'` vóór negatieve getallen en leg dat vast.
- CSV-import haalt die `'` weer weg, zodat export → import van een Cratewise-bestand hetzelfde resultaat geeft (round-trip-test).
- Unit-test met een titel `=HYPERLINK("http://x","y")` → geëxporteerd als `'=HYPERLINK(...)`.

---

### US-128: Thumbnail-downloads hebben een timeout

**Status: ✅ Resolved (2026-10-23)**

**Priority: Medium · 1 SP**

> Als gebruiker op een slechte verbinding,
> wil ik dat het laden van een hoes na een redelijke tijd stopt,
> zodat lijsten en detailschermen niet blijven wachten op een download die nooit afkomt.

**Context:**
[thumbnail_cache_service.dart:31](lib/application/services/thumbnail_cache_service.dart#L31) en [retry_thumbnail_use_case.dart:69](lib/application/use_cases/retry_thumbnail_use_case.dart#L69) roepen `_httpClient.get(...)` aan zonder `.timeout()`. Bij de Discogs-API-calls zit wel een timeout van 15 s.

**Acceptance criteria:**
- Beide downloads gebruiken `.timeout(...)` (zelfde 15 s als de API-client, of 10 s). Na een timeout volgt hetzelfde pad als bij een netwerkfout (`null` of `RetryThumbnailNetworkError`).
- Een response met een `content-type` die niet met `image/` begint, wordt niet als thumbnail opgeslagen.
- Unit-test met een fake client die nooit antwoordt bewijst de timeout (via een korte timeout die je in de test injecteert).

---

### US-129: Discogs-import met meerdere exemplaren van dezelfde release

**Status: ✅ Resolved (2026-10-23)**

**Priority: Medium · 3 SP**

> Als verzamelaar met twee exemplaren van dezelfde persing,
> wil ik dat een Discogs-import beide exemplaren correct koppelt of importeert,
> zodat mijn lokale collectie overeenkomt met Discogs.

**Context:**
Het detecteren van duplicaten gebeurt alleen op `releaseId`:
- [build_collection_import_preview_use_case.dart:61](lib/application/use_cases/build_collection_import_preview_use_case.dart#L61): `containsRelease(releaseId)` → elke Discogs-instance van een release die lokaal al bestaat, wordt `DuplicateCollectionRow`.
- [execute_collection_import_use_case.dart:96-99](lib/application/use_cases/execute_collection_import_use_case.dart#L96-L99) bouwt `Map<int, CollectionItem>` op `releaseId`. Bij meerdere lokale exemplaren blijft er maar één over. Twee Discogs-instances koppelen dus aan hetzelfde lokale item, de laatste `instanceId` wint en het tweede exemplaar wordt nooit geïmporteerd.
- Bijkomend: de preview doet 2 queries per rij (`_hasPendingDeletion`, `containsRelease`). Dat is N+1 bij grote collecties.

**Acceptance criteria:**
- Eerst reproduceren met een test: Discogs heeft 2 instances van release X en lokaal staat 1 ongekoppeld exemplaar van X. Verwacht: 1 gekoppeld, 1 nieuw geïmporteerd.
- Koppelen gebeurt per `discogsInstanceId`. Een lokaal item dat al gekoppeld is, wordt niet opnieuw gekoppeld aan een andere instance.
- Een Discogs-instance waarvan de `instanceId` lokaal al bestaat, telt als "Already linked".
- De preview laadt lokale items en tombstones één keer vooraf (geen query per rij).
- Bestaande tests voor gewone duplicaten blijven groen.
- *Uitvoering:* de preview kiest per Discogs-instance een lokaal doel (`DuplicateCollectionRow.linkTargetId`). Een tombstone met instance id blokkeert alleen dat exemplaar. Lokale items zonder `discogsInstanceId` (ook al gesynchroniseerde items van vóór v9) zijn koppelbaar en krijgen zo alsnog hun instance id.

---

### US-130: Collection- en wishlist-import/export-schermen delen één implementatie

**Status: ✅ Resolved (2026-10-23)**

**Priority: Medium · 8 SP**

> Als ontwikkelaar,
> wil ik dat de vier paren collection/wishlist preview-schermen één gedeelde implementatie hebben,
> zodat een bugfix of UI-wijziging niet steeds twee keer gedaan hoeft te worden.

**Context:**
Acht schermen (samen ~5.350 regels) zijn per paar vrijwel kopieën. Per paar verschilt alleen de typenaam (60 tot 80 regels):

| Paar | Regels per scherm | Verschillende regels |
|---|---|---|
| `*_csv_import_preview_screen.dart` | 711 | 64 |
| `*_import_preview_screen.dart` | 697 | 82 |
| `*_export_preview_screen.dart` | 688 | 76 |
| `*_csv_export_preview_screen.dart` | 578 | 58 |

**Technische aanpak:**
Gebruik geen nieuwe abstractielaag per entiteit. Maak per paar één generiek scherm (`ImportPreviewScreen<TPreview, TResult>` of iets vergelijkbaars) dat de entiteit-specifieke delen (use cases, labels, row-mapping) als constructor-parameters of een klein recordtype meekrijgt. De router geeft de collection- of wishlist-variant door.

**Acceptance criteria:**
- Per paar staat er nog maar één schermbestand in `lib/presentation/screens/`. Het totaal aantal regels van de acht schermen daalt met minimaal 40%.
- Gedrag en UI blijven per variant hetzelfde. Alle bestaande widget-tests voor beide varianten blijven groen zonder inhoudelijke aanpassing van de asserts.
- Routes en deep links veranderen niet.
- *Uitvoering:* 5.348 → 3.178 regels (−40,6%). Per paar heeft het domein een klein interface (`CsvExportPreview`, `CsvImportPreview`, `DiscogsExportPreview`, `DiscogsImportPreview` + bijbehorende `…Done`), daarnaast één generiek scherm en twee dunne publieke wrappers met de oude klassenamen en constructors. Router en tests gebruiken dezelfde klassen; in de tests zijn alleen imports aangepast.
- Niet in scope: de detailschermen (`collection_detail_screen.dart` 1.735 r., `wishlist_detail_screen.dart` 1.268 r.). Doe die in een aparte story als deze aanpak bevalt.

---

### US-131: Lege scaffolding-mappen en dubbele DB-open in `main.dart` opruimen

**Priority: Low · 1 SP**

> Als ontwikkelaar,
> wil ik dat de mapstructuur alleen bevat wat de app echt gebruikt,
> zodat nieuwe code niet in een dode `features/`- of `core/`-structuur terechtkomt.

**Context:**
- Lokaal bestaan lege template-mappen: `lib/features/*/{data,domain,presentation}/...` (63 mappen), `lib/core/*`, `lib/app/theme`, `lib/shared/{models,extensions,widgets}`, `test/features/*` en `test/core`. Daarnaast zijn er `.gitkeep`-bestanden die niet meer nodig zijn in mappen die al code bevatten, plus `lib/infrastructure/sync/` (alleen `.gitkeep`).
- [main.dart:18-27](lib/main.dart#L18-L27) opent een tweede `AppDatabase` op hetzelfde bestand voor `PurgeStaleFailedActionsUseCase`, terwijl [app.dart:46](lib/app/app.dart#L46) de app-brede instantie aanmaakt. Dat gaat in tegen de AC van US-94 ("precies één `AppDatabase`-instantie").

**Acceptance criteria:**
- Alle lege mappen hierboven en `lib/infrastructure/sync/` zijn verwijderd. `.gitkeep` staat alleen nog in mappen die anders leeg zouden zijn (verwacht: geen).
- De purge van verouderde failed actions draait op de app-brede `AppRepositories` (bijvoorbeeld in `_CratewiseAppState.initState`, als fire-and-forget na het aanmaken). `main.dart` importeert `app_database.dart` niet meer.
- `flutter analyze` en `flutter test` zijn groen.

---

### US-132: Use cases vangen alleen verwachte exceptions

**Priority: Low · 3 SP**

> Als ontwikkelaar,
> wil ik dat programmeerfouten niet stil worden opgevangen als "netwerkfout" of "kon niet opslaan",
> zodat bugs in tests en crashrapporten zichtbaar worden in plaats van te verdwijnen.

**Context:**
`lib/` bevat 107× `catch (_)`, vooral in `lib/application/use_cases/`. Een deel is terecht (best-effort cleanup, bijvoorbeeld [clean_up_stale_csv_exports_use_case.dart](lib/application/use_cases/clean_up_stale_csv_exports_use_case.dart)). Maar bijvoorbeeld [execute_collection_import_use_case.dart:117](lib/application/use_cases/execute_collection_import_use_case.dart#L117) en `:204` vangen ook een `TypeError` of `StateError` op en maken er "Could not save item" of "Import could not be completed" van. Ook [`DiscogsApiClient._get`](lib/infrastructure/discogs/discogs_api_client.dart#L234-L241) vertaalt elke `Exception` naar `NetworkError`.

**Acceptance criteria:**
- In use cases die de gebruiker een foutmelding tonen, vangt `catch` alleen `AppError`, `DriftWrapException`/`SqliteException`, `FileSystemException` of `IOException`. Overige fouten worden óf doorgegooid, óf vóór het fallback-resultaat gelogd via `dev.log` (zelfde patroon als [discogs_token_storage.dart:79](lib/infrastructure/secure_storage/discogs_token_storage.dart#L79)). Kies één aanpak en pas die overal toe.
- Best-effort `catch (_) {}` in cleanup-paden blijft staan, met een `// best-effort:`-comment.
- `DiscogsApiClient` vangt alleen `TimeoutException`, `SocketException` en `http.ClientException` als `NetworkError`.
- Bestaande tests blijven groen. Er is minimaal één test die laat zien dat een onverwachte fout niet meer als `NetworkError` terugkomt.
