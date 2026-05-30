# Updated Files Manifest

## Purpose

This manifest lists all files included in the complete Crate project documentation package.

It also explains what was updated in this pass.

## Summary

This package includes:

- Root project files
- Agent instructions
- Project prompts
- Roadmap
- Feature backlog
- Changelog
- OAuth architecture
- API architecture
- ADRs
- Agent prompts
- GitHub templates
- Flutter CI workflow
- Process documentation
- Security documentation
- Environment setup

## Updated in this pass

These files were reviewed and updated for consistency:

- `README.md`
- `AGENT.md`
- `.env.example`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/technical_task.md`
- `.github/workflows/flutter-ci.yml`
- `docs/project/prompts/crate_project_prompt.md`
- `docs/project/prompts/flutter_folder_setup_prompt.md`
- `docs/project/roadmap/roadmap.md`
- `docs/project/backlog/feature_backlog.md`
- `docs/project/changelog/changelog.md`
- `docs/project/architecture/oauth_architecture.md`
- `docs/project/architecture/api_architecture.md`
- `docs/project/working-agreement.md`
- `docs/project/definition-of-ready.md`
- `docs/project/definition-of-done.md`
- `docs/project/branching-strategy.md`
- `docs/project/testing-strategy.md`
- `docs/project/release-checklist.md`
- `docs/project/environment-setup.md`
- `docs/project/decisions/0001-use-cloudflare-worker-for-discogs-oauth.md`
- `docs/project/decisions/0002-use-airbnb-inspired-figma-design-direction.md`
- `docs/project/decisions/0003-use-flutter-feature-based-clean-architecture.md`
- `docs/project/decisions/0004-use-riverpod-for-state-management.md`
- `docs/project/decisions/0005-use-go-router-for-navigation.md`
- `docs/project/decisions/0006-use-discogs-api-v2-only.md`
- `docs/project/decisions/0007-use-real-discogs-api-calls-from-start.md`
- `docs/project/decisions/0008-no-offline-collection-cache-in-mvp.md`
- `docs/project/decisions/0009-support-light-dark-and-system-theme.md`
- `docs/project/decisions/0010-use-cloudflare-worker-as-bff-for-discogs-api.md`
- `docs/project/decisions/0011-use-mobile-scanner-for-barcode-scanning.md`
- `docs/project/decisions/0012-maintain-project-changelog.md`
- All files in `docs/project/prompts/agent/`

## Main consistency changes

- Discogs API usage is now consistently described as Discogs API v2.0 only.
- Discogs API v1.0 is explicitly blocked everywhere relevant.
- Scraping Discogs is explicitly blocked everywhere relevant.
- Cloudflare Worker is consistently used for OAuth signing and secret handling.
- The MVP focus is consistently collection management first.
- Offline collection cache is consistently out of scope for MVP.
- Light, dark, and system theme mode are consistently in scope.
- PR workflow is now part of the project guidance.
- Changelog updates are now part of the Definition of Done.
- GitHub issue and PR templates now match project rules.
- Agent prompts now reference `AGENT.md` and the documentation structure.

## Files carried forward without major content change

Some earlier concepts were kept because they were still valid:

- Feature-based clean architecture
- Riverpod
- go_router
- mobile_scanner
- Airbnb-inspired Figma direction
- ADR-based decision records
- Small PR workflow
- Testing strategy with unit, widget, integration, and manual tests

## Recommended unzip command

From the root of your repo:

```bash
unzip crate_complete_project_files.zip -d .
```

Review changed files before committing:

```bash
git status
git diff
```
