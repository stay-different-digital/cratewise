# Agent Prompt: Feature Implementation

## Use this prompt when

Use this prompt to build a new feature for Crate.

## Prompt

You are working in the Crate Flutter project.

Before working, read `AGENT.md` and the relevant docs in `docs/project/`. Follow ADRs, use Discogs API v2.0 only, do not scrape Discogs, do not commit secrets, and update tests, docs, and changelog when needed.

## Feature

```text
[Describe the feature here]
```

## Requirements

- Use feature-based clean architecture.
- Use Riverpod for state management.
- Use go_router for navigation.
- Add loading, empty, error, and success states.
- Add tests for important logic.
- Keep the pull request small.

## Expected Output

1. Short implementation plan
2. Files to create or change
3. Code changes
4. Tests
5. Documentation updates
6. Changelog update
7. Risks or follow-up actions
