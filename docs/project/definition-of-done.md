# Definition of Done

## Purpose

A task is done when it is complete, tested, documented, and safe to merge.

## Done Checklist

A task is done when:

- [ ] The implementation matches the task.
- [ ] The scope did not grow without approval.
- [ ] Code is formatted.
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] Important logic has tests.
- [ ] Main UI states are handled.
- [ ] User-facing errors are clear.
- [ ] No secrets are committed.
- [ ] Discogs API v2.0 is used where needed.
- [ ] Discogs API v1.0 is not used.
- [ ] No scraping was added.
- [ ] Relevant docs are updated.
- [ ] Changelog is updated when needed.
- [ ] ADR is added or updated when a major decision changes.
- [ ] PR description is complete.

## Required UI States

Every main screen must include:

- Loading state
- Empty state
- Error state
- Success state

## Required Accessibility Basics

UI changes must include:

- Semantic labels where needed
- Scalable text support
- Large tap targets
- Good contrast
- Logical navigation order

## Required Tests

Use the right level of tests:

- Unit tests for business logic
- Unit tests for error mapping
- Unit tests for parsers and models
- Widget tests for key UI states
- Integration tests for critical flows

## Changelog

Update:

```text
docs/project/changelog/changelog.md
```
