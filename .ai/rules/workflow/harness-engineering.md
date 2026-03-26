# Harness Engineering Guide

Repository operating model for agent-first software development.

## Core Principles

### 1. Humans steer, agents execute
- Engineers spend leverage on environment design, intent specification, and feedback loops.
- If a task is repeatedly fragile, improve the system around the task instead of retrying prompts indefinitely.

### 2. The repository is the system of record
- Durable engineering knowledge must live in versioned repo files.
- Keep `AGENTS.md` / `CLAUDE.md` short and map-oriented.
- Store detailed guidance in focused docs under `docs/` or `.ai/rules/`.
- Prefer many small, maintained docs over one giant instruction blob.

### 3. Agent readability is a product requirement
- Apps should be runnable and inspectable per change.
- Expose verification surfaces agents can read directly:
  - UI states via screenshots, DOM snapshots, or browser automation
  - logs via structured queries
  - metrics and traces via queryable local or staging tooling
  - deterministic test fixtures and seed data
- If humans must manually interpret a workflow every time, the harness is incomplete.

### 4. Autonomy grows in levels
- Level 0: guided execution with narrow steps and approvals
- Level 1: bounded implementation with targeted verification
- Level 2: multi-step autonomous runs with repo scripts, tests, and review loops
- Level 3: long-running background agents with cleanup, retry limits, and rollback rules
- Advance only when the previous level is reliable on real work.

### 5. Throughput changes merge philosophy
- Prefer small, reviewable PRs and cheap follow-up fixes.
- Optimize for rapid validation and frequent mergeability, not large perfect batches.
- Use agent review plus automated checks to keep human attention on higher-leverage decisions.

### 6. Entropy is inevitable; cleanup must be explicit
- Agents copy existing patterns, including bad ones.
- Encode golden paths in shared utilities, typed boundaries, templates, and docs.
- Run recurring cleanup for drift, duplicated patterns, dead abstractions, and low-signal docs.

## Recommended Repo Shape

```text
AGENTS.md / CLAUDE.md       # Short map, not encyclopedia (project-specific only)
.ai/
  core.md                   # Global AI orchestrator rules
  entry-points/             # Managed tool configs (auto-updated by setup script)
    claude.md
    copilot.md
    codex.md
  config/quality.yaml       # Quality gate thresholds
  rules/                    # Modular rule files (loaded on demand)
  skills/                   # Custom skills
docs/
  index.md                  # Table of contents
  architecture/
  plans/active/
  plans/completed/
  product/
  references/
  reliability/
  security/
  generated/
```

### 7. Constrain the solution space mechanically
- Enforce architectural boundaries with structural tests, deterministic linters, and CI rules.
- Dependency direction: `Types → Config → Repository → Service → Runtime → UI`. See `.ai/rules/architecture/architecture-guide.md`.
- Constraining agents makes them more productive — they converge faster on correct solutions.
- Design harnesses to be **rippable**: remove constraints when models improve enough to not need them.

### 8. Detect and break doom loops
- Track repeated edits to the same file and repeated test failures.
- 3+ retries on the same error = stop and reassess, not retry harder.
- Automate via `PostToolUse` hook counters. See `.ai/rules/integration/hooks-guide.md`.

### 9. Self-verify before completion
- Agents must run quality gates (lint, typecheck, tests) before reporting done.
- Automate via `Stop` hook that blocks completion on failure.
- Human review focuses on design and intent, not catching lint errors.

## Model Capability Matrix

Harness constraints should evolve as models improve. Design constraints to be **rippable** — remove them when the model no longer needs them.

### Context Management by Model Capability

| Model Trait | Harness Strategy | When to Rip |
|---|---|---|
| Context anxiety (quality degrades with long context) | Context resets between sessions with handoff artifacts | Model maintains quality across full context window |
| Weak decomposition (tries to do everything at once) | Sprint/feature-list structure with one-feature-at-a-time rule | Model naturally decomposes and sequences work |
| Self-evaluation bias (praises own mediocre work) | Separate Evaluator agent with explicit grading criteria | Model produces calibrated self-assessments |
| Loses track in large codebases | Frequent pwd checks, explicit file maps, short entrypoints | Model reliably navigates large repos |
| Premature completion (declares done too early) | Stop hook with quality gate enforcement | Model self-verifies reliably before completion |

### Tuning Checklist

When adopting a new model version:
1. Test whether context resets are still needed (run long session, check quality at end)
2. Test whether work decomposition (sprints/feature lists) is still needed
3. Test self-evaluation accuracy (compare agent self-grade vs independent Evaluator)
4. Adjust autonomy level based on observed reliability
5. Document model-specific harness overrides in project `CLAUDE.md` or `AGENTS.md`

### Practical Examples

```text
Sonnet 4.5:  Context resets required, sprint decomposition required, separate evaluator required
Opus 4.5:    Context resets removable (compaction sufficient), sprint decomposition helpful
Opus 4.6:    Context resets removable, sprint decomposition removable, planner+evaluator still valuable
```

> Continuously re-evaluate. The right harness for today's model may be over-constrained for tomorrow's.

## Execution Heuristics

### When to improve the harness
- The same prompt pattern fails twice
- Agents cannot reliably verify UI or runtime behavior
- People repeatedly answer the same repo questions
- PR review is blocked on missing logs, metrics, or scripts
- Drift keeps reappearing across generated code
- An agent enters a doom loop (3+ retries without progress)

### What to add first
1. Short repo docs with explicit pointers
2. Reusable scripts for build, test, seed, verify, and review
3. Structural tests and linter rules enforcing dependency direction
4. Queryable logs/metrics/traces or lightweight local observability
5. Deterministic fixtures, smoke tests, and browser automation
6. Loop detection and pre-completion self-check hooks
7. Cleanup jobs or recurring agent tasks for drift reduction

## Checklist
- [ ] Is durable knowledge recorded in repo files instead of chat history?
- [ ] Are entrypoint files short and map-like?
- [ ] Can agents verify the changed behavior directly?
- [ ] Is autonomy level appropriate to current reliability?
- [ ] Does the repo contain golden paths that reduce drift?
- [ ] Is there a cleanup loop for entropy and AI slop?
- [ ] Are architectural constraints enforced mechanically (structural tests, linters)?
- [ ] Is loop detection in place to break doom loops?
- [ ] Do agents self-verify (lint, typecheck, test) before reporting completion?
- [ ] Is the harness rippable — can constraints be removed as models improve?
