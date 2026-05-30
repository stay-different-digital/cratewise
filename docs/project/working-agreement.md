# Working Agreement

## Purpose

This document defines how work should be done in the Crate project.

It helps the coding agent and the project owner work in small, safe, reviewable steps.

## Core Rules

- Work in small increments.
- Use a branch for every change.
- Create a pull request for every meaningful change.
- Keep one feature, fix, or refactor per pull request.
- Do not work directly on `main`.
- Do not commit secrets.
- Do not use Discogs API v1.0.
- Do not scrape Discogs.
- Use Discogs API v2.0 only.
- Update the changelog after meaningful changes.
- Add or update tests when logic changes.
- Check ADRs before changing architecture.

## Default Workflow

1. Create or select an issue.
2. Create a branch from `main`.
3. Read `AGENT.md`.
4. Read relevant docs and ADRs.
5. Implement the smallest useful change.
6. Add or update tests.
7. Run checks.
8. Update docs if needed.
9. Update the changelog if needed.
10. Open a pull request.
11. Review the pull request.
12. Merge after approval.

## Branch Naming

Use clear branch names:

```text
feature/collection-list
feature/discogs-oauth-login
fix/oauth-callback-error
docs/update-roadmap
refactor/api-error-mapping
test/collection-parser
```

## Pull Request Size

Preferred pull request size:

- 5 to 15 changed files
- 300 to 500 changed lines maximum
- One clear goal

Avoid:

- Large mixed changes
- Feature plus refactor in one PR
- UI plus API plus architecture in one PR
- Changelog-only changes mixed with unrelated code

## Quality Bar

A change is only ready when:

- Code is formatted.
- Static analysis passes.
- Tests pass.
- Main states are handled.
- No secrets are included.
- Documentation is updated when needed.
- Changelog is updated when needed.
