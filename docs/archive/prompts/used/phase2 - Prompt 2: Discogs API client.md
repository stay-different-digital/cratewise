## phase2 - Prompt 2: Discogs API client

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 2 feature slice for Cratewise: create a basic Discogs API client layer.

Scope:
- Keep the existing Flutter app runnable.
- Keep support for Android, iPhone, and iPad.
- Create a Discogs API client in the infrastructure layer.
- Add base URL configuration for the Discogs API.
- Add support for required headers, including User-Agent.
- Add support for passing a current token into requests.
- Add typed error handling for common API errors.
- Add basic rate limit error detection.
- Add a small method that can request the authenticated user identity or another lightweight endpoint suitable for checking if a token works.
- Do not connect this client to the UI yet.
- Do not validate the token from the Settings screen yet.
- Do not store tokens yet.
- Do not add search yet.
- Do not add release details yet.
- Do not hardcode secrets.
- Do not log tokens.

Architecture requirements:
- Keep API logic out of widgets.
- Put Discogs API code under infrastructure, for example:
  lib/infrastructure/discogs/
- Use clear typed models or DTOs.
- Use clear typed exceptions or failures.
- Keep the client testable.

Security requirements:
- The API client may receive a token as an input value.
- The API client must not persist the token.
- The API client must not print the token.
- The API client must not expose the token in error messages.

Acceptance criteria:
- Discogs API client exists in the infrastructure layer.
- Client supports base URL, headers, token input, and safe error handling.
- Client has a lightweight method that can be used later for token validation.
- No UI behavior is changed except where needed for imports or wiring.
- No token is stored.
- No token is hardcoded.
- No token is logged.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build apk --debug` passes.
- `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:
- Files changed
- Main architecture choices
- Tests/checks run
- Known limitations
- Recommended next small task