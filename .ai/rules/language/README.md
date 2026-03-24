# Language-Specific Rules

Referenced by `core.md` §4.

## File naming
```
.ai/rules/language/
├── _template.md    # Template for new language rules
├── go.md           # Go rules (example)
├── python.md       # Python rules (example)
├── typescript.md   # TypeScript/JavaScript rules (example)
└── ...             # Copy _template.md for additional languages
```

## Adding a new language
1. Copy `_template.md` → `{language}.md`
2. Fill placeholders (`{...}`) with actual values
3. Orchestrator auto-loads when the language is detected

## Required content per file
- Build/run commands
- Test commands and conventions
- Formatter and linter setup
- Language-specific pitfalls
