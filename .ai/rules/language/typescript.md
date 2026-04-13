# TypeScript / JavaScript Rules

Referenced by `core.md` §4 when the project uses TypeScript or JavaScript.

## Build & Run

| Action | Command |
|---|---|
| Build | `npm run build` |
| Run | `npm run start` |
| Dev mode | `npm run dev` |

## Testing

| Action | Command |
|---|---|
| All tests | `npm test` |
| Single file | `npm test -- <path-or-pattern>` |
| Coverage | `npm test -- --coverage` |

### Test file conventions
- Location: `src/**/__tests__/`, `tests/`, or framework-standard colocated test folders
- Naming: `*.test.ts`, `*.spec.ts`, `*.test.tsx`, `*.spec.tsx`, `*.test.js`, `*.spec.js`

## Formatting & Linting

| Tool | Command | Config |
|---|---|---|
| Formatter | `npx prettier --check .` | `.prettierrc`, `prettier.config.*` |
| Linter | `npm run lint` | `eslint.config.*`, `.eslintrc.*` |
| Typecheck | `npm run typecheck` or `npx tsc --noEmit` | `tsconfig.json` |

## Language-Specific Notes
- Prefer strict TypeScript settings (`strict`, `noUncheckedIndexedAccess` when practical) for agent-verifiable safety.
- Treat `npm run lint`, `npm run typecheck`, and impacted tests as the minimum pre-completion gate for code changes.
- When `package.json` exposes scripts, prefer those over raw tool invocations so repo-local wrappers and caches are respected.
- For React/Next.js projects, verify user-facing changes with browser automation or screenshots in addition to unit tests.
- Avoid silent `any` expansion or broad `as unknown as` casts unless the code explains why the escape hatch is necessary.
