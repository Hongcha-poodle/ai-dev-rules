from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
ERRORS: list[str] = []

ROOT_RELATIVE_PREFIXES = (
    ".ai/",
    ".agent/",
    ".claude/",
    ".github/",
    "app/",
    "components/",
    "docs/",
    "fixtures/",
    "lib/",
    "pages/",
    "scripts/",
    "src/",
    "templates/",
    "tests/",
)

OPTIONAL_ARTIFACT_PREFIXES = (
    "_workspace/",
)

ROOT_FILES = {
    "AGENTS.md",
    "CLAUDE.md",
    "README.md",
    "package.json",
    "pyproject.toml",
    "go.mod",
    "tsconfig.json",
}


def report(message: str) -> None:
    ERRORS.append(message)


def markdown_files() -> list[Path]:
    candidates: list[Path] = []
    for relative in ("README.md", "AGENTS.md", "CLAUDE.md", ".github/copilot-instructions.md", ".agent/rules/rules.md"):
        path = ROOT / relative
        if path.exists():
            candidates.append(path)

    for folder in (".claude", "docs"):
        base = ROOT / folder
        if base.exists():
            candidates.extend(base.rglob("*.md"))

    seen: set[Path] = set()
    unique: list[Path] = []
    for path in candidates:
        resolved = path.resolve()
        if resolved not in seen and resolved.is_file():
            unique.append(resolved)
            seen.add(resolved)
    return unique


def clean_reference(raw: str) -> str:
    token = unquote(raw.strip())
    token = token.strip("`'\"")
    if token.startswith("@"):
        token = token[1:]
    token = token.split("#", 1)[0]
    token = re.sub(r":\d+(?::\d+)?$", "", token)
    return token.rstrip(".,:;")


def is_probable_path(token: str) -> bool:
    if not token:
        return False
    if token.startswith(("http://", "https://", "mailto:", "#", "/")):
        return False
    if "://" in token:
        return False
    if any(marker in token for marker in ("{", "}", "*", "$", "|", "&&", "||", "...")):
        return False
    if any(ch.isspace() for ch in token):
        return False
    normalized = token.replace("\\", "/")
    if normalized.startswith(OPTIONAL_ARTIFACT_PREFIXES):
        return False
    if normalized in ROOT_FILES:
        return True
    if normalized.startswith(ROOT_RELATIVE_PREFIXES):
        return True
    if "/" in normalized and re.search(r"\.[A-Za-z0-9_-]+$", normalized):
        return True
    return False


def candidate_paths(token: str, origin: Path) -> list[Path]:
    normalized = token.replace("\\", "/")
    candidates: list[Path] = []

    if normalized.startswith(ROOT_RELATIVE_PREFIXES) or normalized in ROOT_FILES:
        candidates.append(ROOT / normalized)

    candidates.append(origin.parent / normalized)
    candidates.append(ROOT / normalized)
    return candidates


def exists_reference(token: str, origin: Path) -> bool:
    return any(path.exists() for path in candidate_paths(token, origin))


def is_planned_or_todo_line(line: str) -> bool:
    normalized = line.strip().lower()
    if "todo" in normalized:
        return True
    return bool(re.match(r"^[-*]\s+(?:\[[ x]\]\s+)?(add|create|wire|replace|propose|run)\b", normalized))


def check_reference(raw: str, origin: Path, line: str = "") -> None:
    token = clean_reference(raw)
    if not is_probable_path(token):
        return
    if line and is_planned_or_todo_line(line):
        return
    if not exists_reference(token, origin):
        try:
            display_origin = origin.relative_to(ROOT)
        except ValueError:
            display_origin = origin
        report(f"{display_origin}: missing referenced path -> {token}")


def audit_file(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    for line in text.splitlines():
        for match in re.findall(r"\[[^\]]+\]\(([^)]+)\)", line):
            check_reference(match, path, line)
        for match in re.findall(r"`([^`\n]+)`", line):
            check_reference(match, path, line)


def main() -> int:
    for path in markdown_files():
        audit_file(path)

    if ERRORS:
        for error in ERRORS:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("Harness audit passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
