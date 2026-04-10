# Harness Commands

## Core Verification

- Lint: `npm run lint`
- Typecheck: `npm run typecheck`
- Unit tests: `npm run test`
- Integration tests: `npm run test:integration`
- E2E tests: `npm run test:e2e`
- Build: `npm run build`

## When To Run

- Code edits: lint, typecheck, impacted tests
- API/data flow changes: integration tests
- User-facing UI changes: e2e plus browser verification
- Before completion: full verification set

## Notes

- In this fixture the commands are lightweight placeholders so the harness shape is easy to inspect.
- In a real project these commands must map to the actual toolchain.
