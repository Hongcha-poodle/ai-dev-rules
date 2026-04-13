#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_file() {
  local target="$1"
  if [[ ! -e "$ROOT_DIR/$target" ]]; then
    echo "Missing required artifact: $target" >&2
    exit 1
  fi
}

require_text() {
  local target="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -qE "$pattern" "$ROOT_DIR/$target"; then
    echo "Missing expected content in $target: $description" >&2
    exit 1
  fi
}

# 1. Entry point updates
require_file "AGENTS.md"
require_file "CLAUDE.md"
require_text "AGENTS.md" "docs/harness/overview.md" "AGENTS.md should point to durable harness docs"
require_text "CLAUDE.md" "docs/harness/commands.md" "CLAUDE.md should point to verification commands"

# 2. Durable docs
require_file "docs/index.md"
require_file "docs/harness/overview.md"
require_file "docs/harness/commands.md"
require_file "docs/harness/validation.md"
require_file "docs/plans/active/harness-bootstrap.md"
require_text "docs/harness/overview.md" "Producer-Reviewer" "overview should record orchestration pattern"
require_text "docs/harness/overview.md" "Known Gaps" "overview should track known gaps"

# 3. Verification contract
require_text "docs/harness/commands.md" "npm run lint" "lint command"
require_text "docs/harness/commands.md" "npm run typecheck" "typecheck command"
require_text "docs/harness/commands.md" "npm run test" "unit test command"
require_text "docs/harness/commands.md" "npm run test:integration" "integration test command"
require_text "docs/harness/commands.md" "npm run test:e2e" "e2e command"
require_text "docs/harness/commands.md" "npm run build" "build command"

# 4. Review separation
require_file ".claude/agents/frontend-dev.md"
require_file ".claude/agents/backend-dev.md"
require_file ".claude/agents/qa-engineer.md"
require_file ".claude/agents/release-engineer.md"
require_text ".claude/agents/qa-engineer.md" "Verify changed behavior independently" "QA role must be independent"
require_text ".claude/skills/streamboard-harness/skill.md" "Route verification to `qa-engineer`" "skill should preserve review separation"

# 5. Drift control
require_file "_workspace/.gitkeep"
require_text "docs/plans/active/harness-bootstrap.md" "TODO" "bootstrap plan should keep remaining cleanup work visible"
require_text "docs/harness/validation.md" "Remaining TODOs" "validation doc should capture drift follow-ups"

echo "Harness fixture validation passed."
