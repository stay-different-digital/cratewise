# Agent Prompt: Pull Request Workflow

## Prompt

You are working in the Crate Flutter project.

Before working, read `AGENT.md` and the relevant docs in `docs/project/`. Follow ADRs, use Discogs API v2.0 only, do not scrape Discogs, do not commit secrets, and update tests, docs, and changelog when needed.

## Task

```text
[Describe the task here]
```

## Required Workflow

1. Confirm the task goal.
2. Identify relevant docs and ADRs.
3. Create a small implementation plan.
4. Create a branch with the correct naming convention.
5. Make the smallest useful code change.
6. Add or update tests.
7. Run formatting, analysis, and tests.
8. Update documentation when needed.
9. Update the changelog when needed.
10. Prepare a pull request summary.

## Required Checks

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Pull Request Output

```markdown
## Summary

- 

## Files changed

- 

## Tests

- 

## Documentation

- 

## Changelog

- 

## Risks

- 

## Follow-up

- 
```
