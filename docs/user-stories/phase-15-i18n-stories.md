# Phase 15: Meertaligheid (i18n)

Aangemaakt: 2026-06-18

Doel: de app standaard in het Engels aanbieden en ondersteuning voor Engels, Duits, Frans, Spaans en Nederlands inbouwen. Gebruikers kunnen de taal handmatig overschrijven in de instellingen.

Verhaalvolgorde: US-112 → US-113 → US-114 (elk bouwt voort op de vorige).

---

### US-112: Stel i18n-infrastructuur op met flutter_localizations

**Priority: Medium · 3 SP**

> Als ontwikkelaar,
> wil ik de i18n-infrastructuur opzetten met Flutter's ingebouwde lokalisatieondersteuning,
> zodat alle teksten in de app via ARB-bestanden beheerd worden en vertaling per taal mogelijk is.

**Package-keuze:**
`flutter_localizations` (onderdeel van de Flutter SDK — geen nieuwe pub.dev-afhankelijkheid) gecombineerd met `intl ^0.20.2` (al aanwezig in `pubspec.yaml`). Gebruik `flutter gen-l10n` (ingebouwd in de Flutter toolchain) voor codegeneratie vanuit ARB-bestanden.

Geen nieuwe dependency nodig. Dit is de door Flutter officieel aanbevolen aanpak.

**Ondersteunde talen:**
| Code | Taal |
|---|---|
| `en` | Engels (standaard) |
| `de` | Duits |
| `fr` | Frans |
| `es` | Spaans |
| `nl` | Nederlands |

**Technische aanpak:**
1. Voeg `flutter_localizations` toe aan `pubspec.yaml` onder `dependencies` (SDK-package).
2. Maak `lib/l10n/` aan met één ARB-bestand per taal: `app_en.arb`, `app_de.arb`, `app_fr.arb`, `app_es.arb`, `app_nl.arb`.
3. Configureer `l10n.yaml` in de root:
   ```yaml
   arb-dir: lib/l10n
   template-arb-file: app_en.arb
   output-localization-file: app_localizations.dart
   ```
4. Activeer in `MaterialApp`: `localizationsDelegates` en `supportedLocales`.
5. Standaardtaal: `en`. Fallback bij onbekende apparaattaal: `en`.
6. In deze story hoeven nog geen schermen vertaald te worden — de ARB-bestanden bevatten alleen de sleutels die nodig zijn voor de smoke test (bijv. app-naam, één zichtbare string per scherm).

**Acceptance criteria:**
- `pubspec.yaml` heeft `flutter_localizations` als SDK-dependency en `generate: true` onder `flutter:`.
- `l10n.yaml` is aangemaakt en correct geconfigureerd.
- `lib/l10n/app_en.arb` bestaat en bevat minimaal 3 sleutels als proof-of-concept.
- `lib/l10n/app_de.arb`, `app_fr.arb`, `app_es.arb`, `app_nl.arb` bestaan met dezelfde sleutels (initieel zelfde waarden als EN — vervangen in US-113).
- `flutter gen-l10n` genereert `AppLocalizations` zonder fouten.
- `MaterialApp` heeft `localizationsDelegates` en `supportedLocales` geconfigureerd voor de vijf talen.
- De standaardtaal is `en`; een apparaat met een niet-ondersteunde taal valt terug op `en`.
- `flutter analyze` geeft 0 issues en `flutter test` blijft groen.

**QA-checklist:**
- [ ] Stel het apparaat in op Duits — verifieer dat de app niet crasht.
- [ ] Stel het apparaat in op een niet-ondersteunde taal (bijv. Japans) — verifieer fallback naar Engels.
- [ ] `flutter gen-l10n` draait zonder fouten.

---

### US-113: Vertaal kernsschermen naar alle vijf talen

**Priority: Medium · 5 SP**

> Als gebruiker die de app in zijn eigen taal wil gebruiken,
> wil ik dat alle zichtbare teksten in de kernsschermen correct vertaald zijn in mijn taal,
> zodat de app aanvoelt alsof hij voor mij gemaakt is.

**Context:**
Bouwt voort op US-112. Alle hardcoded `String`-literals in de kernsschermen worden vervangen door `AppLocalizations.of(context)!.sleutelNaam`. Vertalingen worden toegevoegd aan de vijf ARB-bestanden.

**Schermen in scope (kernsschermen, eerste prioriteit):**
- Zoekscherm (`search_screen.dart`)
- Collectiescherm (`collection_screen.dart`)
- Verlanglijstscherm (`wishlist_screen.dart`)
- Instellingenscherm (`settings_screen.dart`)
- Barcode-scanscherm (`barcode_scan_screen.dart`)
- Navigatielabels (bottom navigation / tabs)

**Schermen buiten scope voor deze story (fase 2):**
- Detailschermen (release, collectie, verlanglijst)
- Import/export-schermen
- Onboarding (US-104)
- Foutmeldingen en SnackBars

**Taalbestanden:**
Alle vertalingen worden professioneel aangeleverd of via een vertaalservice beoordeeld — geen machine-only vertalingen voor de store-release.

**Acceptance criteria:**
- Alle zichtbare `String`-literals in de zes schermen-in-scope zijn vervangen door `AppLocalizations`-sleutels.
- `app_en.arb`, `app_de.arb`, `app_fr.arb`, `app_es.arb`, `app_nl.arb` bevatten vertaalde waarden voor alle nieuwe sleutels.
- Geen hardcoded UI-teksten meer in de zes betrokken bestanden (met uitzondering van debuglabels en technische strings die nooit getoond worden aan eindgebruikers).
- `flutter analyze` geeft 0 issues.
- Bestaande widget-tests zijn bijgewerkt om een `LocalizationsDelegate` mee te geven in de testopzet; tests blijven groen.
- Nieuwe widget-tests controleren dat minimaal één vertaalde string per scherm correct wordt weergegeven in een Nederlandstalige context.

**QA-checklist:**
- [ ] Stel apparaat in op Duits — doorloop alle zes schermen en verifieer dat teksten in het Duits zijn.
- [ ] Stel apparaat in op Engels — verifieer dat de Engelse standaard actief is.
- [ ] Stel apparaat in op Spaans — verifieer Spaanse teksten.
- [ ] Stel apparaat in op Frans — verifieer Franse teksten.
- [ ] Stel apparaat in op Nederlands — verifieer Nederlandse teksten.
- [ ] Controleer of er geen tekst meer in hard-coded Engels zichtbaar is op de zes schermen.

---

### US-114: Taalvoorkeur instellen in het instellingenscherm

**Priority: Medium · 3 SP**

> Als gebruiker,
> wil ik de taal van de app handmatig kunnen instellen in de instellingen,
> zodat de app mijn voorkeurstaal gebruikt ongeacht de apparaatinstelling.

**Context:**
Bouwt voort op US-112 en US-113. Standaard volgt de app de apparaattaal (met fallback naar Engels). Deze story voegt een expliciete override toe in het instellingenscherm. De gekozen taal wordt persistent opgeslagen.

**Technische aanpak:**
- Opslaan van taalvoorkeur via `flutter_secure_storage` of `shared_preferences` (al aanwezig of minimal toevoeging).
- De `MaterialApp` krijgt een `locale`-parameter die reageert op de opgeslagen voorkeur.
- Optie "Apparaatinstelling volgen" = geen override, standaardgedrag.
- Taalwisseling is direct zichtbaar zonder app-herstart.

**Acceptance criteria:**
- Het instellingenscherm heeft een nieuwe sectie **"Taal"** met een keuzeoptie voor: Apparaatinstelling, English, Deutsch, Français, Español, Nederlands.
- De geselecteerde taal wordt direct toegepast (alle schermen tonen de nieuwe taal zonder herstart).
- De taalvoorkeur blijft behouden na het afsluiten en opnieuw openen van de app.
- "Apparaatinstelling volgen" is de standaard (geen opgeslagen waarde = gebruik apparaattaal).
- `flutter analyze` geeft 0 issues en `flutter test` blijft groen; voeg widget-tests toe die de persistentie en de directe omschakeling verifiëren.

**QA-checklist:**
- [ ] Stel taal in op Duits in de app terwijl het apparaat op Engels staat — verifieer dat alle schermen in het Duits zijn.
- [ ] Sluit de app, open opnieuw — verifieer dat Duits behouden blijft.
- [ ] Schakel terug naar "Apparaatinstelling" — verifieer dat de apparaattaal weer actief is.
- [ ] Wissel snel tussen twee talen — verifieer dat de UI direct en zonder crash omschakelt.
