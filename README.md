# Cratewise

Cratewise is a Flutter app for vinyl collectors and DJs — search Discogs and
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
- [Discogs setup](#discogs-setup)
- [Knowledge graph (graphify)](#knowledge-graph-graphify)
- [Contributing & conventions](#contributing--conventions)
- [License & status](#license--status)

## Features

- **Search** Discogs for releases, artists, and labels (with filter chips), sort
  newest or oldest first, limit to vinyl, and jump from a release to its label.
- **Collection & wishlist** management with membership indicators across search
  and detail screens; filters by format type, decade, label, genre and more.
- **Collection statistics** in their own tab.
- **Discogs import/export** — sync your collection and wantlist both ways,
  including opt-in deletion sync.
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

- **Flutter 3.44 / Dart 3.12** (`sdk: ^3.12.0`).
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

- The **Flutter SDK** (Dart `^3.12.0`; developed on Flutter 3.44).
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

```bash
dart format .            # format
flutter analyze          # static analysis
flutter test             # ~2400+ unit & widget tests
```

Build commands:

```bash
flutter build apk --debug                 # Android
flutter build ios --debug --no-codesign   # iOS (no signing)
```

## Discogs setup

Cratewise talks to Discogs with a **personal access token** you enter in-app
under **Settings**. The token is stored with secure storage and masked in the UI
— it is never hardcoded or committed. See [docs/api/DISCOGS_API.md](docs/api/DISCOGS_API.md)
for endpoint details.

## Knowledge graph (graphify)

This repo carries a queryable knowledge graph under `graphify-out/` (god nodes,
community structure, cross-file relationships). For codebase questions, prefer
it over raw browsing:

```bash
graphify query "<question>"      # scoped subgraph for a question
graphify path "<A>" "<B>"        # relationship between two concepts
graphify explain "<concept>"     # focused explanation of one concept
graphify update .                # refresh the graph after code changes (AST-only)
```

See [CLAUDE.md](CLAUDE.md) for the full workflow.

## Contributing & conventions

- Work on a branch; commit to it with a clear, descriptive message.
- Before committing, run **format → analyze → test**:
  ```bash
  dart format . && flutter analyze && flutter test
  ```
- After changing code, refresh the knowledge graph with `graphify update .`.
- **Never** commit secrets — no Discogs tokens, API keys, or `.env` files.
  Tokens live only in secure storage and are masked in the UI.

Questions or feedback: **hellowerecratewise@gmail.com**.

## License & status

- **Version:** `1.0.0+1` (see [pubspec.yaml](pubspec.yaml)); release notes in
  [CHANGELOG.md](CHANGELOG.md).
- **License:** proprietary — all rights reserved. No open-source license is
  granted at this time.
- **Privacy:** see the [privacy policy](docs/store/PRIVACY_POLICY.md).
