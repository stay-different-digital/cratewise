# AGENTS.md

## Project context

Cratewise is a Flutter app for vinyl collectors and DJs.

The app is an independent Discogs companion. It must never pretend to be Discogs.

The app supports:

- Android
- Windows desktop

The app uses:

- Flutter
- Dart
- Discogs API
- Local-first storage
- Secure token storage

## Main product goals

The app helps users:

- Search Discogs data
- View release details
- Add releases to a local collection
- Manage wishlist items
- Scan barcodes on Android
- Enter barcodes manually on Windows
- Use the collection offline
- Import and export CSV files

## Important docs

Read these files before planning or implementing:

- [Project brief](docs/product/PROJECT_BRIEF.md)
- [Roadmap](docs/product/ROADMAP.md)
- [Architecture](docs/architecture/ARCHITECTURE.md)
- [Design system](docs/design/DESIGN_SYSTEM.md)
- [Discogs API notes](docs/api/DISCOGS_API.md)
- [Security rules](docs/security/SECURITY.md)
- [Workflow](docs/workflow/AGENT_WORKFLOW.md)

## Development principles

- Keep changes small.
- Plan before coding.
- Implement one feature slice at a time.
- Keep UI, domain logic, infrastructure, and app state separated.
- Avoid large files.
- Add tests for important behavior.
- Run formatting before finalizing work.
- Update documentation when decisions or behavior change.

## Security principles

- Never hardcode Discogs tokens.
- Never hardcode API secrets.
- Never log tokens.
- Never show tokens in error messages.
- Store tokens only with secure storage.
- Use a backend proxy later if production OAuth secrets are needed.

## Branding principles

Allowed wording:

- Connect your Discogs account
- Search Discogs
- Import from Discogs
- Uses the Discogs API

Avoid wording that suggests an official partnership.

Do not use:

- Discogs logo without permission
- Discogs brand identity
- Airbnb logo
- Airbnb brand identity

## Agent workflow

Use these agents:

- Product Planner for scope and acceptance criteria
- Flutter Architect for technical plans and architecture
- Flutter Implementer for code changes
- QA Reviewer for tests and quality checks
- Security Reviewer for authentication and token safety
- UI Designer for Figma-inspired Flutter UI guidance
