# Agent Prompt: Discogs API Integration

## Prompt

You are working in the Crate Flutter project.

Before working, read `AGENT.md` and the relevant docs in `docs/project/`. Follow ADRs, use Discogs API v2.0 only, do not scrape Discogs, do not commit secrets, and update tests, docs, and changelog when needed.

Read `docs/project/architecture/api_architecture.md` and ADRs 0006, 0007, and 0010.

## API Work

```text
[Describe the API change here]
```

## Hard Rules

- Use Discogs API v2.0 only.
- Do not use Discogs API v1.0.
- Do not scrape Discogs.
- Use real API calls from the start.
- Add a clear User-Agent.
- Respect rate limits.
- Do not expose secrets in Flutter.
- Use Cloudflare Worker for signed calls where needed.

## Expected Output

1. Endpoint overview
2. Data model changes
3. Repository changes
4. Error mapping
5. Tests
6. Changelog update
