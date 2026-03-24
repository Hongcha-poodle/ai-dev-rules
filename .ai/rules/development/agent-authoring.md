# Agent & Skill Authoring Guide

## Agent Roles

| Role | Purpose | Access | subagent_type |
|---|---|---|---|
| Explore | Read-only codebase search | Read | `"Explore"` |
| Plan | Architecture, implementation strategy | Read | `"Plan"` |
| Execute | Code changes, multi-file edits, commands | Read+Write | `"general-purpose"` |
| Verify | Regression checks, smoke tests, release validation | Read or Read+Exec | `"Explore"` or `"general-purpose"` |
| Release | Deployment readiness, rollback, observability | Read+Write/Exec | `"general-purpose"` + DevOps context |
| Search | External docs/API research | External | `"general-purpose"` + web tools |
| Specialist | Domain-specific expertise | Per-domain | `"general-purpose"` + domain prompt |

### Delegation Decision Tree
1. Read-only exploration needed? → Explore
2. External research needed? → Search
3. Domain expertise needed? → Specialist
4. Architecture/strategy design? → Plan
5. Post-change verification or regression review? → Verify
6. Deployment/readiness/ops review? → Release
7. Multi-file code changes? → Execute

### Parallel Execution
- No dependency between tasks → delegate simultaneously
- Example: Explore (code search) + Search (docs) in parallel
- Example: Execute (implementation) + Verify (regression planning) in parallel
- Write conflicts → serialize or use `isolation: "worktree"`

## Agent Design Principles

### Single Responsibility
- One clear purpose per agent
- Well-defined role and scope
- Avoid feature overload

### Clear Interface
- Define inputs and outputs explicitly
- Specify error handling behavior
- Document the API

### Reusability
- Generic design with configurable parameters
- Modular structure

## Skill Structure

```markdown
# Skill Name

## Purpose
- Problem this skill solves

## Trigger
- When to auto-load (e.g. "on security review request")

## Capabilities
- Key features

## Usage
- Example scenarios

## Constraints
- Known limitations
```

## Testing

### Unit
- Test each capability independently
- Cover edge cases

### Integration
- Verify inter-agent interaction
- Test real usage scenarios
- Verify handoff quality between Execute → Verify → Release
- Verify whether the repo needs a Harness / Enablement agent to improve docs, scripts, or observability

## Documentation Requirements
- Purpose and overview
- Usage examples
- API reference
- Version history
- Known issues
