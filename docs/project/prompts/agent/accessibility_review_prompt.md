# Agent Prompt: Accessibility Review

## Prompt

You are reviewing accessibility in the Crate Flutter project.

Before working, read `AGENT.md` and the relevant docs in `docs/project/`. Follow ADRs, use Discogs API v2.0 only, do not scrape Discogs, do not commit secrets, and update tests, docs, and changelog when needed.

## Review Target

```text
[Describe screen or flow]
```

## Check

- Semantic labels
- Screen reader support
- Scalable text
- Good contrast
- Large tap targets
- Logical navigation order
- Clear focus states
- Non-color-only status indicators

## Expected Output

1. Accessibility summary
2. Blocking issues
3. Suggested fixes
4. Code examples where useful
5. Test suggestions
