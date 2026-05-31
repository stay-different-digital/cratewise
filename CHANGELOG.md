# Changelog

All notable changes to Cratewise are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased — Phase 2 search API method] — 2026-05-31

### Added

- `DiscogsSearchResultDto` in `lib/infrastructure/discogs/dto/discogs_search_result.dart` — parses a single Discogs search result from JSON: splits the API's combined `"Artist - Title"` field into separate `artist` and `title`, takes the first entry from the `format` and `label` arrays, parses `year` from string to `int?`, normalises an empty `thumb` string to `null`.
- `DiscogsApiClient.searchReleases(query, token)` — calls `GET /database/search?q=…&type=release`; returns `List<DiscogsSearchResultDto>`; reuses the existing typed error hierarchy (`InvalidTokenError`, `RateLimitedError`, `DiscogsUnavailableError`, `NetworkError`); token is passed in headers only and never stored or logged.
- Twelve unit tests added to `test/infrastructure/discogs/discogs_api_client_test.dart` covering: happy-path field parsing (artist, title, format, label, year, country, id, thumbUrl), empty-thumb normalisation, missing-field graceful handling, empty results list, URL query-parameter encoding, all four error status codes, network failure, and token absence from errors.

---

## [Unreleased — Phase 2 search UI] — 2026-05-31

### Added

- `ReleaseSearchResult` model in `lib/domain/models/release_search_result.dart` — `id`, `title`, `artist`, `format`, `label`, `country`, nullable `year`, nullable `coverUrl`.
- `ReleaseSearchResultCard` widget in `lib/presentation/widgets/release_search_result_card.dart` — horizontal card showing cover placeholder (72×72 `Icons.album`), artist, title, format · label, year · country, and `#id`.
- `SearchScreen` replaced — pill-shaped search `TextField` with prefix search icon and clear button; empty state (large search icon + "Search Discogs" heading + prompt text) shown when query is empty; scrollable `ListView` of `ReleaseSearchResultCard` widgets shown when query is non-empty.
- Five hardcoded placeholder releases (Miles Davis, The Beatles, Daft Punk, Amy Winehouse, Boards of Canada) displayed for any non-empty query — no API call, no token used.
- Twelve widget tests in `test/presentation/screens/search_screen_test.dart` covering empty state content, results on query entry, each card field (artist, title, format/label, year/country, release ID, cover icon), clear button behaviour.

---

## [Unreleased — Phase 2 iOS Keychain diagnostics] — 2026-05-31

### Changed

- `DiscogsTokenStorage.saveCredentials` — temporary `dart:developer` debug log added to surface the raw iOS Keychain error code (`PlatformException` code + message, no token value) while investigating a Keychain write failure on iOS. To be removed once root cause is confirmed and fixed.

---

## [Unreleased — Phase 2 secure token storage] — 2026-05-31

### Added

- `flutter_secure_storage: ^9.2.4` added to `pubspec.yaml`; CocoaPods required for iOS (installed via Homebrew).
- `StorageError` added to `lib/shared/errors/app_error.dart` — typed error for keychain/keystore failures.
- `ConnectionStatus` model in `lib/domain/models/connection_status.dart` — `isConnected` + nullable `username`.
- `TokenStorage` abstract interface in `lib/domain/repositories/token_storage.dart` — `loadToken`, `loadUsername`, `saveCredentials`, `deleteCredentials`.
- `DiscogsTokenStorage` in `lib/infrastructure/secure_storage/discogs_token_storage.dart` — wraps `FlutterSecureStorage` using keys `discogs_token` and `discogs_username`; all platform exceptions converted to `StorageError`; token never logged.
- `DiscogsConnectionService` in `lib/application/services/discogs_connection_service.dart` — coordinates `TokenValidationService` + `TokenStorage`: `loadStatus()` (degrades gracefully on storage failure), `connect(token)` (validate then save), `disconnect()` (delete credentials).
- `DiscogsTokenSection` now accepts optional `DiscogsConnectionService`; on `initState` loads saved connection status; on successful validation saves credentials and transitions to connected state; connected state shows masked token display (`••••••••••••••••`) and "Connected as @username" with a Disconnect button; Disconnect transitions back to idle and clears credentials.
- Ten new tests in `test/presentation/widgets/discogs_token_section_test.dart` (replacing the previous 8 validation tests): loading indicator, connected state with masked token, each error path (401/403, 429, network, storage), button disabled during load, disconnect returns to idle, connected state on startup from saved credentials, token absent from rendered Text widgets.
- Nine unit tests in `test/application/services/discogs_connection_service_test.dart` covering all `loadStatus`/`connect`/`disconnect` paths including storage failures and token-in-error-message absence check.

---

## [Unreleased — Phase 2 token validation UI] — 2026-05-31

### Added

- `TokenValidationService` in `lib/application/services/token_validation_service.dart` — wraps `DiscogsApiClient.fetchIdentity`; keeps API calls out of the widget layer.
- `_ValidationStatus` enum (`idle`, `loading`, `success`, `failure`) and async `_validate()` method in `DiscogsTokenSection` — calls the service, guards with `!mounted` after await, maps each `AppError` subtype to a user-friendly message.
- Loading indicator (`CircularProgressIndicator` + "Validating…" label) shown while the request is in flight.
- Success row ("Connected as @username") shown on 200 response.
- Error row with friendly message for each failure case: `InvalidTokenError` → "Token not recognised…", `RateLimitedError` → "Too many requests…", `NetworkError` → "No internet connection…", other `AppError` → "Could not reach Discogs…".
- Validate and Remove buttons both disabled while loading.
- Remove clears validation status in addition to clearing the text field.
- Eight new widget tests: loading indicator, success message with username, each error path (401, 429, network), button disabled during load, status clears on Remove, and token value absent from all rendered `Text` widgets.

---

## [Unreleased — Phase 2 Discogs API client] — 2026-05-31

### Added

- `DiscogsApiClient` in `lib/infrastructure/discogs/discogs_api_client.dart` — injectable `http.Client`, `fetchIdentity(token)` method targeting `/oauth/identity`, correct `User-Agent` and `Authorization` headers, no token persisted or logged.
- `DiscogsIdentity` DTO in `lib/infrastructure/discogs/dto/discogs_identity.dart` — `username` and `resourceUrl` fields parsed from JSON.
- Typed error hierarchy in `lib/shared/errors/app_error.dart` — sealed `AppError` base with `InvalidTokenError` (401/403), `RateLimitedError` (429), `DiscogsUnavailableError` (5xx), `NetworkError` (socket/transport), and `UnexpectedApiError(statusCode)`.
- `http: ^1.6.0` added to `pubspec.yaml`.
- Eight unit tests covering: 200 identity parse, 401/403 → `InvalidTokenError`, 429 → `RateLimitedError`, 500 → `DiscogsUnavailableError`, transport exception → `NetworkError`, correct request headers, and token absence from error messages.

---

## [Unreleased]

### Added

- `AppBottomNav` widget — Material 3 `NavigationBar` with five destinations (Search, Collection, Wishlist, Scan, Settings) for phone layouts.
- `AppNavRail` widget — `NavigationRail` with the same five destinations for wider iPad layouts.
- Placeholder screens for Search, Collection, Wishlist, Barcode Scan, and Settings, each showing a centred icon and description text.
- `AppRoutes` constants in `router.dart` (`/search`, `/collection`, `/wishlist`, `/barcode-scan`, `/settings`).
- Five widget tests covering app title, wide/narrow layout selection, all-tab reachability, and tab switching.

### Changed

- `HomeShellScreen` rewritten as a `StatefulWidget` navigation shell using `IndexedStack`. Phones (< 700 logical pixels) get a bottom `NavigationBar`; wider screens get a `NavigationRail` in a `Row` layout.
- `SettingsScreen` replaced static placeholder with a scrollable `ListView` containing the Discogs connection section.
- Nav reachability test updated to assert on Discogs section heading instead of the removed placeholder text.

---

## [Unreleased — Phase 2 token input UI] — 2026-05-31

### Added

- `DiscogsTokenSection` widget — masked `TextField` for a Discogs personal access token with a show/hide `IconButton`, helper text pointing to `discogs.com/settings/developers`, and "Validate token" / "Remove token" buttons that are disabled while the field is empty.
- "Remove token" clears the in-memory field (UI state only; no storage in this slice).
- `autocorrect: false` and `enableSuggestions: false` on the token field keep the value out of keyboard suggestion history.
- `TextEditingController` is disposed correctly in `State.dispose`.
- Seven widget tests covering: token masked by default, show/hide toggle (both directions), help URL text present, buttons disabled when field is empty, buttons enabled with text, and Remove clearing the field.

---

## [0.0.2] — 2026-05-31

### Added

- Full Flutter project scaffolding for Android and iOS/iPadOS.
- `lib/app/app.dart` — `CratewiseApp` root widget with `MaterialApp`, light/dark theme, and `HomeShellScreen` as home.
- `lib/app/router.dart` — initial `buildHomeRoute` helper.
- `lib/app/theme.dart` — Material 3 `ColorScheme` seeded from the Cratewise brand colour.
- `lib/main.dart` — app entry point.
- Initial `HomeShellScreen` with a wide/narrow layout using `LayoutBuilder` and `NavigationRail` placeholder (three destinations).
- Layered folder structure under `lib/` — `application/`, `domain/`, `infrastructure/`, `presentation/`, `shared/` — with `.gitkeep` placeholders.
- Figma reference link for the Airbnb UI Kit added to the design system doc.
- `pubspec.yaml` with Flutter SDK constraint `^3.12.0` and `flutter_lints`.
- Basic CI workflow (`.github/workflows/flutter-ci.yml`).
- `.env.example` with placeholder keys.

---

## [0.0.1] — 2026-05-31

### Added

- `AGENTS.md` — project context, main product goals, development principles, security rules, branding rules, and agent workflow guide.
- `docs/product/PROJECT_BRIEF.md` — app name, target users, MVP scope, and out-of-scope items.
- `docs/product/ROADMAP.md` — nine-phase roadmap from technical foundation through version 1.0 and growth.
- `docs/architecture/ARCHITECTURE.md` — layered folder structure, dependency rules, recommended packages, core data models, error types, and testing priorities.
- `docs/architecture/ADR-0001-use-flutter.md` — decision record for Flutter as the cross-platform framework.
- `docs/architecture/ADR-0002-use-current-token-first.md` — decision record for Discogs personal token as the initial auth strategy.
- `docs/design/DESIGN_SYSTEM.md` — design direction, UI principles, core screens list, accessibility requirements, and Figma references.
- `docs/api/DISCOGS_API.md` — Discogs API notes and usage guidelines.
- `docs/security/SECURITY.md` — token handling rules, secure storage requirements, error message policy, and production login guidance.
- `docs/workflow/AGENT_WORKFLOW.md` — recommended step-by-step agent workflow for planning, implementing, reviewing, and updating docs.
- `docs/workflow/VSCODE_SETUP.md` — VS Code agent mode setup instructions.
- `.github/agents/` — six VS Code agent definitions (Product Planner, Flutter Architect, Flutter Implementer, QA Reviewer, Security Reviewer, UI Designer).
- `.github/prompts/` — reusable prompt files for common tasks (plan feature, implement feature, code review, prepare PR, update docs, start project).
- `.github/skills/` — skill definitions for Airbnb UI Flutter, Discogs API, Flutter features, Flutter testing, local-first data, release checklist, and secure token storage.
- `.vscode/` — workspace settings, recommended extensions, launch configs, and task definitions.
