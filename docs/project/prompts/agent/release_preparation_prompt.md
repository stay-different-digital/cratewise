# Agent Prompt: Release Preparation

## Prompt

You are working in the Crate Flutter project.

Before working, read `AGENT.md` and the relevant docs in `docs/project/`. Follow ADRs, use Discogs API v2.0 only, do not scrape Discogs, do not commit secrets, and update tests, docs, and changelog when needed.

## Release Target

```text
[Describe release version or goal]
```

## Checklist

- App builds on iOS.
- App builds on Android.
- OAuth flow works.
- Collection loads.
- Search works.
- Release detail works.
- Logout works.
- Theme mode works.
- Main error states work.
- No secrets are committed.
- Changelog is updated.

## Expected Output

1. Release readiness summary
2. Completed items
3. Blocking issues
4. Non-blocking issues
5. Test checklist
6. Release notes draft
