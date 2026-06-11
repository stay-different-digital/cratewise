---
name: review-code
description: Review Cratewise code changes for quality, tests, and security basics.
agent: Cratewise QA Reviewer
argument-hint: '[changed files or feature]'
---

Review the current changes for: `${input:scope:changed files or feature}`.

Check:

- Acceptance criteria
- Architecture boundaries
- Tests
- Android behavior
- iOS behavior
- iPadOS behavior
- Error states
- Token safety
- Documentation updates

Return findings by severity.
