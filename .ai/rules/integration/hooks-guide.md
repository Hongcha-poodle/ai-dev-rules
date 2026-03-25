# Harness Hooks Guide

Automate quality gates and workflows using Claude Code hooks in `settings.json`.

## Hook Events

| Event | Fires | Matcher target | Use case |
|---|---|---|---|
| `PreToolUse` | Before tool execution | Tool name | Block dangerous commands, validate input |
| `PostToolUse` | After tool execution | Tool name | Auto lint/typecheck, verify results |
| `PostToolUseFailure` | After tool failure | Tool name | Error recovery |
| `Notification` | On notification | Notification type | External system integration |
| `Stop` | Agent response complete | — | Final verification, summary |
| `SubagentStart` | Subagent spawned | Agent type | Tracking |
| `SubagentStop` | Subagent finished | Agent type | Result validation |
| `UserPromptSubmit` | User submits prompt | — | Input validation |

## Exit Code Behavior

| Exit code | Effect |
|---|---|
| `0` | Success — action proceeds. stdout parsed for JSON output. |
| `2` | **Block** — action is blocked. stderr is shown to Claude as feedback. |
| Other (1, 3, ...) | Action proceeds. stderr logged only (visible in verbose mode). |

**Only exit code 2 blocks.** Exit 1 does NOT block.

## Configuration Files

```
~/.claude/settings.json           # Global (all projects)
.claude/settings.json             # Per-project (git-tracked)
.claude/settings.local.json       # Local only (git-ignored)
```

Resolution order: user → project → local → managed → plugin. Project settings override global.

## Hook JSON Structure

Every hook entry requires a `hooks` array with `type` specified:

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "regex_pattern",
        "hooks": [
          {
            "type": "command",
            "command": "your-command-here",
            "timeout": 600
          }
        ]
      }
    ]
  }
}
```

- `matcher`: **Regex pattern** against tool name. `""` or omitted = match all.
- `hooks`: Array of hook actions. Each needs `type: "command"`.
- `timeout`: Seconds (default 600).

## Hook Input (stdin JSON)

Hooks receive context via **stdin**, not environment variables. Parse with `jq`:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/dir",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": { "command": "rm -rf /", "description": "..." }
}
```

Available env vars: `$CLAUDE_PROJECT_DIR`, `$CLAUDE_ENV_FILE` (SessionStart only).

## Quality Gate Automation

### Auto lint after file edits
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npm run lint --fix 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

### Auto typecheck after edits
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npx tsc --noEmit 2>&1 | head -20"
          }
        ]
      }
    ]
  }
}
```

### Block dangerous commands
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "INPUT=$(cat); CMD=$(echo \"$INPUT\" | jq -r '.tool_input.command // empty'); echo \"$CMD\" | grep -qE '(rm -rf|git push --force|git reset --hard)' && echo 'BLOCK: destructive command' >&2 && exit 2 || exit 0"
          }
        ]
      }
    ]
  }
}
```

### Quality summary on completion
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '=== Quality Summary ===' && npm run lint 2>&1 | tail -5 && npm test 2>&1 | tail -10"
          }
        ]
      }
    ]
  }
}
```

## Language-Specific Hooks

### Go
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "gofmt -l . 2>/dev/null | head -5; go vet ./... 2>&1 | head -10"
          }
        ]
      }
    ]
  }
}
```

### Python
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "ruff check --fix . 2>/dev/null; mypy . --no-error-summary 2>&1 | head -10"
          }
        ]
      }
    ]
  }
}
```

## Integration with quality.yaml

- `quality.yaml` → defines thresholds (errors: 0, coverage_min: 80)
- `hooks` → enforces thresholds automatically

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "npm test -- --coverage 2>&1 | grep -E 'Statements|Branches|Functions|Lines' | head -4"
          }
        ]
      }
    ]
  }
}
```

## Loop Detection Hook

Detect doom loops where the agent repeatedly edits the same file without progress. Track via a counter file:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "INPUT=$(cat); FILE=$(echo \"$INPUT\" | jq -r '.tool_input.file_path // empty'); HASH=$(printf '%s' \"$FILE\" | cksum | cut -d' ' -f1); COUNTER=\"/tmp/claude-edit-counter-$HASH\"; COUNT=$(cat \"$COUNTER\" 2>/dev/null || echo 0); COUNT=$((COUNT+1)); echo $COUNT > \"$COUNTER\"; if [ $COUNT -ge 4 ]; then echo \"LOOP DETECTED: $FILE edited $COUNT times. Stop and reassess approach.\" >&2; rm -f \"$COUNTER\"; fi"
          }
        ]
      }
    ]
  }
}
```

Reset counters at session start or when the agent completes successfully.

## Pre-Completion Self-Check Hook

Run quality gates automatically before the agent finishes, surfacing failures as feedback:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "ERRORS=0; LINT=$(npm run lint 2>&1 | tail -5); if echo \"$LINT\" | grep -qiE 'error|warning'; then ERRORS=1; fi; TYPE=$(npx tsc --noEmit 2>&1 | tail -10); if echo \"$TYPE\" | grep -qiE 'error'; then ERRORS=1; fi; TEST=$(npm test 2>&1 | tail -10); if echo \"$TEST\" | grep -qiE 'fail'; then ERRORS=1; fi; echo \"=== Pre-Completion Check ===\"; echo \"$LINT\"; echo \"$TYPE\"; echo \"$TEST\"; if [ $ERRORS -eq 1 ]; then echo 'BLOCK: quality gates not passed — fix before completing' >&2; exit 2; fi; exit 0"
          }
        ]
      }
    ]
  }
}
```

This hook **blocks completion** (exit 2) if lint, typecheck, or tests fail, forcing the agent to fix issues before finishing.

> **Note**: The example above uses npm/tsc commands. Adapt to your project's toolchain (e.g., `ruff check` + `mypy` + `pytest` for Python, `golangci-lint run` + `go test ./...` for Go). See Language-Specific Hooks above for per-language examples.

## Permission Pairing

Allow quality tools to run without prompts:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run lint *)",
      "Bash(npm test *)",
      "Bash(npx tsc *)"
    ]
  }
}
```

Permission evaluation order: **deny → ask → allow** (first match wins).

Path syntax:
- `//path` — absolute filesystem path
- `~/path` — home directory
- `/path` — project root relative
- `./path` or `path` — current directory relative

## Rules
- **Only exit code 2 blocks** tool calls. Other non-zero codes log but proceed.
- Matcher is a **regex** pattern (e.g., `Edit|Write`, `Bash`, `mcp__.*`).
- Hook input arrives via **stdin JSON**, not environment variables.
- Keep hook commands fast (<5s) to avoid workflow delays.
- No sensitive data in hook output.
- Add `settings.local.json` to `.gitignore`.

## Checklist
- [ ] Lint/typecheck hooks configured for project language?
- [ ] PreToolUse guard for destructive commands?
- [ ] Hook commands use stdin JSON parsing (not $TOOL_INPUT)?
- [ ] Blocking hooks use `exit 2` (not `exit 1`)?
- [ ] Hook commands execute within 5 seconds?
- [ ] Permissions aligned with hooks?
- [ ] `settings.local.json` in `.gitignore`?
