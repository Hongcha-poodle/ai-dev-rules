# Code Review Starter

## Use When

- The main goal is review, audit, triage, or remediation planning.
- The user wants findings first and cross-domain review coverage.
- The project needs structured review ownership more than implementation ownership.

## Default Pattern

- Primary: `Fan-out/Fan-in`
- Secondary: `Producer-Reviewer`

## Recommended Roles

- `architecture-reviewer`
- `security-reviewer`
- `performance-reviewer`
- `test-reviewer`
- `review-synthesizer`

Use `review-synthesizer` as the single point that merges findings and removes duplication.

## Recommended Repo Outputs

- `docs/harness/overview.md`
- `docs/harness/review-playbook.md`
- `docs/harness/commands.md`
- `docs/plans/active/harness-bootstrap.md`

If the project uses Claude Code:

- `.claude/agents/architecture-reviewer.md`
- `.claude/agents/security-reviewer.md`
- `.claude/agents/performance-reviewer.md`
- `.claude/agents/test-reviewer.md`
- `.claude/agents/review-synthesizer.md`
- `.claude/skills/{review-harness}/skill.md`

Optional review artifacts:

- `_workspace/00_input.md`
- `_workspace/10_architecture-findings.md`
- `_workspace/11_security-findings.md`
- `_workspace/12_performance-findings.md`
- `_workspace/13_test-findings.md`
- `_workspace/20_synthesized-review.md`

## Template Skeletons

### `docs/harness/review-playbook.md`

```md
# Review Playbook

## Review Lanes
- Architecture
- Security
- Performance
- Testing / reliability

## Finding Format
- Title
- Severity
- Evidence
- Risk
- Suggested remediation

## Synthesis Rules
- Merge duplicate findings
- Findings come before summary
- Call out unknowns separately
```

### `docs/harness/overview.md`

```md
# Harness Overview

## Goal
- Produce consistent, multi-lens review output for this project.

## Primary Pattern
- Fan-out/Fan-in review with explicit synthesis

## Roles
- Architecture Reviewer
- Security Reviewer
- Performance Reviewer
- Test Reviewer
- Review Synthesizer

## Verification Inputs
- lint / static analysis:
- tests:
- benchmarks:
- runtime logs:
- security checks:
```

## Validation Checklist

- Does each reviewer have a distinct lane?
- Are findings structured and evidence-based?
- Is there an explicit synthesis step?
- Can repeated review requests reuse the same playbook and commands?
