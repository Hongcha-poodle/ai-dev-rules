# Research Content Starter

## Use When

- The project centers on research, drafting, packaging, publishing, or content operations.
- The workflow needs strategy, production, packaging, and review as distinct steps.
- The user cares about repeatable output quality and artifact traceability.

## Default Pattern

- Primary: `Pipeline`
- Secondary: `Producer-Reviewer`

## Recommended Roles

- `research-strategist`
- `drafter`
- `package-editor`
- `reviewer`

Optional:

- `fact-checker`

## Recommended Repo Outputs

- `docs/harness/overview.md`
- `docs/harness/content-workflow.md`
- `docs/harness/commands.md`
- `docs/plans/active/harness-bootstrap.md`

If the project uses Claude Code:

- `.claude/agents/research-strategist.md`
- `.claude/agents/drafter.md`
- `.claude/agents/package-editor.md`
- `.claude/agents/reviewer.md`
- `.claude/skills/{content-harness}/skill.md`

Optional artifact trail:

- `_workspace/00_input.md`
- `_workspace/01_research-brief.md`
- `_workspace/02_draft.md`
- `_workspace/03_packaging.md`
- `_workspace/04_review.md`

## Template Skeletons

### `docs/harness/content-workflow.md`

```md
# Content Workflow

## Stages
1. Research brief
2. Draft
3. Packaging / formatting
4. Review

## Role Ownership
- Research Strategist:
- Drafter:
- Package Editor:
- Reviewer:

## Quality Gates
- Source quality:
- Required sections:
- Review standard:
- Publish / handoff format:
```

### `docs/harness/overview.md`

```md
# Harness Overview

## Goal
- Create repeatable research and content output for this project.

## Primary Pattern
- Pipeline with separate review stage

## Roles
- Research Strategist
- Drafter
- Package Editor
- Reviewer

## Verification Surfaces
- source links:
- draft checklist:
- packaging checklist:
- reviewer rubric:
```

## Validation Checklist

- Are research and review separated?
- Is there a durable artifact per stage?
- Are output formats explicit?
- Can future runs reuse the same workflow without re-explaining it in chat?
