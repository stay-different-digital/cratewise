# Definition of Ready

## Purpose

A task is ready when the coding agent has enough context to start without guessing.

## Ready Checklist

A task is ready when these points are clear:

- [ ] The goal is clear.
- [ ] The user value is clear.
- [ ] The scope is clear.
- [ ] Out of scope is clear.
- [ ] Acceptance criteria are written.
- [ ] Required API behavior is known.
- [ ] Required UI states are known.
- [ ] Related ADRs are identified.
- [ ] Related architecture docs are identified.
- [ ] Test expectations are clear.
- [ ] Documentation expectations are clear.

## Required Context

Every task should include:

```markdown
## Goal

## Scope

## Out of scope

## Acceptance criteria

## Technical notes

## Test notes

## Documentation notes
```

## API Tasks

For Discogs API tasks, the task must confirm:

- Use Discogs API v2.0.
- Do not use Discogs API v1.0.
- Do not scrape Discogs.
- Use the Cloudflare Worker where signed calls or secrets are needed.
- Handle rate limits.
- Handle unauthorized responses.
- Handle network errors.

## UI Tasks

For UI tasks, the task must confirm:

- Loading state
- Empty state
- Error state
- Success state
- Light mode
- Dark mode
- Phone layout
- Tablet layout
- Accessibility basics
