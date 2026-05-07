# Fullstack App Starter

## Use When

- The project spans frontend, backend, data, QA, and release readiness.
- The user wants a project harness that can support implementation as well as verification.
- UI changes and API changes both matter.

## Default Pattern

- Primary: `Producer-Reviewer`
- Secondary: `Pipeline`
- Optional for larger repos: `Supervisor`

## Recommended Roles

- `architect`
- `frontend-dev`
- `backend-dev`
- `qa-engineer`
- `release-engineer`

Keep `qa-engineer` or equivalent as a separate verification owner.

## Recommended Repo Outputs

Always consider generating:

- `docs/harness/overview.md`
- `docs/harness/commands.md`
- `docs/harness/validation.md`
- `docs/plans/active/harness-bootstrap.md`

If the project uses Claude Code, also consider:

- `.claude/CLAUDE.md` updates
- `.claude/agents/architect.md`
- `.claude/agents/frontend-dev.md`
- `.claude/agents/backend-dev.md`
- `.claude/agents/qa-engineer.md`
- `.claude/agents/release-engineer.md`
- `.claude/skills/{project-harness}/skill.md`

Optional when multi-phase artifacts matter:

- `_workspace/00_input.md`
- `_workspace/01_architecture.md`
- `_workspace/02_execution-plan.md`
- `_workspace/03_validation.md`

## Template Skeletons

### `docs/harness/overview.md`

```md
# Harness Overview

## Goal
- Help agents deliver and verify work on this project reliably.

## Primary Pattern
- Producer-Reviewer with pipeline handoffs

## Roles
- Architect: system design and dependency analysis
- Frontend Dev: UI changes and browser-verifiable behavior
- Backend Dev: API, data, integrations
- QA Engineer: regression, smoke, edge cases
- Release Engineer: deploy-readiness, config, rollback, observability

## Verification Surfaces
- lint:
- typecheck:
- unit:
- integration:
- smoke/e2e:
- browser automation:
- logs/metrics/traces:

## Known Gaps
- browser verification unavailable: TODO until Playwright or an equivalent browser smoke script exists
```

### `docs/harness/commands.md`

```md
# Harness Commands

## Core Verification
- Lint: `...`
- Typecheck: `...`
- Unit tests: `...`
- Integration tests: `...`
- Smoke / e2e: `...`
- Browser smoke: `npm run smoke:browser` if Playwright or equivalent exists; otherwise record `browser verification unavailable`

## Release Readiness
- Build: `...`
- Config validation: `...`
- Migration safety: `...`

## Notes
- If a command does not exist yet, track it as a TODO in the harness bootstrap plan.
```

### `docs/plans/active/harness-bootstrap.md`

```md
# Harness Bootstrap Plan

## Scope
- Build a reusable harness for this project.

## Deliverables
- entrypoint updates
- harness docs
- verification contract
- separate reviewer/qa path

## Tasks
- [ ] Audit existing entrypoints, docs, and commands
- [ ] Confirm real verification commands
- [ ] Add or update harness docs
- [ ] Define role ownership
- [ ] Define validation flow
- [ ] Record browser verification as real command or `browser verification unavailable`
- [ ] Record remaining gaps
```

## Validation Checklist

- Can UI work be verified via browser automation or screenshots?
- If browser automation is unavailable, is `browser verification unavailable` recorded in `docs/harness/validation.md` as a known gap?
- Can API changes be checked with repeatable commands?
- Is there a separate QA/reviewer role?
- Are release-readiness and rollback expectations recorded?
- Are missing observability surfaces called out explicitly?
