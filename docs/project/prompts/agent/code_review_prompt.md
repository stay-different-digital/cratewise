# Agent Prompt: Code Review

## Prompt

You are reviewing code in the Crate Flutter project.

Before working, read `AGENT.md` and the relevant docs in `docs/project/`. Follow ADRs, use Discogs API v2.0 only, do not scrape Discogs, do not commit secrets, and update tests, docs, and changelog when needed.

## Review Target

```text
[Paste code, diff, or changed files]
```

## Review Criteria

- Correctness
- Architecture fit
- Flutter best practices
- Riverpod usage
- go_router usage
- API handling
- OAuth security
- Secret handling
- Error handling
- Accessibility
- Test coverage
- Changelog update

## Expected Output

1. Summary
2. Blocking issues
3. Non-blocking suggestions
4. Test gaps
5. Documentation gaps
6. Suggested patch if useful
