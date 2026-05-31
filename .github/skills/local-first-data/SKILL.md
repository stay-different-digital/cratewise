---
name: local-first-data
description: Design and implement local-first collection, wishlist, cached release metadata, offline access, sync status, and conflict handling for Cratewise.
argument-hint: '[data or sync task]'
---

# Local-First Data Skill

Use this skill for offline collection and wishlist features.

## Procedure

1. Define domain models first.
2. Define repository contracts.
3. Add local persistence models.
4. Add mappers between local models and domain models.
5. Add sync status fields.
6. Add offline-friendly queries.
7. Add tests for repository behavior.

## Sync states

Use these states:

- Synced
- Pending
- Failed
- Conflict
- Offline

## Local data should include

- Collection items
- Wishlist items
- Release metadata
- Notes
- Tags
- Media condition
- Sleeve condition
- Purchase price
- Storage location
- Thumbnail cache reference

## Done criteria

- Collection opens offline.
- Wishlist opens offline.
- Local edits are not lost.
- Sync state is visible.
- Tests cover repository behavior.
