---
name: prepare-pr
description: Prepare a pull request summary for Cratewise changes.
agent: Cratewise QA Reviewer
argument-hint: '[feature or branch]'
---

Prepare a pull request summary for: `${input:scope:feature or branch}`.

Return:

- Title
- Summary
- What changed
- Tests run
- Manual QA
- Risks
- Screenshots needed
- Follow-up tasks
