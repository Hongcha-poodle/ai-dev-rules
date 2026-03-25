# SPEC Workflow

Specification-driven development workflow aligned with Claude Code harness tools.

## Phases

### 1. Plan — Analysis & Specification

**Goal**: Sufficient analysis and user alignment before implementation.

**Steps**:
- Assess complexity (Low/Medium/High per `core.md` §1)
- Identify constraints and scope
- Identify affected runtime paths, deployment surface, and rollback sensitivity
- Identify missing harness support: docs, scripts, fixtures, observability, or UI automation
- Get user approval (Approach-First rule)

**Harness tools**:
- `[Explore agent]` → Scan existing codebase patterns
- `[Plan agent]` → Design implementation strategy, file list, dependency analysis
- `[TodoWrite]` → Break work into trackable items

**Output**: File change list, `TodoWrite` items, impacted runtime/deploy surface, harness gaps, user approval.

### 2. Run — Implementation & Verification

**Goal**: Code to spec, pass all quality gates.

**Steps**:
- Implement per `TodoWrite` task list (sequential or parallel)
- Update task status immediately on completion
- Continuous LSP quality gate checks
- **Loop Detection**: If the same file is edited 3+ times for the same error, or a test fails 3+ attempts, stop implementation and reassess approach. Treat as harness signal.
- Run verification proportional to risk: unit, integration, contract, smoke, or e2e
- Capture deploy-readiness notes for migrations, config, secrets, and rollback
- When repeated friction exists, add harness improvements in the same run or as an explicitly linked follow-up task

**Harness tools**:
- `[Edit/Write]` → Code changes
- `[Bash]` → Test execution, build verification
- `[Agent worktree]` → Parallel implementation in isolated environments
- `[Verify agent]` → Regression, smoke, and release-readiness review
- `[Hooks]` → Auto lint/typecheck via `PostToolUse` hooks

**Quality gates** (`.ai/config/quality.yaml`):
- [ ] LSP errors: 0
- [ ] Type errors: 0
- [ ] Lint errors: 0
- [ ] Impacted-path tests pass (unit/integration/contract as needed)
- [ ] Critical flows have smoke or e2e coverage
- [ ] Deploy readiness checked for config, migration, and secrets impact
- [ ] Repo docs or scripts updated when the task introduces durable new knowledge
- [ ] Agents can read the relevant verification surface directly
- [ ] Tests pass (coverage ≥ 80%)

### 3. Sync — Review & Integration

**Goal**: Code review, release readiness, doc updates, final verification, and harness learning capture.

**Checklists**:
- `.ai/rules/architecture/architecture-guide.md`
- `.ai/rules/security/security-guide.md`
- `.ai/rules/testing/testing-guide.md`

**Harness tools**:
- `[Explore agent]` → Full code review
- `[Bash]` → Final test suite
- `[Release agent]` → Deployment, rollback, and observability review
- `[Stop hook]` → Auto quality summary via `Stop` hook

**Output**: Issue list, edge cases, recommended tests, deploy/rollback notes, harness follow-ups, change summary.

### Pre-Completion Self-Check

Before transitioning Run → Sync, the agent MUST execute quality gates and verify results:

1. Run lint, typecheck, and tests
2. Confirm all pass (zero errors)
3. If any fail → fix before proceeding, do NOT mark Run as complete
4. Automated via `Stop` hook (blocks completion on failure). See `.ai/rules/integration/hooks-guide.md`.

## Phase Transitions

```
Plan → Run:  User approves approach + `TodoWrite` task list ready
Run → Sync:  Pre-Completion Self-Check passes + all quality gates pass + all `TodoWrite` items done + release-readiness notes drafted
Sync → Done: Checklists pass + rollout/rollback expectations are clear + repo knowledge is updated + user confirms
```

## Bug Fix Shortcut

```
1. [Plan]  Identify reproduction steps, analyze root cause
2. [Run]   Write failing test → fix → verify impacted-path tests pass
3. [Sync]  Check side effects, smoke critical path, note rollback/monitoring if user-facing
```

[HARD] Reproduction-First: Always write the failing test first.

## Checklist
- [ ] Requirements clearly defined?
- [ ] User approved the approach?
- [ ] `TodoWrite` has decomposed tasks?
- [ ] Pre-Completion Self-Check executed and passed?
- [ ] All quality gates passed?
- [ ] Architecture/security/testing checklists executed?
- [ ] Deploy-readiness and rollback expectations documented?
- [ ] Durable repo knowledge and harness improvements captured?
- [ ] Entry-point managed config (`.ai/entry-points/`) consistent with workflow changes?
- [ ] Potential issues and edge cases reported?
