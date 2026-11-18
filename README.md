# Cratewise

Cratewise is a Flutter app for vinyl collectors — search Discogs and
manage your record collection and wishlist, online or offline.

It is an independent Discogs companion app. It uses the Discogs API, but it is
not affiliated with or endorsed by Discogs.

## Contents

- [Features](#features)
- [Platforms](#platforms)
- [Tech stack & architecture](#tech-stack--architecture)
- [Project structure](#project-structure)
- [Getting started](#getting-started)
- [Running tests & checks](#running-tests--checks)
- [Releases](#releases)
- [Discogs setup](#discogs-setup)
- [Knowledge graph (graphify)](#knowledge-graph-graphify)
- [Contributing & conventions](#contributing--conventions)
- [License & status](#license--status)

## Features

- **Search** Discogs for releases, artists, and labels, limit to vinyl, and sort
  by relevance or by when a release was added to Discogs — all from one filter
  button; jump from a release to its label.
- **Collection & wishlist** management with membership indicators across search
  and detail screens; one filter button with sorting by date added (newest or
  oldest first) and filters by format type, decade, label, genre and more.
- **Collection statistics** in their own tab.
- **Discogs import/export** — sync your collection and wantlist both ways,
  including opt-in deletion sync.
- **Automatic sync (opt-in)** — new records go to Discogs as you add them, and
  records added on Discogs come in when the app opens.
- **CSV import/export** for moving data in and out.
- **Offline-first** local storage — browse and edit without a connection.
- **Thumbnail caching** for fast, low-bandwidth artwork.
- **Sync status** and **failed-action retry** so nothing is silently lost.

## Platforms

The app is built for:

- Android phones
- iPhone
- iPad

Desktop and web targets are out of scope.

## Tech stack & architecture

- **Flutter 3.50 / Dart 3.14** (`sdk: ^3.12.0`), with Material from the
  standalone **material_ui** package.
- **Clean architecture** with a strict dependency rule — outer layers depend
  inward only: `presentation` → `application` → `domain`, with
  `infrastructure` implementing `domain` contracts.
- **Drift (SQLite)** for local persistence.
- **GoRouter** for navigation, **flutter_secure_storage** for the Discogs token,
  **http** for the Discogs API, and **csv** for import/export.

See [docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md) for the
full layer breakdown, data model, and the architecture decision records under
[docs/architecture/](docs/architecture/).

## Project structure

```text
lib/
  main.dart
  app/              # app shell, router, theme
  presentation/     # screens, widgets, design system
  application/      # use cases, state, services
  domain/           # models, repository contracts, value objects
  infrastructure/   # Discogs API, local DB, secure storage, sync, CSV
  shared/           # errors, utils, constants
test/               # ~2400+ widget & unit tests
android/  ios/
```

The `docs/` tree holds the supporting documentation:

- [docs/architecture/](docs/architecture/) — architecture overview and ADRs.
- [docs/api/](docs/api/) — Discogs API notes ([DISCOGS_API.md](docs/api/DISCOGS_API.md)).
- [docs/product/](docs/product/) — product roadmap ([ROADMAP_V2.md](docs/product/ROADMAP_V2.md)).
- [docs/design/](docs/design/) — design system.
- [docs/security/](docs/security/) — security model and token handling.
- [docs/qa/](docs/qa/) — QA plans and results.
- [docs/release/](docs/release/) — release and store-review process.
- [docs/store/](docs/store/) — store listings and the [privacy policy](docs/store/PRIVACY_POLICY.md).
- [docs/user-stories/](docs/user-stories/) — the user-story backlog.
- [docs/beta/](docs/beta/), [docs/workflow/](docs/workflow/), [docs/archive/](docs/archive/) — beta triage, workflow notes, and history.

## Getting started

Prerequisites:

- The **Flutter SDK** (Dart `^3.12.0`; developed on Flutter 3.50).
- **CocoaPods** for iOS builds (e.g. via Homebrew: `brew install cocoapods`).

Then:

```bash
flutter doctor
flutter pub get
flutter run
```

To run on a specific platform, start a simulator/emulator first:

```bash
# iOS
open -a Simulator
flutter run

# Android: start an emulator from Android Studio (Device Manager), then
flutter run
```

## Running tests & checks

One command runs the same checks as CI (format, analyze, all tests, Android
release build with the Kotlin Gradle Plugin check, iOS build):

```bash
tool/ci_local.sh            # everything
tool/ci_local.sh --skip-ios # without the iOS build
```

GitHub Actions doesn't run on every push or pull request: the Flutter CI
workflow only runs for a major release tag (`vX.0.0`) or when started by hand
(Actions → Flutter CI → Run workflow; tick **ios** for the macOS build).

Device tests (on an emulator or simulator, skipped in normal test runs):

- `integration_test/app_upgrade_test.dart` — data survives an app update
  (see the file header).
- `integration_test/discogs_live_test.dart` — against the real Discogs API
  with your own token in `.env` (`--dart-define-from-file=.env`; see
  `.env.example`). Never commit `.env`.

## Releases

Signed Android APKs are on the
[GitHub Releases](https://github.com/stay-different-digital/cratewise/releases)
page. Cratewise is not published to the App Store or Google Play. How a
release is made: [docs/release/RELEASE.md](docs/release/RELEASE.md).

## Discogs setup

Cratewise talks to Discogs with a **personal access token** you enter in-app
under **Settings**. Create one on Discogs under **Settings → Developers →
Generate new token**. The token is stored with secure storage and masked in the UI
— it is never hardcoded or committed. See [docs/api/DISCOGS_API.md](docs/api/DISCOGS_API.md)
for endpoint details.

## Knowledge graph (graphify)

Optional, for local development: the `graphify` tool
builds a queryable knowledge graph of the code in `graphify-out/` (not in the
repository; build it yourself with `graphify update .`):

```bash
graphify query "<question>"      # scoped subgraph for a question
graphify path "<A>" "<B>"        # relationship between two concepts
graphify explain "<concept>"     # focused explanation of one concept
graphify update .                # refresh the graph after code changes (AST-only)
```

See [CLAUDE.md](CLAUDE.md) for the full workflow.

## Contributing & conventions

- Work on a branch; commit to it with a clear, descriptive message.
- See [CONTRIBUTING.md](CONTRIBUTING.md): open an issue first and wait for
  the `accepted` label before opening a pull request.
- Before committing, run `tool/ci_local.sh`.
- After changing code, refresh the knowledge graph with `graphify update .`.
- **Never** commit secrets — no Discogs tokens, API keys, or `.env` files.
  Tokens live only in secure storage and are masked in the UI.

Questions or feedback: **hellowerecratewise@gmail.com**.

## License & status

- **Version:** see [pubspec.yaml](pubspec.yaml); release notes in
  [CHANGELOG.md](CHANGELOG.md).
- **License:** [GNU General Public License v3.0](LICENSE). You may use, study,
  change and share the code; if you distribute a modified version, it must be
  released under the GPL-3.0 as well.
- **Name and logo:** the GPL covers the code, not the name "Cratewise" or its
  logo. Please don't publish a modified app under that name or logo.
- **Discogs:** data from the Discogs API falls under the
  Discogs API terms (see [discogs.com/developers](https://www.discogs.com/developers)),
  not under this license. Cratewise is not affiliated with Discogs.
- **Privacy:** see the [privacy policy](docs/store/PRIVACY_POLICY.md).
