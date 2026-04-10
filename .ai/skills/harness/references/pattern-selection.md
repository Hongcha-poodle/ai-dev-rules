# Harness Pattern Selection

Use this guide after auditing the project and before generating harness files.

## Decision Table

| Pattern | Use When | Avoid When | Typical Outputs |
|---|---|---|---|
| Pipeline | Work has clear sequential dependencies | Specialists need to negotiate in real time | stage-by-stage docs, phase checklists, handoff files |
| Fan-out/Fan-in | Several analyses or implementations can run independently | Shared state changes would constantly conflict | parallel specialist roles, merge checklist, synthesis step |
| Expert Pool | Only some specialists are needed depending on context | The workflow is always the same | routing rules, specialist trigger map |
| Producer-Reviewer | Output quality depends on independent critique | There is no meaningful review surface | builder + verifier/evaluator roles, review rubric |
| Supervisor | A single coordinator must manage priorities and re-routing | The task is simple enough for one worker | orchestrator skill, teammate roster, task ownership |
| Hierarchical Delegation | Large work must be recursively decomposed | Scope is small or highly coupled | planner -> lead -> specialist tree, multi-level handoffs |

## Selection Heuristics

### Start with the work shape
- Feature implementation with clear build-then-check flow:
  - Prefer `Producer-Reviewer`
- Parallel code review across architecture, security, performance:
  - Prefer `Fan-out/Fan-in`
- End-to-end product delivery with design, implementation, QA, release:
  - Prefer `Pipeline` or `Supervisor`
- Research or support desks where the right specialist depends on the request:
  - Prefer `Expert Pool`
- Multi-domain programs or long-running migrations:
  - Prefer `Hierarchical Delegation`

### Add a review layer by default
- If the harness will generate or modify code, pair the main pattern with `Producer-Reviewer` unless the project is trivial.
- The generator and evaluator should not be the same role.

### Match the tool environment
- Claude Code with agent teams available:
  - `Supervisor`, `Fan-out/Fan-in`, and `Producer-Reviewer` become more valuable because explicit teammate coordination is available.
- Subagent-only environments:
  - Prefer `Pipeline` or `Fan-out/Fan-in` with explicit repo handoff artifacts.
- Mixed-tool repos:
  - Keep the orchestration pattern in docs and make the execution mechanism tool-specific.

## Minimum Good Harness

If the project is early-stage or underspecified, start with this baseline:
1. `Producer-Reviewer` core loop
2. One short entrypoint pointer
3. `docs/harness/overview.md`
4. Real verification commands
5. A cleanup / drift note in `docs/plans/` or `docs/reliability/`

## Escalation Rules
- If the same task class fails twice, add harness support instead of adding more prompt text.
- If humans repeatedly explain the same repo fact, move it into `docs/`.
- If QA depends on manual interpretation, add a verification surface or create a follow-up task that does.
