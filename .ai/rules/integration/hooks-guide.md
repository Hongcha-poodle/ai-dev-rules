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

Hooks receive context via **stdin**, not environment variables. Prefer parsing that JSON in a repo script instead of shell one-liners:

```json
{
  "type": "command",
  "command": "node scripts/hook-runner.mjs post-edit lint"
}
```

The generated `scripts/hook-runner.mjs` reads stdin JSON directly, so hook commands do not need `cat`, `jq`, `grep`, `tail`, or shell redirection. The hook input shape is:

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
            "command": "node scripts/hook-runner.mjs post-edit lint"
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
            "command": "node scripts/hook-runner.mjs post-edit typecheck"
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
            "command": "node scripts/hook-runner.mjs pre-bash block-destructive"
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
            "command": "node scripts/hook-runner.mjs stop quality-summary"
          }
        ]
      }
    ]
  }
}
```

## Language-Specific Hooks

`scripts/generate-hooks.py` chooses a profile from the repository surface:
- `package.json` → JavaScript / TypeScript
- `go.mod` → Go
- `pyproject.toml`, `requirements.txt`, `setup.py`, or `tox.ini` → Python

For JavaScript impacted tests, the generator inspects `package.json`:
- `vitest` dependency or script → `node scripts/hook-runner.mjs post-edit impacted-tests vitest`, which runs `vitest related <file> --run`
- `jest` dependency or script → `node scripts/hook-runner.mjs post-edit impacted-tests jest`, which runs `jest --findRelatedTests <file>` or the existing `npm test -- --findRelatedTests <file>` fallback
- unknown runner → no impacted-test hook is generated; use the Stop quality summary or add a repository-specific command

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
            "command": "node scripts/hook-runner.mjs post-edit lint"
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
            "command": "node scripts/hook-runner.mjs post-edit lint"
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
- `scripts/generate-hooks.sh` → materializes `hooks_intent` into a starter `.claude/settings.json`
- `scripts/apply-hooks.sh` → merges generated hooks into an existing `.claude/settings.json`
- On Windows / PowerShell, prefer `py -3 scripts/generate-hooks.py ...` when `py` exists
- If the project uses `uv`, prefer `uv run python scripts/generate-hooks.py ...`
- Otherwise install Python or skip hook generation

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "node scripts/hook-runner.mjs stop coverage-report"
          }
        ]
      }
    ]
  }
}
```

## Loop Detection Hook

Detect loops where the agent repeatedly edits the same file without progress. Prefer adding a small action to `scripts/hook-runner.mjs` or another repo script so the counter logic remains portable. If you keep this as a shell one-liner, mark it POSIX-only and do not ship it as the default Windows hook template.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "node scripts/hook-runner.mjs post-edit loop-detect"
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
            "command": "node scripts/hook-runner.mjs stop quality-summary"
          }
        ]
      }
    ]
  }
}
```

Use a dedicated blocking action in the runner when you want this hook to block completion with exit code 2. The default generated quality summary is informational and does not block, preserving the previous `|| true` behavior.

> **Note**: Adapt blocking behavior to your project's toolchain and risk tolerance. See Language-Specific Hooks above for per-language examples.

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

## Troubleshooting

### `spawn EPERM`
- Usually means the hook command cannot be executed by the current OS/shell.
- Prefer `node scripts/hook-runner.mjs ...` or another repo script over shell-specific one-liners.
- Verify the executable is on PATH and, on Windows, avoid relying on broken `python.exe` aliases.

### `/_error` warning during Next.js checks
- Treat as a framework/build warning until a reproducible user-facing failure is observed.
- Re-run the focused command once, then inspect build output and route-level errors if it persists.

### `EBUSY: resource busy or locked, unlink '.next/export/404.html'`
- On Windows this commonly means a dev server, watcher, editor extension, or Node process still holds a file lock.
- Stop the dev server or related Node processes, retry the command once, and only investigate lock holders if it repeats.
- If the retry passes and no source code changed, record it as transient file locking rather than a regression.

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
- [ ] Hook commands use repo scripts rather than POSIX-only `jq`/`grep`/`tail` one-liners?
- [ ] Blocking hooks use `exit 2` (not `exit 1`)?
- [ ] Hook commands execute within 5 seconds?
- [ ] Permissions aligned with hooks?
- [ ] `settings.local.json` in `.gitignore`?
- [ ] After editing `settings.json`, reloaded the session (`/exit` → `claude --resume`)? Hooks are read at session start only.
