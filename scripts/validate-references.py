from __future__ import annotations

import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
errors: list[str] = []


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def fail(message: str) -> None:
    errors.append(message)


def path_exists(candidate: str, origin: Path) -> bool:
    token = candidate.strip().strip("`")
    token = token.split("#", 1)[0]
    token = token.rstrip(".,:")

    if not token or "://" in token or token.startswith("mailto:"):
        return True

    if token == ".ai/rules/language/{lang}.md":
        return (root / ".ai/rules/language/_template.md").exists()

    if any(marker in token for marker in ("{lang}", "{tool}", "{name}", "{skill}", "{agent}", "{path}", "{file}", "{command}")):
        return True

    attempts: list[Path] = []
    if token.startswith((".ai/", "docs/", ".claude/", "_workspace/", "fixtures/", "templates/", "scripts/", ".github/", ".agent/")):
        attempts.append(root / token)

    current = origin.parent
    while True:
        attempts.append(current / token)
        if current == root:
            break
        if root not in current.parents and current != root:
            break
        current = current.parent

    for attempt in attempts:
        if attempt.exists():
            return True

    return False


def validate_core_context_loading() -> None:
    core_path = root / ".ai/core.md"
    text = read_text(core_path)
    marker = "## §6. Context Loading"
    next_marker = "\n## "
    start = text.find(marker)
    if start == -1:
        fail(f"{core_path}: missing Context Loading section")
        return
    end = text.find(next_marker, start + len(marker))
    section = text[start:end if end != -1 else None]

    files: set[str] = set()
    for line in section.splitlines():
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.split("|")[1:-1]]
        if len(cells) != 2:
            continue
        trigger, file_ref = cells
        if trigger == "Trigger" or set(trigger) == {"-"}:
            continue
        files.add(file_ref)
        if not path_exists(file_ref, core_path):
            fail(f"{core_path}: missing file referenced in Context Loading -> {file_ref}")

    expected = {
        ".ai/rules/security/security-guide.md",
        ".ai/rules/architecture/architecture-guide.md",
        ".ai/rules/testing/testing-guide.md",
        ".ai/rules/development/agent-authoring.md",
        ".ai/rules/integration/mcp-integration.md",
        ".ai/rules/integration/hooks-guide.md",
        ".ai/rules/workflow/harness-engineering.md",
        ".ai/skills/harness/SKILL.md",
        ".ai/rules/language/{lang}.md",
        ".ai/rules/workflow/spec-workflow.md",
        ".ai/rules/workflow/long-running-guide.md",
        ".ai/rules/workflow/team-workflow.md",
    }
    if files != expected:
        missing = sorted(expected - files)
        extra = sorted(files - expected)
        if missing:
            fail(f"{core_path}: missing Context Loading rows -> {', '.join(missing)}")
        if extra:
            fail(f"{core_path}: unexpected Context Loading rows -> {', '.join(extra)}")


def validate_entrypoints() -> None:
    expectations = {
        "claude.md": {
            "required": {
                ".ai/rules/architecture/architecture-guide.md",
                ".ai/rules/security/security-guide.md",
                ".ai/rules/testing/testing-guide.md",
                ".ai/rules/development/agent-authoring.md",
                ".ai/rules/integration/mcp-integration.md",
                ".ai/rules/integration/hooks-guide.md",
                ".ai/rules/workflow/harness-engineering.md",
                ".ai/skills/harness/SKILL.md",
                ".ai/rules/language/{lang}.md",
                ".ai/rules/workflow/spec-workflow.md",
                ".ai/rules/workflow/long-running-guide.md",
                ".ai/rules/workflow/team-workflow.md",
            },
            "forbidden": set(),
        },
        "copilot.md": {
            "required": {
                ".ai/rules/architecture/architecture-guide.md",
                ".ai/rules/security/security-guide.md",
                ".ai/rules/testing/testing-guide.md",
                ".ai/rules/development/agent-authoring.md",
                ".ai/rules/workflow/harness-engineering.md",
                ".ai/skills/harness/SKILL.md",
                ".ai/rules/language/{lang}.md",
                ".ai/rules/workflow/spec-workflow.md",
                ".ai/rules/workflow/long-running-guide.md",
                ".ai/rules/workflow/team-workflow.md",
            },
            "forbidden": {
                ".ai/rules/integration/hooks-guide.md",
            },
        },
        "codex.md": {
            "required": {
                ".ai/rules/architecture/architecture-guide.md",
                ".ai/rules/security/security-guide.md",
                ".ai/rules/testing/testing-guide.md",
                ".ai/rules/development/agent-authoring.md",
                ".ai/rules/workflow/harness-engineering.md",
                ".ai/skills/harness/SKILL.md",
                ".ai/rules/language/{lang}.md",
                ".ai/rules/workflow/spec-workflow.md",
                ".ai/rules/workflow/long-running-guide.md",
                ".ai/rules/workflow/team-workflow.md",
            },
            "forbidden": {
                ".ai/rules/integration/hooks-guide.md",
            },
        },
        "antigravity.md": {
            "required": {
                ".ai/rules/architecture/architecture-guide.md",
                ".ai/rules/security/security-guide.md",
                ".ai/rules/testing/testing-guide.md",
                ".ai/rules/development/agent-authoring.md",
                ".ai/rules/workflow/harness-engineering.md",
                ".ai/skills/harness/SKILL.md",
                ".ai/rules/language/{lang}.md",
                ".ai/rules/workflow/spec-workflow.md",
                ".ai/rules/workflow/long-running-guide.md",
                ".ai/rules/workflow/team-workflow.md",
            },
            "forbidden": {
                ".ai/rules/integration/hooks-guide.md",
            },
        },
    }

    for name, rules in expectations.items():
        path = root / ".ai/entry-points" / name
        text = read_text(path)
        for required in sorted(rules["required"]):
            if required not in text:
                fail(f"{path}: missing required reference -> {required}")
        for forbidden in sorted(rules["forbidden"]):
            if forbidden in text:
                fail(f"{path}: forbidden reference present -> {forbidden}")


def validate_skill_references() -> None:
    skill_path = root / ".ai/skills/harness/SKILL.md"
    text = read_text(skill_path)
    matches = re.findall(r"`((?:references|templates)/[^`\n]+)`", text)
    for match in matches:
        target = skill_path.parent / match
        if not target.exists():
            fail(f"{skill_path}: missing referenced skill asset -> {match}")


def validate_markdown_links() -> None:
    markdown_paths = list(root.glob("README.md"))
    markdown_paths += list((root / ".ai").rglob("*.md"))
    markdown_paths += list((root / "fixtures").rglob("*.md"))

    link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
    inline_pattern = re.compile(r"`([^`\n]+)`")

    for path in markdown_paths:
        text = read_text(path)

        for candidate in link_pattern.findall(text):
            cleaned = candidate.strip()
            if cleaned.startswith(("http://", "https://", "mailto:", "#")):
                continue
            if not path_exists(cleaned, path):
                fail(f"{path}: broken markdown link -> {cleaned}")

        if path == root / "README.md" or path == root / ".ai/core.md" or path.parent == root / ".ai/entry-points" or path == root / ".ai/skills/harness/SKILL.md":
            for candidate in inline_pattern.findall(text):
                token = candidate.strip()
                if any(ch in token for ch in (" ", ">", ";", "|", "(", ")")):
                    continue
                if "/" not in token and not token.endswith((".md", ".json", ".yaml", ".yml", ".sh", ".py", ".ps1")):
                    continue
                if token.startswith(("http://", "https://")):
                    continue
                if not path_exists(token, path):
                    fail(f"{path}: broken inline path reference -> {token}")


validate_core_context_loading()
validate_entrypoints()
validate_skill_references()
validate_markdown_links()

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)

print("Reference validation passed.")
