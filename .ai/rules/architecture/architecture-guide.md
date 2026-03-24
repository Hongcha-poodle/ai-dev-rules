# Architecture Guide

## Hard Rules
- [HARD] **Approach-First**: List target files and approach before non-trivial code. Get user approval.
- Read existing patterns first, then write. Maintain consistency.
- Minimize complexity for current requirements. No speculative abstractions.

## Layer Separation & Dependency Direction

```
UI / Controller → Service / Use Case → Domain / Entity → Infrastructure (DB, API, File)
```

Inner layers MUST NOT depend on outer layers. Domain layer has zero framework/DB dependencies.

### Dependency Layering (Harness Engineering)

Enforce a strict unidirectional dependency flow. Each layer may only import from layers to its right:

```
Types → Config → Repository → Service → Runtime → UI
```

- **Types**: Shared type definitions, interfaces, DTOs. Zero runtime dependencies.
- **Config**: Environment config, feature flags. Depends only on Types.
- **Repository**: Data access, external API clients. Depends on Types + Config.
- **Service**: Business logic orchestration. Depends on Types + Config + Repository.
- **Runtime**: Server bootstrap, middleware, DI wiring. Depends on all above.
- **UI**: Controllers, views, API handlers. Depends on all above.

**Violations to detect**:
- UI importing from Repository directly (skipping Service)
- Service importing from UI or Runtime
- Types importing from anything
- Circular dependencies at any level

### Mechanical Enforcement

Architecture rules should be enforced mechanically, not just by convention:

| Method | Tool examples | When to use |
|---|---|---|
| **Structural tests** | ArchUnit, dependency-cruiser, deptry | CI pipeline — fail build on violation |
| **Deterministic linters** | eslint-plugin-import, go vet, custom lint rules | `PostToolUse` hook — immediate feedback |
| **LLM-based auditor** | Explore agent with architecture prompt | Sync phase — review for subtle violations |

Example dependency-cruiser rule (JS/TS):
```json
{
  "forbidden": [
    {
      "name": "no-ui-to-repo",
      "from": { "path": "^src/ui/" },
      "to": { "path": "^src/repository/" }
    },
    {
      "name": "no-service-to-ui",
      "from": { "path": "^src/service/" },
      "to": { "path": "^src/ui/" }
    }
  ]
}
```

| Layer | Responsibility | Must NOT contain |
|---|---|---|
| Controller/Handler | Request parsing, response formatting | Business logic |
| Service/Use Case | Business flow orchestration | Direct DB queries |
| Domain/Entity | Core business rules | Framework deps |
| Repository | Data access abstraction | Business decisions |

## Modularity

### Split criteria
- Different change reasons → separate (SRP)
- Co-changing code → keep together (cohesion)
- Group by reuse boundary

### Size guidelines
- Function: single responsibility, fits one screen
- File: review at 200-400 lines, split if exceeded
- Class/module: review at 7+ public interfaces

## Design Decisions

### Adding features
1. Read existing patterns first
2. Follow existing patterns (consistency over novelty)
3. If patterns are flawed, propose refactoring as a separate task

### Refactoring
- Never mix feature changes with structural changes
- Verify sufficient test coverage before refactoring
- Proceed in small incremental steps

### Dependencies
- Wrap external libraries behind interfaces for replaceability
- Zero circular dependencies
- Use DI for testability

## Checklist
- [ ] Existing architecture patterns identified and followed?
- [ ] Layer dependency direction correct (Types→Config→Repo→Service→Runtime→UI)?
- [ ] Business logic not leaking into Controller/Infrastructure?
- [ ] No circular dependencies?
- [ ] Structural tests or linter rules enforce dependency direction?
- [ ] Minimum complexity for current requirements?
