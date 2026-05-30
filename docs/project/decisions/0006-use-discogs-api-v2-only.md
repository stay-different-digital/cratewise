# ADR 0006: Use Discogs API v2.0 Only

## Status

Accepted

## Date

2026-05-30

## Context

The project must use the current Discogs API direction and avoid outdated API assumptions.

## Decision

Use Discogs API v2.0 only. Do not use Discogs API v1.0. Do not scrape Discogs pages.

## Consequences

### Positive

- Keeps the implementation aligned with Discogs developer documentation.
- Prevents outdated API usage.
- Keeps the app safer and more maintainable.

### Negative

- Some old examples found online may not apply.
- The agent must verify endpoint assumptions.

## Alternatives Considered

### Use Discogs API v1.0 examples

Rejected. The project explicitly targets v2.0.

### Scrape Discogs pages

Rejected. Use the official API.

## Follow-up Actions

- Add this rule to AGENT.md.
- Add this rule to PR template.
- Add this rule to API prompts.
