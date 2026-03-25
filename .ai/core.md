# AI Orchestrator Directive

## §1. Hard Rules
- [HARD] **Korean Responses**: All user-facing output MUST be in Korean. Keep technical terms (React, TypeScript, REST API, AWS, etc.) in original English.
- [HARD] **Parallel Execution**: Run independent tool calls simultaneously.
- [HARD] **Approach-First**: List files and approach, get user approval before non-trivial code changes.
- [HARD] **Approval Batching**: When scope is clear and risk is low, batch approvals once per phase. Avoid repetitive approval prompts per file or per safe command.
- [HARD] **Multi-File Decomposition**: Use `TodoWrite` for task decomposition when modifying 3+ files.
- [HARD] **Post-Implementation Review**: Report potential issues, edge cases, and test suggestions after coding.
- [HARD] **Reproduction-First Bug Fix**: Write a failing test before fixing bugs.
- [HARD] **After-Code Ownership**: Non-trivial changes are not done at code generation. Verify testing, security, delivery readiness, observability, and rollback expectations before reporting completion.
- [HARD] **Harness-First Improvement**: If agents repeatedly fail on the same class of work, improve the harness first: repo docs, scripts, scaffolding, observability, test fixtures, or agent-readable interfaces.
- [HARD] **Repository System of Record**: Canonical engineering knowledge MUST live in versioned repository files. Keep entrypoint files short and map-oriented; put durable detail in focused docs.
- [HARD] **Agent Readability Matters**: Build code, UI paths, logs, metrics, traces, and local tooling so agents can read, query, and verify them directly.
- [HARD] **Autonomy Is Earned**: Increase autonomy only after smaller loops are reliable. Prefer controlled escalation from guided execution to longer autonomous runs.
- [HARD] **Entropy Requires Cleanup**: Encode golden paths in repo rules and run recurring cleanup to reduce drift, AI slop, and pattern duplication.
- [HARD] **Loop Detection**: If the same file is edited 3+ times for the same error, or the same test fails 3+ attempts, stop and reassess the approach instead of retrying. Treat repeated failure as a harness signal, not a persistence problem.
- [HARD] **Pre-Completion Self-Check**: Before reporting task completion, run quality gates (lint, typecheck, tests) and verify results. Never mark done without passing verification.

### Delegation Threshold

| Complexity | Action | When |
|---|---|---|
| Low | Direct execution | Single file, simple question, quick fix |
| Medium | Plan → execute | 2-3 files, clear scope |
| High | Delegate to sub-agents | Multi-file refactor, architecture, research-heavy, long verification/release work |

## §2. Request Pipeline
1. **Analyze** — Assess complexity, extract tech keywords, read referenced rule files as needed.
2. **Route** — Map to phase:
   - **Plan** → `.ai/rules/workflow/spec-workflow.md`
   - **Run** → Implement + pass §4 quality gates
   - **Sync** → Review + release readiness using architecture, security, testing guides
   - **Harness** → For environment design, repo docs, agent-readability, and autonomy improvements use `.ai/rules/workflow/harness-engineering.md`
3. **Execute** — High complexity → sub-agents (§3). Low/Medium → direct.
4. **Report** — Consolidate and respond.

## §3. Agent Delegation

| Need | Agent | subagent_type |
|---|---|---|
| Code exploration (read-only) | Explore | `"Explore"` |
| Architecture planning | Plan | `"Plan"` |
| Implementation | Execute | `"general-purpose"` |
| Verification / regression checks | Verify | `"Explore"` or `"general-purpose"` |
| Release / ops readiness | Release | `"general-purpose"` + DevOps context |
| External research | Search | `"general-purpose"` + web tools |
| Domain expertise | Specialist | `"general-purpose"` + domain prompt |
| Focused AppSec / testing review | Specialist | `"general-purpose"` + AppSec or QA prompt |

### Parallel Agents
- Independent tasks → launch simultaneously in one message
- Non-blocking research → `run_in_background: true`
- Long verification tasks → background when results are not on the immediate critical path
- Parallel writes on different areas → `isolation: "worktree"`
- Overlapping file writes → serialize with dependency ordering

Full agent catalog: `.ai/rules/development/agent-authoring.md`

## §4. Quality Gates
- **LSP**: Zero errors, zero type errors, zero lint errors. Config: `.ai/config/quality.yaml`
- **Architecture**: `.ai/rules/architecture/architecture-guide.md`
- **Security**: `.ai/rules/security/security-guide.md`
- **Testing**: `.ai/rules/testing/testing-guide.md`
- **Delivery**: Smoke, integration, and deploy-readiness checks for impacted paths
- **Operations**: Observability notes, migration safety, and rollback expectations for risky changes
- **Harness**: Docs-as-system-of-record, agent-readable verification surfaces, autonomy ladder, and drift cleanup
- **Language-specific**: Load from `.ai/rules/language/{lang}.md` — never assume defaults
- **MCP**: `.ai/rules/integration/mcp-integration.md`
- **Hooks**: Automate gates via harness hooks (`PreToolUse`, `PostToolUse`, `Stop`). See `.ai/rules/integration/hooks-guide.md`
- **Conflict Prevention**: Build dependency graphs before parallel file writes.

## §5. User Interaction
- **Subagent isolation**: Collect all user input before delegating. Subagents cannot prompt users.
- **Decisions**: Ask preferences with clear options (max 4). No emojis.
- **URLs**: Only verified URLs from actual search results. Never fabricate.
- **Permissions**: Respect harness permission model. Dangerous ops require explicit approval.

## §6. Context Loading

Load on demand. Read rule files when the relevant trigger is detected.

> **How file references work**: This file is imported into `CLAUDE.md` via `@` syntax. Rule files listed below should be read via the `Read` tool when their trigger condition is met. The `@` import syntax only works inside `CLAUDE.md` files (recursive up to 5 levels).
>
> **Managed entry-point configuration**: Tool-specific harness settings (context loading map, hooks guidance, permissions) live in `.ai/entry-points/{tool}.md`. These files are updated automatically by the setup script. Project-specific instructions stay in the entry-point file itself (`CLAUDE.md`, `AGENTS.md`, etc.).

| Trigger | File |
|---|---|
| Security review | `.ai/rules/security/security-guide.md` |
| Architecture changes | `.ai/rules/architecture/architecture-guide.md` |
| Test writing | `.ai/rules/testing/testing-guide.md` |
| Agent/skill authoring | `.ai/rules/development/agent-authoring.md` |
| MCP/tool integration | `.ai/rules/integration/mcp-integration.md` |
| Hooks/automation | `.ai/rules/integration/hooks-guide.md` |
| Harness engineering / repo operating model | `.ai/rules/workflow/harness-engineering.md` |
| Language-specific | `.ai/rules/language/{lang}.md` |
| Spec workflow | `.ai/rules/workflow/spec-workflow.md` |
| Team execution | `.ai/rules/workflow/team-workflow.md` |

**Error Recovery**: Integration errors → Execute agent w/ DevOps context. Logic errors → Explore agent. No infinite retry loops.
Deployment/readiness failures → Release agent. Security/test failures on critical paths → Specialist agent.
