---
name: release-checklist
description: Prepare Android, iOS and iPadOS release checks for Cratewise, including build checks, privacy text, branding, QA, and documentation.
argument-hint: '[release version]'
---

# Release Checklist Skill

Use this skill before beta or production releases.

## Release checks

Check:

- Android build
- iOS build
- iPadOS build
- App name
- App icon
- Splash screen
- Privacy text
- Token storage explanation
- Discogs API wording
- Independent branding
- Error states
- Empty states
- Light mode
- Dark mode
- Offline mode
- CSV export

## Security checks

Check:

- No hardcoded tokens
- No hardcoded API secrets
- No token logs
- No token in crash reports
- Remove-token flow works

## Done criteria

- App builds.
- Core flows work.
- Docs are current.
- Privacy text is clear.
- No branding issue is present.
