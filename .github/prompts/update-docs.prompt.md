---
name: update-docs
description: Update Cratewise docs after product, architecture, API, or workflow changes.
agent: Cratewise Product Planner
argument-hint: '[change summary]'
---

Update the docs for this change: `${input:changeSummary:change summary}`.

Check these docs:

- [Project brief](../../docs/product/PROJECT_BRIEF.md)
- [Roadmap](../../docs/product/ROADMAP.md)
- [Architecture](../../docs/architecture/ARCHITECTURE.md)
- [Discogs API notes](../../docs/api/DISCOGS_API.md)
- [Security](../../docs/security/SECURITY.md)
- [Design system](../../docs/design/DESIGN_SYSTEM.md)

Return:

- Files that need updates
- Suggested edits
- Any conflicting information
