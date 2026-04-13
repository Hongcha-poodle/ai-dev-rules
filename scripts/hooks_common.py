from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


def parse_hooks_intent(text: str) -> dict[str, dict[str, bool]]:
    hooks: dict[str, dict[str, bool]] = {}
    in_section = False
    current_group: str | None = None

    for raw_line in text.splitlines():
        line = raw_line.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue

        if not in_section:
            if line.startswith("hooks_intent:"):
                in_section = True
            continue

        if not raw_line.startswith("  "):
            break

        if re.match(r"^  [A-Za-z0-9_]+:\s*$", raw_line):
            current_group = raw_line.strip().rstrip(":")
            hooks[current_group] = {}
            continue

        if current_group and re.match(r"^    [A-Za-z0-9_]+:\s+(true|false)\s*$", raw_line):
            key, value = raw_line.strip().split(":", 1)
            hooks[current_group][key] = value.strip().lower() == "true"

    return hooks


def detect_language(repo_root: Path) -> str:
    if (repo_root / "package.json").exists():
        return "javascript"
    if (repo_root / "go.mod").exists():
        return "go"
    if any((repo_root / name).exists() for name in ("pyproject.toml", "requirements.txt", "setup.py", "tox.ini")):
        return "python"
    return "generic"


def command_profile(language: str) -> dict[str, str | list[str]]:
    destructive = (
        "INPUT=$(cat); "
        "CMD=$(echo \"$INPUT\" | jq -r '.tool_input.command // empty'); "
        "echo \"$CMD\" | grep -qE '(rm -rf|git push --force|git reset --hard)' "
        "&& echo 'BLOCK: destructive command' >&2 && exit 2 || exit 0"
    )

    common = {
        "block_destructive": destructive,
        "delivery_summary": "echo 'Delivery summary: verify smoke checks, rollback plan, and observability notes for risky changes.'",
        "harness_summary": "echo 'Harness summary: confirm docs/index.md, docs/harness/, and cleanup loop remain current.'",
    }

    if language == "javascript":
        return common | {
            "lint": "npm run lint 2>&1 | tail -20 || true",
            "typecheck": "npm run typecheck 2>&1 | tail -20 || npx tsc --noEmit 2>&1 | tail -20 || true",
            "impacted_tests": (
                "INPUT=$(cat); FILE=$(echo \"$INPUT\" | jq -r '.tool_input.file_path // empty'); "
                "if [ -n \"$FILE\" ]; then npm test -- --findRelatedTests \"$FILE\" 2>&1 | tail -20 || true; fi"
            ),
            "quality_summary": (
                "echo '=== Quality Summary ==='; "
                "npm run lint 2>&1 | tail -10 || true; "
                "npm run typecheck 2>&1 | tail -10 || npx tsc --noEmit 2>&1 | tail -10 || true; "
                "npm test 2>&1 | tail -10 || true"
            ),
            "coverage_report": "npm test -- --coverage 2>&1 | grep -E 'Statements|Branches|Functions|Lines' | head -4 || true",
            "permissions": [
                "Bash(npm run lint *)",
                "Bash(npm run typecheck *)",
                "Bash(npm test *)",
                "Bash(npx tsc *)",
            ],
        }

    if language == "go":
        return common | {
            "lint": "gofmt -l . 2>/dev/null | head -10; go vet ./... 2>&1 | tail -20 || true",
            "typecheck": "go test ./... 2>&1 | tail -20 || true",
            "impacted_tests": "go test ./... 2>&1 | tail -20 || true",
            "quality_summary": (
                "echo '=== Quality Summary ==='; "
                "gofmt -l . 2>/dev/null | head -10; "
                "go vet ./... 2>&1 | tail -10 || true; "
                "go test ./... 2>&1 | tail -10 || true"
            ),
            "coverage_report": "go test ./... -cover 2>&1 | tail -20 || true",
            "permissions": [
                "Bash(go vet *)",
                "Bash(go test *)",
                "Bash(gofmt *)",
            ],
        }

    if language == "python":
        return common | {
            "lint": "ruff check . 2>&1 | tail -20 || true",
            "typecheck": "mypy . --no-error-summary 2>&1 | tail -20 || true",
            "impacted_tests": "pytest -q 2>&1 | tail -20 || true",
            "quality_summary": (
                "echo '=== Quality Summary ==='; "
                "ruff check . 2>&1 | tail -10 || true; "
                "mypy . --no-error-summary 2>&1 | tail -10 || true; "
                "pytest -q 2>&1 | tail -10 || true"
            ),
            "coverage_report": "pytest --cov 2>&1 | tail -20 || true",
            "permissions": [
                "Bash(ruff check *)",
                "Bash(mypy *)",
                "Bash(pytest *)",
            ],
        }

    return common | {
        "lint": "echo 'TODO: configure lint command for this repository.'",
        "typecheck": "echo 'TODO: configure typecheck command for this repository.'",
        "impacted_tests": "echo 'TODO: configure impacted test command for this repository.'",
        "quality_summary": "echo 'TODO: configure quality summary commands for this repository.'",
        "coverage_report": "echo 'TODO: configure coverage command for this repository.'",
        "permissions": [],
    }


def build_hooks_settings(quality_path: Path) -> dict[str, Any]:
    repo_root = quality_path.parents[2]
    hooks_intent = parse_hooks_intent(quality_path.read_text(encoding="utf-8"))
    profile = command_profile(detect_language(repo_root))

    settings: dict[str, Any] = {"hooks": {}, "permissions": {"allow": list(profile["permissions"])}}

    post_edit_flags = hooks_intent.get("post_edit", {})
    post_edit_hooks = []
    for key in ("lint", "typecheck", "impacted_tests"):
        if post_edit_flags.get(key):
            post_edit_hooks.append({"type": "command", "command": profile[key], "timeout": 30})
    if post_edit_hooks:
        settings["hooks"]["PostToolUse"] = [{"matcher": "Edit|Write", "hooks": post_edit_hooks}]

    pre_bash_flags = hooks_intent.get("pre_bash", {})
    if pre_bash_flags.get("block_destructive"):
        settings["hooks"]["PreToolUse"] = [{
            "matcher": "Bash",
            "hooks": [{"type": "command", "command": profile["block_destructive"], "timeout": 10}],
        }]

    stop_flags = hooks_intent.get("on_stop", {})
    stop_hooks = []
    for key in ("coverage_report", "quality_summary", "delivery_summary", "harness_summary"):
        if stop_flags.get(key):
            stop_hooks.append({"type": "command", "command": profile[key], "timeout": 30})
    if stop_hooks:
        settings["hooks"]["Stop"] = [{"matcher": "", "hooks": stop_hooks}]

    return settings


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def merge_permission_allow(existing: list[Any], generated: list[Any]) -> list[Any]:
    merged: list[Any] = []
    seen: set[str] = set()
    for value in [*existing, *generated]:
        key = json.dumps(value, sort_keys=True)
        if key not in seen:
            merged.append(value)
            seen.add(key)
    return merged


def merge_hooks(existing: list[Any], generated: list[Any]) -> list[Any]:
    def signature(entry: Any) -> str:
        return str(entry.get("matcher", "")) if isinstance(entry, dict) else json.dumps(entry, sort_keys=True)

    existing_map = {signature(entry): entry for entry in existing if isinstance(entry, dict)}
    generated_signatures = [signature(entry) for entry in generated if isinstance(entry, dict)]
    merged = [entry for entry in existing if signature(entry) not in generated_signatures]
    merged.extend(generated)

    # Preserve non-dict entries and original ordering for unrelated hooks.
    if len(existing_map) == 0 and len(existing) == 0:
        return generated
    return merged


def apply_hooks_settings(existing: dict[str, Any], generated: dict[str, Any]) -> dict[str, Any]:
    merged = json.loads(json.dumps(existing))

    merged_hooks = merged.setdefault("hooks", {})
    for event, generated_entries in generated.get("hooks", {}).items():
        existing_entries = merged_hooks.get(event, [])
        if not isinstance(existing_entries, list):
            existing_entries = []
        merged_hooks[event] = merge_hooks(existing_entries, generated_entries)

    merged_permissions = merged.setdefault("permissions", {})
    existing_allow = merged_permissions.get("allow", [])
    if not isinstance(existing_allow, list):
        existing_allow = []
    merged_permissions["allow"] = merge_permission_allow(existing_allow, generated.get("permissions", {}).get("allow", []))

    return merged
