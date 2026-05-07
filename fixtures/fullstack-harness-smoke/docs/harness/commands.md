# Harness Commands

## Core Verification

- Lint: `npm run lint`
- Typecheck: `npm run typecheck`
- Unit tests: `npm run test`
- Integration tests: `npm run test:integration`
- E2E tests: `npm run test:e2e`
- Browser smoke: `browser verification unavailable`
- Build: `npm run build`

## When To Run

- Code edits: lint, typecheck, impacted tests
- API/data flow changes: integration tests
- User-facing UI changes: e2e plus browser verification
- Before completion: full verification set

## Notes

- In this fixture the commands validate the harness contract itself rather than a product runtime.
- In a real project these commands should be replaced with the repository's actual toolchain commands.
- `browser verification unavailable` is intentional here; a real app should replace it with Playwright or equivalent browser automation.
