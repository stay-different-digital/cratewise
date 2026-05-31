# Cratewise VS Code Agent Mode Setup

This setup prepares the Cratewise Flutter project for VS Code Agent Mode.

Cratewise is a Flutter app for Android and and iOS/iPadOS. It helps vinyl collectors and DJs manage their record collection with Discogs data.

## What this setup contains

- `.github/copilot-instructions.md`
  - Always-on project rules for Copilot Chat.

- `.github/agents/`
  - Custom agents for planning, architecture, implementation, QA, security, and design.

- `.github/skills/`
  - Reusable Agent Skills for Flutter features, Discogs API work, local-first data, UI design, testing, and release checks.

- `.github/prompts/`
  - Slash-command prompt files for common workflows.

- `.vscode/`
  - Recommended VS Code extensions, tasks, launch configs, and workspace settings.

- `docs/`
  - Product, architecture, design, API, security, and workflow documentation.

## Recommended VS Code extensions

Install these extensions:

- GitHub Copilot
- GitHub Copilot Chat
- Flutter
- Dart

VS Code will recommend them from `.vscode/extensions.json`.

## How to use this setup

### 1. Add these files to the root of your Flutter repo

Copy all folders from this package into your project root.

Your repo should look like this:

```text
cratewise/
  .github/
    agents/
    prompts/
    skills/
    copilot-instructions.md
  .vscode/
  docs/
  AGENTS.md
  README.md
```

### 2. Open the project in VS Code

Open the root folder in VS Code.

Then run:

```bash
flutter doctor
flutter pub get
```

### 3. Check the Copilot customizations

In VS Code:

- Open the Command Palette
- Run `Chat: Open Customizations`
- Check these tabs:
  - Agents
  - Skills
  - Prompts

### 4. Use the custom agents

Use the agent dropdown in Copilot Chat.

Recommended flow:

1. `Cratewise Product Planner`
2. `Cratewise Flutter Architect`
3. `Cratewise Flutter Implementer`
4. `Cratewise QA Reviewer`
5. `Cratewise Security Reviewer`

### 5. Use prompt files as slash commands

In Copilot Chat, type `/` and look for prompts like:

- `/start-project`
- `/plan-feature`
- `/implement-feature`
- `/review-code`
- `/prepare-pr`
- `/update-docs`

### 6. Use skills for repeatable workflows

Skills can load automatically when relevant.

You can also invoke them from the slash menu when VS Code shows them.

Use skills for:

- Flutter feature implementation
- Discogs API work
- Secure token storage
- Local-first sync
- Testing
- UI implementation
- Release checks

## Best workflow for vibe coding

Use small steps.

Recommended prompt:

```text
Use the Cratewise Product Planner agent. Read AGENTS.md and docs/product/ROADMAP.md. Create an implementation plan for Phase 1 only. Do not edit code yet.
```

Then:

```text
Switch to the Cratewise Flutter Implementer agent. Implement only the first step from the plan. Keep changes small. Run formatting and tests.
```

Then:

```text
Switch to the Cratewise QA Reviewer agent. Review the changes. Check if the implementation matches the acceptance criteria.
```

## Project rules

- Keep the app Flutter-first.
- Support Android and iOS/iPadOS.
- Use Discogs API as metadata source.
- Start with Discogs current token mode.
- Do not hardcode tokens or secrets.
- Keep architecture clean and testable.
- Keep the UI inspired by the Airbnb Figma references, but do not copy Airbnb branding.
- Keep implementation small per task.
- Update docs when behavior changes.

## Safe first task for Agent Mode

Start with this task:

```text
Use the Cratewise Flutter Architect agent. Read AGENTS.md, docs/product/PROJECT_BRIEF.md, docs/product/ROADMAP.md, and docs/architecture/ARCHITECTURE.md. Create a Phase 1 implementation plan for the Flutter project setup. Do not edit files yet.
```
