---
name: secure-token-storage
description: Implement or review secure storage for Discogs tokens on Android and Windows, including masking, removal, and safe logging rules.
argument-hint: '[token storage task]'
---

# Secure Token Storage Skill

Use this skill for token storage and authentication work.

## Procedure

1. Treat the Discogs token as a secret.
2. Store tokens with secure storage.
3. Never store tokens in plain text files.
4. Never commit tokens.
5. Never log tokens.
6. Never show tokens in exceptions.
7. Mask tokens in the UI.
8. Add a remove-token flow.
9. Add tests around token state where practical.

## Required app states

- Not connected
- Token entered
- Token validating
- Token valid
- Token invalid
- Token removed

## Done criteria

- Token is stored securely.
- Token can be removed.
- Token is masked.
- Logs are safe.
- Errors are user-friendly.
