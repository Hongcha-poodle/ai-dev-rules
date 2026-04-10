# Harness Bootstrap Plan

## Scope

- Build a reusable fullstack harness for Streamboard.

## Deliverables

- Short entrypoints
- Harness docs
- Specialist agent roles
- Orchestrator skill
- Validation flow

## Tasks

- [x] Audit project surface and commands
- [x] Select `fullstack-app-starter`
- [x] Add `docs/harness/overview.md`
- [x] Add `docs/harness/commands.md`
- [x] Add `docs/harness/validation.md`
- [x] Add `.claude/agents/*`
- [x] Add `.claude/skills/streamboard-harness/skill.md`
- [ ] Add `.claude/settings.json` hooks for lint/typecheck/test
- [ ] Add structured logs and browser verification command

## Notes

- This fixture intentionally leaves hooks and observability as TODO so the harness does not pretend the project is more complete than it is.
