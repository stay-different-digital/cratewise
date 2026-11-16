# Phase 18: Cratewise op de nieuwste Flutter (november 2026)

Aangemaakt: 2026-11-16

Doel: Cratewise draait schoon en toekomstbestendig op Flutter 3.50 (Dart 3.14). De basis-upgrade is al gedaan in 1.2.1 (material_ui, go_router 18, Gradle 9.5/AGP 9.3, JDK 21). Deze fase ruimt de resterende waarschuwingen en verouderde dependencies op. Nummering loopt door vanaf US-149.

Uitgangssituatie (2026-11-16, Flutter 3.50.0):
- `flutter analyze` 0 issues, 2618 tests groen, debug/release-APK en iOS-build slagen.
- Android-build waarschuwt: `file_picker`, `package_info_plus`, `sensors_plus`, `share_plus` gebruiken nog de losse Kotlin Gradle-plugin; een volgende Flutter-versie bouwt dat niet meer.
- `flutter pub outdated`: major-updates beschikbaar voor `file_picker` (10→13), `flutter_secure_storage` (9→11), `package_info_plus` (8→10), `share_plus` (10→13), `csv` (6→8), `cupertino_icons` (1→2); minor-updates voor `drift`, `drift_dev`, `build_runner`, `sensors_plus`, `url_launcher`, `uuid`.
- `sqlite3_flutter_libs: ^0.6.0+eol` is end-of-life.
- `flutter build ios --simulator` faalt in Flutters framework-kopieerstap (architectuurvolgorde).

Volgorde: US-150 (vangnet) eerst. Daarna de plugins per stuk (US-151 t/m US-154), dan US-159 (app op Built-in Kotlin), dan de overige updates (US-155 t/m US-157), en als laatste US-158 (controle op toestel). Elke story levert een groene build en een groene CI op.

Geen store-releases (zie besluit 2026-11-16): versie en CHANGELOG per story volgens ADR-0003, zonder indiening.

## Overzicht

| Story | Titel | Prio | SP | Hangt af van |
|---|---|---|---|---|
| US-150 | Vangnet: build-checks voor Android, iOS en de Kotlin-waarschuwing | High | 2 | — |
| US-151 | `share_plus` 10 → 13 | High | 2 | US-150 |
| US-152 | `package_info_plus` 8 → 10 | High | 1 | US-150 |
| US-153 | `sensors_plus` 7.1 met Built-in Kotlin | High | 1 | US-150 |
| US-154 | `file_picker` 10 → 13 | High | 3 | US-150 |
| US-155 | `flutter_secure_storage` 9 → 11 zonder verlies van token | High | 3 | US-150 |
| US-156 | `sqlite3_flutter_libs` (eol) vervangen; drift naar 2.35 | Medium | 3 | US-150 |
| US-157 | Overige updates: `csv` 8, `cupertino_icons` 2, minors | Low | 2 | US-150 |
| US-159 | App naar Built-in Kotlin (`android.builtInKotlin=true`) | High | 1 | US-151–154 |
| US-160 | `flutter_secure_storage` 10 → 11 | Low | 1 | US-155 + elke installatie heeft een 10-build gedraaid |
| US-158 | Volledige controle op Flutter 3.50 op toestel en simulator | Medium | 2 | US-151–157, US-159 |

Totaal: 21 SP.

---

### US-150: Vangnet: build-checks voor Android, iOS en de Kotlin-waarschuwing

**Status: ✅ Resolved (2026-11-16)** — CI bouwt release-APK en controleert de KGP-waarschuwing (`continue-on-error` tot US-159); `tool/run_ios_simulator.sh` voor de simulator. CI groen.

**Priority: High · 2 SP**

> Als ontwikkelaar,
> wil ik dat CI faalt zodra een build of een Flutter-waarschuwing over plugins terugkomt,
> zodat de upgrades in deze fase aantoonbaar iets oplossen en niet stilletjes terugvallen.

**Context:**
CI bouwt nu alleen een Android-debug-APK en een unsigned iOS-debugbuild. De release-build (met lint) faalde eerder pas lokaal, en de Kotlin-pluginwaarschuwing is alleen in de buildoutput zichtbaar.

**Acceptance criteria:**
- CI bouwt ook `flutter build apk --release` (met debug-signing als er geen keystore is).
- Een CI-stap faalt als de buildoutput de waarschuwing "apply Kotlin Gradle Plugin (KGP)" bevat. Tot US-151–154 klaar zijn staat deze stap op `continue-on-error`, met een TODO die naar die stories verwijst.
- `flutter build ios --simulator` werkt lokaal, of de workaround (xcodebuild voor één simulator met `ONLY_ACTIVE_ARCH=YES`) staat als script in de repo en in `docs/release/RELEASE_BUILD.md`.
- CI blijft gepind op de Flutter-versie die lokaal gebruikt wordt.

---

### US-151: `share_plus` 10 → 13

**Status: ✅ Resolved (2026-11-16)** — `share_plus` 13.3.1; aanroepen naar `SharePlus.instance.share(ShareParams(...))`. Deelvenster met CSV gecontroleerd op Android-emulator. Opgeleverd samen met US-151, US-152, US-154 en US-155: die vier hangen via `win32` 6 aan elkaar en lossen alleen samen op.

**Priority: High · 2 SP**

> Als ontwikkelaar,
> wil ik `share_plus` op de huidige major,
> zodat de app blijft bouwen als Flutter de losse Kotlin-plugin weigert.

**Context:**
Gebruikt bij delen van CSV-exports. Tussen 10 en 13 is de API gewijzigd (o.a. `SharePlus.instance.share(ShareParams(...))` in plaats van `Share.shareXFiles`); eerst de changelog lezen.

**Acceptance criteria:**
- `share_plus` ^13 in `pubspec.yaml`; alle aanroepen gemigreerd volgens de changelog.
- De Android-build noemt `share_plus` niet meer in de KGP-waarschuwing.
- Delen van een CSV-export werkt op Android-emulator en iOS-simulator (bestand komt aan in het deelvenster).
- Bestaande tests groen; een test op de deel-aanroep is aangepast aan de nieuwe API.

---

### US-152: `package_info_plus` 8 → 10

**Status: ✅ Resolved (2026-11-16)** — `package_info_plus` 10.2.2; API ongewijzigd. Opgeleverd samen met US-151, US-152, US-154 en US-155: die vier hangen via `win32` 6 aan elkaar en lossen alleen samen op.

**Priority: High · 1 SP**

> Als gebruiker,
> wil ik onderaan Instellingen en op het startscherm de juiste versie zien,
> ook na de pluginupdate.

**Context:**
Gebruikt voor de versieweergave (US-72). Changelog 9 en 10 lezen.

**Acceptance criteria:**
- `package_info_plus` ^10; versie verschijnt als `1.2.x.y` op onboarding en in Instellingen.
- Niet meer in de KGP-waarschuwing.
- Bestaande versietests groen.

---

### US-153: `sensors_plus` 7.1 met Built-in Kotlin

**Status: ⛔ Blocked — wacht op upstream-release (2026-11-16)**

De fix staat op de main-branch van plus_plugins (fluttercommunity/plus_plugins#3902 "Add support of built-in Kotlin" en #3950 "apply KGP unless built-in Kotlin is enabled") maar zit nog niet in een release; 7.1.1 is de nieuwste op pub.dev en past KGP altijd toe. Geen git-dependency gebruikt (ongereleaseerde code). Zodra er een release na 7.1.1 is: versie ophogen, schudden testen, daarna US-159.

**Priority: High · 1 SP**

> Als gebruiker,
> wil ik dat schudden (easter eggs, US-109–111) blijft werken,
> zodat die functie de build niet tegenhoudt.

**Context:**
7.1.1 is de nieuwste versie. Eerst nagaan of die de losse Kotlin-plugin nog gebruikt. Zo ja: issue/PR van de plugin volgen, en als er voor de volgende Flutter-release geen fix is, beslissen of de easter eggs blijven.

**Acceptance criteria:**
- `sensors_plus` op de nieuwste versie.
- Niet meer in de KGP-waarschuwing, óf een vastgelegd besluit met link naar het upstream-issue.
- Schudden op Zoeken, Collectie en Verlanglijst werkt op de emulator (sensor-simulatie).

---

### US-154: `file_picker` 10 → 13

**Status: ✅ Resolved (2026-11-16)** — `file_picker` 13.3.3; `FilePicker.pickFile()` + `readAsBytes()`. Systeemkiezer gecontroleerd op Android-emulator. Versie 13 gebruikt op iOS `PHPickerViewController` en niet meer `DKImagePickerController`; of `NSPhotoLibraryUsageDescription` daardoor weg kan, wordt in US-158 bekeken. Opgeleverd samen met US-151, US-152, US-154 en US-155: die vier hangen via `win32` 6 aan elkaar en lossen alleen samen op.

**Priority: High · 3 SP**

> Als gebruiker,
> wil ik CSV-bestanden blijven kiezen voor import,
> ook na de pluginupdate.

**Context:**
Gebruikt bij CSV-import. Drie majors overslaan: changelog 11–13 lezen op API-wijzigingen (`FilePicker.platform.pickFiles`, `FileType`, iOS-rechten). Mogelijk vervalt `NSPhotoLibraryUsageDescription` in `Info.plist`; dan ook het privacybeleid bijwerken.

**Acceptance criteria:**
- `file_picker` ^13; aanroepen gemigreerd.
- Niet meer in de KGP-waarschuwing.
- CSV-import van collectie en verlanglijst werkt op Android-emulator en iOS-simulator.
- `Info.plist`-sleutels kloppen met wat de nieuwe versie vraagt; `RELEASE_BUILD.md` en privacybeleid bijgewerkt als er iets verandert.

---

### US-155: `flutter_secure_storage` 9 → 11 zonder verlies van token

**Status: ✅ Resolved (2026-11-16)** — bewust op **10.3.4**, niet 11. Versie 11 leest data van vóór 10 niet meer; 10 migreert die automatisch. Upgrade-test (`integration_test/secure_storage_upgrade_test.dart`: schrijven met de oude build, verifiëren met de nieuwe eroverheen) slaagt op Android-emulator en iOS-simulator voor token, gebruikersnaam, taal, onboarding, "Alleen vinyl" en auto-sync. Live Discogs-test groen. De stap naar 11: US-160. Opgeleverd samen met US-151, US-152, US-154 en US-155: die vier hangen via `win32` 6 aan elkaar en lossen alleen samen op.

**Priority: High · 3 SP**

> Als gebruiker met een gekoppeld Discogs-account,
> wil ik na de update nog steeds gekoppeld zijn,
> zodat ik mijn token niet opnieuw hoef in te voeren.

**Context:**
Opslag van het Discogs-token, de taalkeuze, onboarding-status, "Alleen vinyl" en de auto-sync-instelling. Majors 10 en 11 veranderen o.a. Android-opslagopties (EncryptedSharedPreferences) en mogelijk de iOS-keychain-instellingen. Een verkeerde migratie betekent dat gebruikers uitgelogd raken of instellingen kwijt zijn.

**Acceptance criteria:**
- `flutter_secure_storage` ^11.
- Een bestaande installatie met versie 9-data (token, taal, onboarding klaar, vinyl aan, auto-sync aan) houdt na de update alle waarden: getest op Android-emulator door eerst de huidige build te installeren, waarden te zetten, en daarna de nieuwe build eroverheen te installeren. Hetzelfde op iOS-simulator.
- De live Discogs-test (`integration_test/discogs_live_test.dart`) slaagt.
- Unit-tests op de opslaglaag groen.

---

### US-156: `sqlite3_flutter_libs` (eol) vervangen; drift naar 2.35

**Status: In Progress**

**Priority: Medium · 3 SP**

> Als gebruiker,
> wil ik dat mijn collectie veilig in de database blijft,
> ook nu de SQLite-bibliotheek niet meer onderhouden wordt.

**Context:**
`sqlite3_flutter_libs: ^0.6.0+eol` is end-of-life. Drift's documentatie noemt de opvolger (vermoedelijk de ingebouwde native assets van `sqlite3` 3.x); eerst nalezen. Tegelijk `drift`/`drift_dev` 2.34 → 2.35 en `build_runner` 2.17.

**Acceptance criteria:**
- Geen eol-dependency meer in `pubspec.yaml`.
- `drift` en `drift_dev` op 2.35.x; gegenereerde code opnieuw gemaakt.
- Migratietests (US-125) groen: elke oude schemaversie migreert naar de huidige zonder dataverlies.
- Een bestaande database op de emulator blijft leesbaar na installatie van de nieuwe build.

---

### US-157: Overige updates: `csv` 8, `cupertino_icons` 2, minors

**Priority: Low · 2 SP**

> Als ontwikkelaar,
> wil ik geen verouderde dependencies meer,
> zodat volgende Flutter-upgrades klein blijven.

**Acceptance criteria:**
- `csv` ^8: CSV-export en -import geven byte-voor-byte dezelfde uitvoer als nu voor de bestaande testbestanden (inclusief de formule-bescherming uit US-127).
- `cupertino_icons` ^2 (of verwijderd als er geen Cupertino-iconen gebruikt worden).
- `url_launcher`, `uuid` en overige minors op de nieuwste versie.
- `flutter pub outdated` toont geen achterstand meer bij directe dependencies, of elke overgebleven regel heeft een vastgelegde reden.

---

### US-159: App naar Built-in Kotlin (`android.builtInKotlin=true`)

**Priority: High · 1 SP**

> Als ontwikkelaar,
> wil ik dat de app Built-in Kotlin gebruikt,
> zodat de KGP-waarschuwing verdwijnt en een volgende Flutter-versie blijft bouwen.

**Context:**
Toegevoegd tijdens US-151 (2026-11-16). Plugins als `share_plus` 13.3 passen de Kotlin Gradle-plugin alleen toe "unless built-in Kotlin is enabled": de waarschuwing verdwijnt pas als ook de app omschakelt. De app is al grotendeels gemigreerd (geen `kotlin-android`, wel `kotlin { compilerOptions }`); `android/gradle.properties` staat nog op `android.builtInKotlin=false`. Bron: docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers.

**Acceptance criteria:**
- `android.builtInKotlin=true` in `android/gradle.properties`; de ongebruikte `org.jetbrains.kotlin.android`-pluginverklaring in `settings.gradle.kts` verwijderd als de build zonder kan.
- Debug- en release-APK bouwen zonder KGP-waarschuwing.
- De CI-stap uit US-150 draait zonder `continue-on-error`.

---

### US-160: `flutter_secure_storage` 10 → 11

**Priority: Low · 1 SP**

> Als ontwikkelaar,
> wil ik op de nieuwste `flutter_secure_storage`,
> zonder dat iemand zijn token of instellingen kwijtraakt.

**Context:**
Toegevoegd bij US-155. Versie 11 kan alleen data lezen die al door versie 10 is gemigreerd. Pas oppakken als elke installatie (zonder store-releases: in de praktijk Freds toestellen) minstens één keer een build met versie 10 heeft gestart.

**Acceptance criteria:**
- `flutter_secure_storage` ^11; `checkUpgradeStatus()` meldt geen dataverlies.
- Upgrade-test (schrijven met een 10-build, verifiëren met de 11-build) slaagt op Android en iOS.

---

### US-158: Volledige controle op Flutter 3.50 op toestel en simulator

**Priority: Medium · 2 SP**

> Als ontwikkelaar,
> wil ik na alle updates één volledige controle,
> zodat vaststaat dat Cratewise op Flutter 3.50 werkt zoals vóór de upgrade.

**Acceptance criteria:**
- `flutter analyze` 0 issues, alle tests groen, CI groen inclusief de KGP-stap (nu zonder `continue-on-error`).
- Geen KGP-waarschuwing meer in de Android-build.
- Live Discogs-test slaagt op Android-emulator én iOS-simulator.
- Handmatige rondgang (screenshots in de story): onboarding, alle tabs, zoeken met sortering en vinyl, label-link, toevoegen, filters, statistieken, CSV-export/import, instellingen in het Nederlands. Schermovergangen en iOS terugvegen werken.
- Versie en CHANGELOG bijgewerkt.
