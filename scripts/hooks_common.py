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


def read_package_json(repo_root: Path) -> dict[str, Any]:
    package_path = repo_root / "package.json"
    if not package_path.exists():
        return {}
    try:
        payload = json.loads(package_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return payload if isinstance(payload, dict) else {}


def package_has(package_json: dict[str, Any], name: str) -> bool:
    for key in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
        values = package_json.get(key, {})
        if isinstance(values, dict) and name in values:
            return True
    return False


def detect_javascript_test_runner(repo_root: Path) -> str | None:
    package_json = read_package_json(repo_root)
    scripts = package_json.get("scripts", {})
    scripts_text = " ".join(value for value in scripts.values() if isinstance(value, str)) if isinstance(scripts, dict) else ""

    if package_has(package_json, "vitest") or re.search(r"(^|[^A-Za-z0-9_-])vitest([^A-Za-z0-9_-]|$)", scripts_text):
        return "vitest"
    if package_has(package_json, "jest") or re.search(r"(^|[^A-Za-z0-9_-])jest([^A-Za-z0-9_-]|$)", scripts_text):
        return "jest"
    return None


def hook_runner(*args: str) -> str:
    return " ".join(["node", "scripts/hook-runner.mjs", *args])


def command_profile(language: str, repo_root: Path) -> dict[str, str | list[str] | None]:
    javascript_test_runner = detect_javascript_test_runner(repo_root) if language == "javascript" else None

    common = {
        "block_destructive": hook_runner("pre-bash", "block-destructive"),
        "delivery_summary": hook_runner("stop", "delivery-summary"),
        "harness_summary": hook_runner("stop", "harness-summary"),
    }

    if language == "javascript":
        impacted_tests = (
            hook_runner("post-edit", "impacted-tests", javascript_test_runner)
            if javascript_test_runner
            else None
        )
        return common | {
            "lint": hook_runner("post-edit", "lint"),
            "typecheck": hook_runner("post-edit", "typecheck"),
            "impacted_tests": impacted_tests,
            "quality_summary": hook_runner("stop", "quality-summary"),
            "coverage_report": hook_runner("stop", "coverage-report"),
            "permissions": [
                "Bash(node scripts/hook-runner.mjs *)",
                "Bash(npm run lint *)",
                "Bash(npm run typecheck *)",
                "Bash(npm test *)",
                "Bash(npx tsc *)",
                "Bash(npx vitest *)",
                "Bash(npx jest *)",
            ],
        }

    if language == "go":
        return common | {
            "lint": hook_runner("post-edit", "lint"),
            "typecheck": hook_runner("post-edit", "typecheck"),
            "impacted_tests": hook_runner("post-edit", "impacted-tests"),
            "quality_summary": hook_runner("stop", "quality-summary"),
            "coverage_report": hook_runner("stop", "coverage-report"),
            "permissions": [
                "Bash(node scripts/hook-runner.mjs *)",
                "Bash(go vet *)",
                "Bash(go test *)",
                "Bash(gofmt *)",
            ],
        }

    if language == "python":
        return common | {
            "lint": hook_runner("post-edit", "lint"),
            "typecheck": hook_runner("post-edit", "typecheck"),
            "impacted_tests": hook_runner("post-edit", "impacted-tests"),
            "quality_summary": hook_runner("stop", "quality-summary"),
            "coverage_report": hook_runner("stop", "coverage-report"),
            "permissions": [
                "Bash(node scripts/hook-runner.mjs *)",
                "Bash(ruff check *)",
                "Bash(mypy *)",
                "Bash(pytest *)",
            ],
        }

    return common | {
        "lint": hook_runner("post-edit", "lint"),
        "typecheck": hook_runner("post-edit", "typecheck"),
        "impacted_tests": hook_runner("post-edit", "impacted-tests"),
        "quality_summary": hook_runner("stop", "quality-summary"),
        "coverage_report": hook_runner("stop", "coverage-report"),
        "permissions": ["Bash(node scripts/hook-runner.mjs *)"],
    }


def build_hooks_settings(quality_path: Path) -> dict[str, Any]:
    repo_root = quality_path.parents[2]
    hooks_intent = parse_hooks_intent(quality_path.read_text(encoding="utf-8"))
    profile = command_profile(detect_language(repo_root), repo_root)

    settings: dict[str, Any] = {"hooks": {}, "permissions": {"allow": list(profile["permissions"])}}

    post_edit_flags = hooks_intent.get("post_edit", {})
    post_edit_hooks = []
    for key in ("lint", "typecheck", "impacted_tests"):
        command = profile.get(key)
        if post_edit_flags.get(key) and isinstance(command, str):
            post_edit_hooks.append({"type": "command", "command": command, "timeout": 30})
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
        command = profile.get(key)
        if stop_flags.get(key) and isinstance(command, str):
            stop_hooks.append({"type": "command", "command": command, "timeout": 30})
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
