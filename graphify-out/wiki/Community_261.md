# Community 261

> 5 nodes

## Key Concepts

- **Discogs Current Token Mode (paste personal token; validate, store securely, mask, removable). Rationale: simplest MVP auth, avoids embedding OAuth consumer secrets in the Flutter app** (3 connections) — `docs/api/DISCOGS_API.md`
- **Backend Proxy for Production OAuth Secrets. Rationale: production consumer secrets must never ship inside the Flutter client** (2 connections) — `docs/api/DISCOGS_API.md`
- **Token Lifecycle States (not connected / entered / validating / valid / invalid / removed)** (1 connections) — `.github/skills/secure-token-storage/SKILL.md`
- **Token Security Principles (never hardcode/log/show tokens; secure storage only)** (1 connections) — `AGENTS.md`
- **Cloudflare Worker Proxy (for secrets and signed Discogs calls)** (1 connections) — `CONTRIBUTING.md`

## Relationships

- No strong cross-community connections detected

## Source Files

- `.github/skills/secure-token-storage/SKILL.md`
- `AGENTS.md`
- `CONTRIBUTING.md`
- `docs/api/DISCOGS_API.md`

## Audit Trail

- EXTRACTED: 2 (25%)
- INFERRED: 6 (75%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*