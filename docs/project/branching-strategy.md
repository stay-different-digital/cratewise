# Branching Strategy

## Purpose

This document defines how branches are used in the Crate project.

The goal is to keep vibe coding safe, reviewable, and easy to roll back.

## Main Branch

### `main`

Stable branch.

Rules:

- Always keep it working.
- Do not commit directly.
- Merge only through pull requests.
- CI must pass before merge.

## Working Branches

Use one branch per task.

Branch name format:

```text
type/short-description
```

Types:

- `feature`
- `fix`
- `docs`
- `refactor`
- `test`
- `chore`

Examples:

```text
feature/discogs-oauth-login
feature/collection-list
feature/release-detail-screen
fix/oauth-callback-error
docs/add-api-architecture
refactor/error-mapping
test/collection-parser
chore/update-dependencies
```

## Pull Request Rules

Every branch should become a pull request.

A pull request should:

- Have one clear goal.
- Stay small.
- Include tests when needed.
- Update docs when needed.
- Update changelog when needed.

## Merge Rules

Before merge:

- CI passes.
- PR template is complete.
- No secrets are committed.
- Changelog is updated when needed.
- ADR is updated when needed.
- The change is reviewed.
