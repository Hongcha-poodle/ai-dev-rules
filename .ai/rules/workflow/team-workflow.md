# Team Workflow

Multi-agent collaboration using Claude Code harness: Agent tool, worktree isolation, background execution.

## Team Roles

| Role | Agent Role | subagent_type | Responsibility |
|---|---|---|---|
| Architect | Plan | `"Plan"` | Design and structure |
| Developer | Execute | `"general-purpose"` | Code implementation |
| Reviewer | Explore | `"Explore"` | Code review, quality |
| Verifier | Verify | `"Explore"` or `"general-purpose"` | Regression, smoke, release checks |
| Release / SRE | Release | `"general-purpose"` + DevOps context | Deployment, rollback, observability |
| Harness / Enablement | Execute or Specialist | `"general-purpose"` + tooling/docs prompt | Docs, scripts, fixtures, observability, developer leverage |
| Researcher | Search | `"general-purpose"` + web | External docs/API research |
| AppSec / QA | Specialist | `"general-purpose"` + domain prompt | Security and test-depth review |

## Parallel Execution

### Three mechanisms

**1. Simultaneous Agent calls**
Launch multiple Agent tools in a single message:
```
Explore agent (code search) + Search agent (doc research) → one message, two calls
Developer agent + Verify agent → implement while regression planning runs in parallel
```

**2. Background execution** (`run_in_background: true`)
Non-blocking tasks that notify on completion:
```
Long test suite → background, continue other work → auto-notified when done
Release-readiness checklist → background while implementation finishes
```

**3. Worktree isolation** (`isolation: "worktree"`)
Prevents file conflicts in parallel write operations:
```
Agent A: frontend refactor (worktree) | Agent B: backend refactor (worktree) → merge after
```

### Decision tree

```
Q1. File dependency between tasks?
├─ Yes → Serialize
└─ No
   Q2. Both tasks write files?
   ├─ Yes → Worktree isolation
   └─ No → Standard parallel execution
```

## Synchronization
- Merge worktree changes at phase boundaries
- Resolve conflicts before proceeding
- Use `TodoWrite` for progress tracking across agents

## Execution Example: New Feature (High Complexity)

```
Phase 1: Parallel research
├─ [Explore agent] Existing code patterns (run_in_background)
└─ [Search agent]  External API docs (run_in_background)

Phase 2: Design
└─ [Plan agent] Architecture based on Phase 1 results

Phase 3: Parallel implementation
├─ [Execute agent A] Frontend components (isolation: "worktree")
└─ [Execute agent B] Backend API (isolation: "worktree")

Phase 4: Verification
├─ [Verify agent] Smoke/integration/regression checks
└─ [AppSec / QA specialist] Risk review for auth, data, API, or migration changes

Phase 5: Release readiness
├─ [Release agent] Rollout, rollback, config, migration, observability review
└─ [Harness / Enablement agent] Capture docs/scripts improvements for future runs
```

## Checklist
- [ ] Task dependencies analyzed?
- [ ] Worktree isolation applied for parallel writes?
- [ ] Background execution used for non-blocking tasks?
- [ ] `TodoWrite` tracking overall progress?
- [ ] Results integrated at sync points?
- [ ] Verification and release ownership assigned?
- [ ] Harness ownership assigned when repeated friction appears?
