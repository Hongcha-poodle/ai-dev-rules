# Streamboard Fixture

Harness bootstrap dry-run fixture for a small fullstack app.

## Purpose

- Simulate a project after `ai-dev-rules` installation
- Show the expected artifact shape after a request like:
  - `하네스 설치해`
  - `하네스 세팅해`
  - `하네스 구성해`

## App Shape

- Frontend: React dashboard
- Backend: Node API
- Data: PostgreSQL
- Verification: lint, typecheck, unit, integration, e2e, build

## What This Fixture Demonstrates

- Short entrypoints
- Dedicated harness docs
- Separate builder and verifier roles
- Claude Code specialist agents and orchestrator skill
- A `_workspace/` artifact convention for multi-step work
