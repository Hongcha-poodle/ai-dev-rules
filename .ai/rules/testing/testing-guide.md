# Testing Guide

## Hard Rules
- [HARD] **Reproduction-First**: Write a failing reproduction test before fixing any bug.
- [HARD] **Test Before Merge**: No feature is complete without tests.
- Test **behavior**, not implementation details.
- Test code quality = production code quality.

## Test Layers

| Layer | Scope | External deps | Speed | Focus |
|---|---|---|---|---|
| Unit | Single function/class | All mocked | ms | Core logic, 80%+ coverage |
| Integration | Module interfaces | Partial real (DB, FS) | Medium | Happy path + error path |
| E2E | Full user scenario | Real environment | Slow | Critical scenarios only |

## Conventions

### File structure
Follow language conventions. Language-specific commands in `@.ai/rules/language/`.

| Language | Pattern | Location |
|---|---|---|
| Go | `*_test.go` | Same directory |
| Python | `test_*.py` | `tests/` or same dir |
| TypeScript | `*.spec.ts` | `__tests__/` or same dir |

### Naming
```
[target] + [scenario] + [expected result]
e.g. calculateTotal_withDiscount_returnsReducedPrice
e.g. login_withInvalidPassword_throws401Error
```

### Mock/Stub rules
| Dependency | Mock? |
|---|---|
| External API, DB, File I/O | Always |
| Internal modules (unit test) | Yes |
| Internal modules (integration) | Prefer real |
| Time/date logic | Always |

## Coverage
Thresholds in `@.ai/config/quality.yaml`. Focus on critical paths being actually tested, not hitting a number. High coverage with weak assertions is meaningless.

## Checklist
- [ ] Unit tests for new features?
- [ ] Reproduction test written before bug fix?
- [ ] Edge cases tested (empty, null, boundary)?
- [ ] Tests run independently (no order dependency)?
- [ ] Teardown cleans external state?
