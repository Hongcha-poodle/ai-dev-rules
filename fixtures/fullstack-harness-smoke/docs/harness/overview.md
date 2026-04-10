# Harness Overview

## Goal

- Let agents ship and verify Streamboard changes with less repeated explanation.
- Keep implementation, QA, and release readiness separate.

## Primary Pattern

- Producer-Reviewer

## Secondary Pattern

- Pipeline

## Roles

- Architect: 구조 변경과 dependency direction 점검
- Frontend Dev: UI 구현과 browser-verifiable behavior 담당
- Backend Dev: API, data flow, integration 담당
- QA Engineer: regression, smoke, edge case 검증 담당
- Release Engineer: build, config, rollback, observability readiness 담당

## Verification Surfaces

- lint: `npm run lint`
- typecheck: `npm run typecheck`
- unit: `npm run test`
- integration: `npm run test:integration`
- e2e: `npm run test:e2e`
- build: `npm run build`
- browser automation: required for user-facing UI changes
- logs/metrics/traces: TODO for real project integration

## Artifact Convention

- Multi-step work stores intermediate outputs in `_workspace/`
- Suggested flow:
  - `_workspace/00_input.md`
  - `_workspace/01_architecture.md`
  - `_workspace/02_execution.md`
  - `_workspace/03_validation.md`

## Known Gaps

- Structured logs are not wired yet
- Metrics and traces are still TODO
- Hook automation is not configured in this fixture
