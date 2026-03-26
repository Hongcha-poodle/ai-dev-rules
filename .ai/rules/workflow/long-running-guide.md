# Long-Running Agent Guide

Multi-session agent execution across context window boundaries.

## Core Problem

Complex projects cannot be completed within a single context window. Each new session starts with no memory of previous work. Without structured handoff, agents try to implement everything at once, run out of context mid-feature, or declare the job done prematurely.

## Two-Agent Pattern

### Initializer Agent

Runs once at project start. Creates the infrastructure every subsequent session relies on.

**Outputs**:
- `feature_list.json` — Granular feature/task list with status tracking
- `claude-progress.txt` — Session-by-session progress notes
- `init.sh` — Environment setup script (cold start within minutes)
- Initial git commit documenting all created files

**Prompt structure**: "Set up the environment, generate the feature list, create progress tracking, commit everything."

### Coding Agent

Runs in every subsequent session. Makes incremental progress, one feature at a time.

**Session startup protocol** (same four steps, every session):
1. Run `pwd` — Confirm working directory
2. Read `claude-progress.txt` + `git log` — Handoff notes + authoritative change record
3. Read `feature_list.json` — Identify highest-priority unfinished feature
4. Pick one feature, implement, test, commit, update progress

**Prompt structure**: "Read progress, pick the next feature, implement it, test it, commit, update progress."

## Three-Agent Evolution (GAN-Inspired)

For higher quality output, separate planning and evaluation from generation:

| Agent | Role | Purpose |
|---|---|---|
| Planner | Decompose | Break work into tractable chunks, define acceptance criteria |
| Generator | Implement | Code one feature at a time, commit, update progress |
| Evaluator | Grade | Independent quality assessment with explicit criteria |

The Evaluator MUST be a separate agent from the Generator. See Self-Evaluation Separation in `core.md`.

## Context Reset vs Compaction

| Strategy | Mechanism | Best for |
|---|---|---|
| Context reset | Kill session, start fresh with handoff artifacts | Models with context anxiety (e.g. Sonnet), long builds |
| Compaction | Summarize earlier conversation in-place, keep going | Models with strong long-context (e.g. Opus), shorter builds |

**Decision guide**:
- Agent quality degrades after many turns → use context reset
- Agent stays coherent across the full session → use compaction
- Handoff artifacts are well-structured → context reset is safe
- Task requires continuous state awareness → prefer compaction

## Handoff Artifacts

### feature_list.json

```json
{
  "features": [
    {
      "id": "auth-login",
      "description": "User login with email/password",
      "priority": 1,
      "status": "passing",
      "session_completed": "session-003"
    },
    {
      "id": "auth-signup",
      "description": "User registration with validation",
      "priority": 2,
      "status": "failing",
      "session_completed": null
    }
  ]
}
```

**Rules**:
- Granular features (one per implementable unit, not epics)
- Status: `"failing"` (not started or broken), `"passing"` (implemented and tested)
- Priority ordering determines work sequence
- Initializer generates all features upfront; Coding Agent only implements

### claude-progress.txt

```text
=== Session 005 (2026-03-26) ===
Completed: auth-signup (user registration with email validation)
Approach: Added signup endpoint, bcrypt hashing, email format validation
Tests: 12 new tests, all passing
Issues: Rate limiting not yet implemented (deferred to auth-rate-limit feature)
Next: auth-password-reset (priority 3)

=== Session 004 (2026-03-25) ===
Completed: auth-login (email/password login)
...
```

**Rules**:
- Append-only (newest session on top)
- Include: what was done, approach taken, tests added, issues found, suggested next
- Git log is the authoritative record; progress file is the readable summary
- Keep concise — this file is read at cold start every session

### init.sh

```bash
#!/bin/bash
# Environment setup — must cold-start within minutes
set -euo pipefail

# Install dependencies
npm install  # or pip install -r requirements.txt, etc.

# Set up database / seed data
npm run db:setup 2>/dev/null || true

# Start dev server (background)
npm run dev &

echo "Environment ready."
```

**Rules**:
- Idempotent — safe to run multiple times
- Fast — target cold start under 3 minutes
- Self-contained — no manual steps required

## Session Lifecycle

```
┌─────────────────────────────────────────────┐
│ Session Start                               │
│  1. Run init.sh (environment ready)         │
│  2. Read claude-progress.txt + git log      │
│  3. Read feature_list.json                  │
│  4. Pick highest-priority failing feature   │
├─────────────────────────────────────────────┤
│ Session Work                                │
│  5. Implement the feature                   │
│  6. Write/run tests                         │
│  7. Run quality gates (lint, typecheck)     │
│  8. Git commit with descriptive message     │
├─────────────────────────────────────────────┤
│ Session End                                 │
│  9. Update feature_list.json (status)       │
│ 10. Append to claude-progress.txt           │
│ 11. Final git commit (progress update)      │
│ 12. Context reset or compaction decision    │
└─────────────────────────────────────────────┘
```

## Integration with SPEC Workflow

Long-running execution wraps the existing Plan → Run → Sync phases:

```
Initializer Session:
  Plan → Generate feature list, define architecture, create init.sh

Coding Sessions (repeat):
  Plan → Read progress, pick next feature
  Run  → Implement, test, commit
  Sync → Update progress, evaluate quality

Final Session:
  Sync → Full integration test, release readiness review
```

## Autonomy Level Mapping

| Autonomy Level | Long-Running Behavior |
|---|---|
| Level 0 | Human approves each feature before implementation |
| Level 1 | Agent picks features autonomously, human reviews each commit |
| Level 2 | Agent runs multiple features per session, human reviews at session boundary |
| Level 3 | Agent runs unattended across sessions with progress tracking and self-evaluation |

## Anti-Patterns

- **Big-bang implementation**: Trying to build everything in one session instead of feature-by-feature
- **No progress artifacts**: Relying on context/memory instead of persistent files
- **Self-evaluation**: Same agent grades its own work (see Self-Evaluation Separation)
- **Manual cold start**: Environment requires human steps to set up
- **Monolithic feature list**: Features too large to implement in one session
- **Missing git commits**: Not committing after each feature (breaks handoff)
- **Progress file as source of truth**: Git log is authoritative; progress file is summary only

## Checklist

- [ ] Initializer agent creates all handoff artifacts?
- [ ] feature_list.json has granular, one-session-sized features?
- [ ] init.sh achieves cold start within minutes?
- [ ] Session startup protocol followed (pwd → progress → features → pick)?
- [ ] Each completed feature has tests and a git commit?
- [ ] claude-progress.txt updated at session end?
- [ ] Evaluator agent is separate from generator agent?
- [ ] Context reset vs compaction decision documented?
- [ ] Autonomy level appropriate for current reliability?
