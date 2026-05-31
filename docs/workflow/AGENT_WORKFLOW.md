# Agent Workflow

## Goal

Use VS Code Agent Mode in a controlled way.

## Recommended workflow

### Step 1: Plan

Use `Cratewise Product Planner`.

Ask:

```text
Create a feature plan for Phase 1 technical foundation. Do not edit code.
```

### Step 2: Architecture

Use `Cratewise Flutter Architect`.

Ask:

```text
Create a technical implementation plan for the first feature slice. Do not edit code.
```

### Step 3: Implement

Use `Cratewise Flutter Implementer`.

Ask:

```text
Implement only step 1 from the plan. Keep the change small. Run format and tests.
```

### Step 4: Review

Use `Cratewise QA Reviewer`.

Ask:

```text
Review the current changes against the acceptance criteria and testing requirements.
```

### Step 5: Security review

Use `Cratewise Security Reviewer` for:

- Token storage
- Authentication
- API integration
- Privacy changes

### Step 6: Update docs

Use `/update-docs` after feature changes.

## Good task size

Good task:

- Create the base folder structure.
- Add token storage service interface.
- Add Discogs search DTO mapping.
- Add collection item domain model.

Too large:

- Build the full app.
- Implement all Discogs integration.
- Create all screens and sync.

## Done criteria per task

Each task should end with:

- Files changed
- Tests run
- Known limitations
- Next suggested task
