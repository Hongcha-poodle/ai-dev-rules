# Harness-100 Template Pack

This reference distills reusable conventions from `revfactory/harness-100` instead of copying its domain packages verbatim.

Primary source examples reviewed:
- `harness-100` repo overview and architecture
- `ko/01-youtube-production/.claude/CLAUDE.md`
- `ko/01-youtube-production/.claude/agents/content-strategist.md`
- `ko/01-youtube-production/.claude/skills/youtube-production/skill.md`
- `ko/16-fullstack-webapp/.claude/CLAUDE.md`
- `ko/16-fullstack-webapp/.claude/skills/fullstack-webapp/skill.md`
- `ko/16-fullstack-webapp/.claude/skills/component-patterns/skill.md`

## Reusable Structural Conventions

### 1. Package layout

Use this as the Claude Code baseline when the project supports `.claude/`:

```text
.claude/
  CLAUDE.md
  agents/
    {specialist-1}.md
    {specialist-2}.md
    {specialist-3}.md
    {specialist-4}.md
    {reviewer-or-qa}.md
  skills/
    {orchestrator}/skill.md
    {agent-extending-skill-1}/skill.md
    {agent-extending-skill-2}/skill.md
```

Why this works:
- `CLAUDE.md` stays small and acts as a harness map.
- Agent files define "who does the work".
- Skills define "how the work is done".
- One reviewer/QA role is always visible as a separate quality path.

### 2. Three-layer skill system

Harness-100 repeatedly uses this shape:
- `Orchestrator`: team coordination, workflow phases, dependencies, error handling
- `Agent-extending skills`: focused domain expertise that upgrades a specialist
- `External tools`: web search, image generation, or external services used only where needed

Adopt this pattern when building a project harness:
- every serious harness should have exactly one orchestrator entrypoint
- add agent-extending skills only when they meaningfully deepen specialist output quality
- keep external-tool usage explicit and bounded

### 3. `_workspace/` artifact contract

Most sample harnesses store intermediate artifacts in `_workspace/` with ordered file names:

```text
_workspace/
  00_input.md
  01_{phase-output}.md
  02_{phase-output}.md
  ...
```

This is useful because:
- phases become inspectable
- later agents can read earlier artifacts directly
- review and audit become easier

Use `_workspace/` when:
- the harness coordinates multiple specialists
- intermediate outputs matter
- partial reruns or audits are likely

Skip or simplify it when:
- the project already has a stronger native artifact system
- the task is a tiny one-shot update

### 4. Scale modes

Harness-100 commonly defines multiple execution scopes:
- full pipeline
- reduced mode
- single-agent or review-only mode

When generating a new harness, include a small routing table like:

| User request pattern | Mode | Agents |
|---|---|---|
| full build request | full pipeline | all specialists |
| narrow subsystem request | reduced mode | subset + reviewer |
| audit / verification only | review mode | reviewer/qa only |

This prevents over-deploying the entire team for small jobs.

### 5. Trigger boundaries

Harness-100 descriptions are intentionally aggressive about when a skill should trigger, and also explicit about when it should not.

Apply the same rule:
- include should-trigger phrases
- include NOT-trigger boundaries
- mention adjacent tasks that should route elsewhere

This helps avoid ambiguous triggering and keeps skills from being too passive.

### 6. Structured outputs

Harness-100 agent files and orchestrators define concrete output locations and formats.

Reuse that idea:
- every agent should know its output file or output section
- every orchestrator should know final report paths
- every reviewer should emit a structured review artifact, not only chat text

## Reusable Starter Kits

These are not hardcoded templates. They are starter patterns to adapt.

### A. Fullstack App Starter

Use for product engineering projects that span design/implementation/testing/release.

Recommended roles:
- `architect`
- `frontend-dev`
- `backend-dev`
- `qa-engineer`
- `devops-engineer`

Recommended skills:
- one orchestrator skill for the whole product flow
- one frontend extension skill
- one backend/reliability/security extension skill

Typical artifact flow:
- `00_input.md`
- architecture
- api spec
- db schema
- test plan
- deploy guide
- review report

### B. Code Review Starter

Use for audit-heavy requests.

Recommended roles:
- `architecture-reviewer`
- `security-reviewer`
- `performance-reviewer`
- `style-reviewer`
- `synthesis-reviewer`

Primary pattern:
- `Fan-out/Fan-in` plus explicit synthesis

Typical artifact flow:
- parallel finding files
- merged review summary
- remediation checklist

### C. Research / Content Starter

Use when discovery, drafting, packaging, and cross-checking are the core loop.

Recommended roles:
- strategist / researcher
- drafter / producer
- package specialist
- reviewer

Primary pattern:
- `Pipeline` or `Producer-Reviewer`

## Adaptation Rules For Our Repo

- Prefer repo-level harness docs when the project is not Claude-first.
- Use the harness-100 structure as a source of naming and packaging discipline, not as a requirement to always create five agents.
- For software projects in our workflow, always keep separate verification ownership even if the rest of the harness is small.
- If the project already has `.ai/`, `AGENTS.md`, or `docs/`, merge the harness into those structures instead of creating a parallel universe.

## What To Copy vs What To Distill

Copy directly:
- the small-map `CLAUDE.md` idea
- agent/skill separation
- orchestrator + extension layering
- `_workspace/` intermediate artifacts when helpful
- scale modes and trigger boundaries

Distill rather than copy:
- domain-specific role names
- domain-specific frameworks
- exact prompt wording
- any structure that conflicts with the project's existing stack or toolchain
