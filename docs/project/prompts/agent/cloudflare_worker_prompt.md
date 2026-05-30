# Agent Prompt: Cloudflare Worker for Discogs OAuth

## Prompt

You are working on the Cloudflare Worker Backend-for-Frontend for the Crate Flutter app.

Before working, read `AGENT.md` and the relevant docs in `docs/project/`. Follow ADRs, use Discogs API v2.0 only, do not scrape Discogs, do not commit secrets, and update tests, docs, and changelog when needed.

Read OAuth and API architecture docs before coding.

## Worker Task

```text
[Describe Worker task here]
```

## Hard Rules

- Store Discogs consumer secret only as a Cloudflare Worker secret.
- Do not expose secrets to Flutter.
- Use Discogs API v2.0.
- Handle OAuth 1.0a signing.
- Validate callback state.
- Return simple JSON responses to Flutter.
- Do not log sensitive tokens or secrets.

## Expected Endpoints

- `POST /auth/start`
- `GET /auth/callback`
- `POST /auth/logout`
- `GET /me`
- `GET /collection`
- `GET /releases/:id`
- `GET /search`

## Expected Output

1. Worker route design
2. Secret configuration
3. Request and response examples
4. Error handling
5. Worker code
6. Test plan
7. Deployment notes
