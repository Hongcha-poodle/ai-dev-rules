# Security Guide

OWASP Top 10 based. Prioritized by frequency.

## Hard Rules
- [HARD] Never generate code with known security vulnerabilities.
- [HARD] Never hardcode secrets (API keys, passwords, tokens). Use env vars or secret managers.
- Validate and escape all external input (trust boundary principle).
- Design with least privilege by default.

## Injection Prevention

**Always** use parameterized queries. Never concatenate user input into queries.

```
# FORBIDDEN
query = "SELECT * FROM users WHERE id = " + user_input

# REQUIRED
query = "SELECT * FROM users WHERE id = ?"
execute(query, [user_input])
```

Applies to: SQL, NoSQL, OS commands, LDAP.

## Auth & Session
- Passwords: bcrypt or argon2 only. Never plaintext/MD5/SHA1.
- Session tokens: 128+ bit entropy.
- JWT: explicit algorithm (`alg: none` forbidden), mandatory expiration.

## XSS
- Escape all user input before HTML rendering.
- Set CSP headers.
- Sanitize before `innerHTML` / `dangerouslySetInnerHTML`.

## Data Exposure
- No stack traces, DB schemas, or internal paths in error responses.
- No passwords, tokens, or PII in logs.
- Strip unnecessary fields from API responses (minimum exposure).

## Access Control
- Auth/authz checks on every API endpoint.
- Prevent IDOR: verify resource ownership before access.
- Role-based restrictions for admin functions.

## Dependency Security
- No known-vulnerable library versions.
- Regular audits: `npm audit`, `pip-audit`, `go vuln`, etc.

## Review Checklist
- [ ] No hardcoded secrets?
- [ ] All external input validated/escaped?
- [ ] No SQL/command injection vectors?
- [ ] Auth/authz applied correctly?
- [ ] No sensitive data in error messages?
- [ ] No known-vulnerable dependencies?
