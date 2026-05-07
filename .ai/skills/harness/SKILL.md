# Harness Bootstrap

## Purpose
- Build or evolve a project-specific harness when the user says things like `하네스 구성해`, `하네스 구축해`, `하네스 설계해`, `하네스 설치해`, `하네스 세팅해`, `하네스 셋팅해`, `build a harness for this project`, `set up a harness for this project`, or asks for harness audit/expansion.
- Turn harness engineering principles into concrete repo artifacts for the current project: docs, agent-readable verification surfaces, automation, and tool-specific orchestration.

## Trigger
- Use this skill when the user explicitly asks to build, set up, install, configure, bootstrap, audit, repair, or extend a harness.
- Treat common Korean variants such as `하네스 설치해`, `하네스 세팅해`, `하네스 셋팅해`, `하네스 셋업해`, and `하네스 잡아줘` as harness bootstrap requests unless the user clearly means a specific third-party plugin install only.
- Also use it when the task is really about enabling agents to work better on the project rather than shipping one feature.

## Capabilities
- Audit existing harness state before creating anything new.
- Choose an execution pattern that fits the project:
  - `Pipeline` for sequential dependent work
  - `Fan-out/Fan-in` for parallel independent work
  - `Expert Pool` for selective specialist routing
  - `Producer-Reviewer` for generation plus independent verification
  - `Supervisor` for central orchestration
  - `Hierarchical Delegation` for recursive decomposition
- Generate project-local harness artifacts such as:
  - short entrypoint pointers
  - `docs/` maps and harness notes
  - verification command lists
  - hook or automation recommendations
  - Claude-specific `.claude/agents/` and `.claude/skills/` packages when the project uses Claude Code
- Define a validation plan so the harness is tested, not just written down.

## Workflow

### Phase 0. Audit current state
- Read the active entrypoint files first: `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, or `.agent/rules/rules.md` when present.
- Inspect existing harness-related folders and files before adding new ones:
  - `.claude/agents/`
  - `.claude/skills/`
  - `.claude/settings.json`
  - `docs/index.md`
  - `docs/reliability/`
  - `docs/security/`
  - `docs/plans/`
- Detect drift between entrypoints, docs, scripts, and actual verification commands.
- Check referenced paths before trusting generated docs:
  - Prefer `scripts/harness-audit.py` when present.
  - Otherwise scan backtick path references in entrypoints and `docs/**/*.md`; report missing files such as stale `lib/content-data.ts` pointers.
- Summarize what already exists, what is missing, and what should be preserved.

### Phase 1. Analyze the project
- Identify the stack, runtime surface, verification commands, and deployment/rollback needs.
- Identify repeated failure points that should be solved by harness improvements rather than longer prompts.
- Classify the main work shape:
  - feature delivery
  - code review
  - QA / regression
  - research
  - release / operations
  - long-running autonomous work

### Phase 2. Choose the harness shape
- Read `references/pattern-selection.md` and pick one primary orchestration pattern plus optional secondary patterns.
- When the project matches a common starter-kit shape, also read `references/harness-100-template-pack.md`.
- Load the closest starter template from `templates/`:
  - software product work → `templates/fullstack-app-starter.md`
  - audit/review-heavy work → `templates/code-review-starter.md`
  - research/drafting/package work → `templates/research-content-starter.md`
- Prefer the lightest harness that still gives reliable execution and verification.
- For projects with Claude Code agent teams enabled, prefer a team-based design when two or more specialists need to coordinate.
- For other tools, keep the same harness intent but express it through repo-local docs, scripts, and reusable role definitions.

### Phase 3. Generate harness artifacts
- Always keep entrypoints short and map-oriented.
- Always write durable knowledge into repo files, never only into chat output.
- Produce the artifacts described in `references/output-contract.md`.
- Reuse the baseline conventions from `references/harness-100-template-pack.md` when they fit:
  - `.claude/CLAUDE.md` summary map
  - 4-5 specialist agents plus one reviewer/QA role
  - one orchestrator skill plus 1-2 agent-extending skills
  - `_workspace/` artifact convention
  - full / reduced / single-agent scale modes
  - explicit should-trigger and NOT-trigger boundaries
- Start from the selected starter template and then adapt it. Do not leave template placeholders unresolved in the final project files.
- If the project uses Claude Code, generate:
  - `.claude/agents/{name}.md`
  - `.claude/skills/{skill-name}/SKILL.md`
  - optional `.claude/skills/{skill-name}/references/*`
  - `.claude/settings.json` hook suggestions when appropriate
- If the project does not use Claude Code, still generate a repo-local harness package:
  - `docs/harness/overview.md`
  - `docs/harness/commands.md`
  - `docs/harness/validation.md`
  - `docs/plans/active/harness-bootstrap.md`
  - entrypoint updates that point to those files

### Phase 4. Wire verification surfaces
- Ensure the harness tells agents how to verify their own work.
- Prefer adding or documenting:
  - lint / typecheck / unit / integration / smoke commands
  - browser automation or screenshot checks for UI work
  - structured logs
  - metrics / traces when the project already has or needs them
  - deterministic fixtures or seed scripts
- If a required surface does not yet exist, create a concrete follow-up plan instead of pretending the harness is complete.
- For UI/browser verification:
  - If Playwright or an equivalent browser runner exists, propose or wire a real script such as `npm run smoke:browser`.
  - If browser automation is unavailable, write an explicit TODO labeled `browser verification unavailable`.
  - Record the gap in `docs/harness/validation.md` as a known gap, not just chat output.

### Phase 5. Validate the harness
- Run or document a dry run using one representative task.
- Verify:
  - triggers are discoverable
  - entrypoints point to deeper docs
  - verification commands are real
  - quality gates are runnable
  - reviewer / evaluator separation exists for non-trivial work
- Run `scripts/harness-audit.py` when available to catch referenced-path drift in entrypoints and harness docs.
- Record remaining gaps and next iteration steps.

### Phase 6. Decide whether the client must reload
- Claude Code:
  - Claude Code loads `.claude/settings.json`, `.claude/agents/`, `.claude/skills/`,
    and `CLAUDE.md` only at session start.
  - If any of those Claude-managed artifacts were generated or modified, instruct the user to reload before verifying:
    - `/exit` — leave the current session
    - `claude --resume` (or `cc --resume`) — pick the session that just ended so
      the conversation context is preserved while the harness is re-read
    - Trigger one of the newly added skills/agents to confirm it actually loads
  - If the repo has no `CLAUDE.md` and no `.claude/*` artifacts, record `Claude-managed artifact 없음, reload 불필요`.
- Codex:
  - Continue in a fresh request or explicitly ask Codex to re-read `AGENTS.md`, `.ai/entry-points/codex.md`, and `docs/harness/`.
  - Do not copy Claude Code's `/exit` flow unless the active Codex client documents session-level caching.
- GitHub Copilot:
  - Use the client's instruction reload behavior for `.github/copilot-instructions.md`; when unclear, start a new chat/session after changing instructions.
- Google Antigravity:
  - Use the client's rule reload behavior for `.agent/rules/rules.md`; when unclear, start a new task/session after changing rules.
- On-demand rules under `.ai/rules/*.md` are re-read when the client explicitly reads them, so they do not require Claude-style reload by themselves.
- When post-bootstrap verification fails ("the new skill isn't triggering", "hooks didn't run"), check the relevant client reload/re-read rule before debugging the artifacts.

## Usage
- `하네스 구성해. 이 프로젝트는 Next.js + Supabase 기반이고, UI 변경과 API 변경을 모두 검증할 수 있어야 해.`
- `하네스 설치해. 이 프로젝트에서 Claude Code와 Codex가 반복 작업을 덜 헤매게 해줘.`
- `하네스 세팅해. 테스트, review, release readiness까지 잡아줘.`
- `하네스 셋팅해. 지금 repo 구조에 맞는 harness artifact를 만들어줘.`
- `이 repo에 Claude Code용 하네스를 구축해. agent team, skills, hooks까지 제안해줘.`
- `현재 하네스를 감사하고 drift를 줄이도록 재구성해.`

## Constraints
- Do not create giant entrypoint files. Keep them as maps.
- Do not invent verification commands. Discover them from the repo or clearly mark them as TODOs.
- Do not force Claude-only outputs on projects that are not using Claude Code.
- Do not stop at architecture prose; produce repo artifacts that future runs can reuse.
- Do not cargo-cult a full harness-100 package into a project. Distill the pattern, then adapt it to the project's actual stack and scope.
- For bulky examples and decision guides, load `references/` files only when needed.
- Remind the user to reload Claude Code (`/exit` → `claude --resume`) only after producing or modifying `.claude/` artifacts or `CLAUDE.md`; otherwise report that no Claude-managed reload is required.
