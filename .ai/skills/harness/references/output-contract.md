# Harness Output Contract

When building a project harness, the result should leave behind reusable repo artifacts.

## Required Deliverables

### 1. Entry point updates
- Keep `AGENTS.md`, `CLAUDE.md`, or equivalent short.
- Add only high-signal routing pointers:
  - where durable harness docs live
  - which verification commands matter
  - which tool-specific harness package is active

### 2. Durable docs
- Create or update:
  - `docs/index.md`
  - `docs/plans/active/harness-bootstrap.md` or equivalent
  - `docs/harness/overview.md` when the project needs a dedicated harness area
- Record:
  - chosen orchestration pattern
  - agent or role layout
  - verification surfaces
  - hook / automation choices
  - known gaps

### 3. Verification contract
- Capture real commands for:
  - lint
  - typecheck
  - unit/integration/smoke/e2e
  - build or deploy-readiness checks
- If commands are missing, write TODOs and recommended additions instead of guessing.

### 4. Review separation
- Define who builds and who verifies.
- For agent-enabled projects, this usually means explicit builder and verifier/evaluator definitions.
- For tool-limited projects, document the separation in workflow docs and task templates.

### 5. Drift control
- Add one of:
  - recurring cleanup checklist
  - doc-gardening task
  - quality review reminder in `docs/plans/`
- The harness should explain how bad patterns are detected and cleaned up over time.

## Claude Code Specific Outputs

When `CLAUDE.md` or `.claude/` is part of the project, prefer generating:
- `.claude/agents/{agent}.md`
- `.claude/skills/{skill}/SKILL.md`
- `.claude/skills/{skill}/references/*`
- `.claude/settings.json` hook recommendations or concrete config

Use these only when they match the project's actual toolchain and permission model.

## Validation Checklist
- Can a new session discover the harness from entrypoint files?
- Can the agent find durable docs without chat history?
- Can the agent run or at least locate verification commands?
- Is there a separate verification path?
- Is there a clear next step for missing observability, fixtures, or browser automation?
