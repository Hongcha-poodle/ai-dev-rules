# Harness Validation

## Dry-Run Scenario

Prompt:

`하네스 설치해. 이 프로젝트는 React frontend와 Node API가 있고, UI 변경과 API 변경 모두 검증돼야 해.`

## Expected Behavior

1. Audit existing entrypoints and docs
2. Select the fullstack starter
3. Define separate roles for implementation and verification
4. Generate or update harness docs
5. Point entrypoints to durable docs
6. Record known gaps instead of inventing observability surfaces

## Success Criteria

- Entry points are short
- Commands are explicit and real
- QA/reviewer path is separate
- Release-readiness ownership exists
- `_workspace/` convention is documented

## Remaining TODOs For A Real Project

- Add `.claude/settings.json` hooks
- Wire browser automation command
- Add structured log query examples
- Add rollback checklist for deploys
