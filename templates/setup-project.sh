#!/usr/bin/env bash
# setup-project.sh
# GitHub에서 ai-dev-rules를 다운로드하여 현재 프로젝트에 설정하는 스크립트
#
# 사용법:
#   bash <(curl -fsSL "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.sh")

set -euo pipefail

REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main}"
PROJECT_PATH="$(pwd)"
install_copilot=false
install_claude=false
install_antigravity=false
install_codex=false

normalize_choice() {
  local normalized="${1,,}"
  case "$normalized" in
    1|copilot|github-copilot|vscode) echo "1" ;;
    2|claude|claude-code) echo "2" ;;
    3|antigravity|google-antigravity) echo "3" ;;
    4|codex|openai-codex) echo "4" ;;
    5|all) echo "5" ;;
    *) echo "" ;;
  esac
}

echo "AI Dev Rules 셋업을 시작합니다..."
echo "대상 프로젝트: $PROJECT_PATH"

# --- 0. AI 도구 선택 ---
choice=""

if [[ -n "${AI_TOOL:-}" ]]; then
  choice="$(normalize_choice "${AI_TOOL}")"
  if [[ -z "$choice" ]]; then
    echo "지원하지 않는 AI_TOOL 값입니다: ${AI_TOOL}" >&2
    exit 1
  fi
else
  echo "========================================"
  echo "어떤 AI 개발 도구를 사용하시겠습니까?"
  echo "1. VS Code (GitHub Copilot)"
  echo "2. Claude Code"
  echo "3. Google Antigravity"
  echo "4. OpenAI Codex"
  echo "5. 모두 설치"
  echo "========================================"

  if [[ -t 0 ]]; then
    read -r -p "번호를 선택하세요 (1-5): " choice
  else
    echo "비대화형 모드에서는 AI_TOOL 환경 변수를 설정해야 합니다. 예: AI_TOOL=claude" >&2
    exit 1
  fi
fi

case "$choice" in
  1) install_copilot=true ;;
  2) install_claude=true ;;
  3) install_antigravity=true ;;
  4) install_codex=true ;;
  5) install_copilot=true; install_claude=true; install_antigravity=true; install_codex=true ;;
  *)
    echo "잘못된 선택입니다. 스크립트를 종료합니다." >&2
    exit 1
    ;;
esac

# --- 1. 파일 다운로드 함수 ---
download_file() {
  local remote_path="$1"
  local local_path="$2"

  local dest_dir
  dest_dir="$(dirname "$local_path")"
  mkdir -p "$dest_dir"

  local url="$REPO_URL/$remote_path"
  local attempt
  for attempt in 1 2 3; do
    if curl -fsSL "$url" -o "$local_path"; then
      if [[ "$local_path" == *.sh ]]; then
        chmod +x "$local_path"
      fi
      echo "✔ 다운로드 완료: $local_path"
      return 0
    fi
    echo "⚠ 다운로드 실패 (시도 $attempt/3): $url" >&2
    sleep 1
  done

  echo "✖ 다운로드 최종 실패: $url" >&2
  exit 1
}

# --- 2. .ai 폴더 및 핵심 규칙 다운로드 ---
AI_DIR="$PROJECT_PATH/.ai"
mkdir -p "$AI_DIR"

echo ""
echo "[핵심 규칙 다운로드]"
download_file ".ai/core.md" "$AI_DIR/core.md"

# config
download_file ".ai/config/quality.yaml" "$AI_DIR/config/quality.yaml"

# rules
rules=(
  "architecture/architecture-guide.md"
  "development/agent-authoring.md"
  "integration/mcp-integration.md"
  "integration/hooks-guide.md"
  "security/security-guide.md"
  "testing/testing-guide.md"
  "workflow/harness-engineering.md"
  "workflow/long-running-guide.md"
  "workflow/spec-workflow.md"
  "workflow/team-workflow.md"
)

for rule in "${rules[@]}"; do
  download_file ".ai/rules/$rule" "$AI_DIR/rules/$rule"
done

# language rules
download_file ".ai/rules/language/README.md" "$AI_DIR/rules/language/README.md"
download_file ".ai/rules/language/_template.md" "$AI_DIR/rules/language/_template.md"
download_file ".ai/rules/language/typescript.md" "$AI_DIR/rules/language/typescript.md"

# skills
download_file ".ai/skills/README.md" "$AI_DIR/skills/README.md"
download_file ".ai/skills/harness/SKILL.md" "$AI_DIR/skills/harness/SKILL.md"
download_file ".ai/skills/harness/templates/README.md" "$AI_DIR/skills/harness/templates/README.md"
download_file ".ai/skills/harness/templates/fullstack-app-starter.md" "$AI_DIR/skills/harness/templates/fullstack-app-starter.md"
download_file ".ai/skills/harness/templates/code-review-starter.md" "$AI_DIR/skills/harness/templates/code-review-starter.md"
download_file ".ai/skills/harness/templates/research-content-starter.md" "$AI_DIR/skills/harness/templates/research-content-starter.md"
download_file ".ai/skills/harness/references/pattern-selection.md" "$AI_DIR/skills/harness/references/pattern-selection.md"
download_file ".ai/skills/harness/references/output-contract.md" "$AI_DIR/skills/harness/references/output-contract.md"
download_file ".ai/skills/harness/references/harness-100-template-pack.md" "$AI_DIR/skills/harness/references/harness-100-template-pack.md"

# scripts
download_file "scripts/apply-hooks.sh" "$PROJECT_PATH/scripts/apply-hooks.sh"
download_file "scripts/apply-hooks.py" "$PROJECT_PATH/scripts/apply-hooks.py"
download_file "scripts/generate-hooks.sh" "$PROJECT_PATH/scripts/generate-hooks.sh"
download_file "scripts/generate-hooks.py" "$PROJECT_PATH/scripts/generate-hooks.py"
download_file "scripts/hooks_common.py" "$PROJECT_PATH/scripts/hooks_common.py"

# entry-points (managed templates — always overwritten for updates)
entry_points=(
  "entry-points/claude.md"
  "entry-points/copilot.md"
  "entry-points/antigravity.md"
  "entry-points/codex.md"
)
for ep in "${entry_points[@]}"; do
  download_file ".ai/$ep" "$AI_DIR/$ep"
done

# --- 2.5 권장 docs/ 구조 생성 ---
echo ""
echo "[권장 docs 구조 생성]"
mkdir -p \
  "$PROJECT_PATH/docs/architecture" \
  "$PROJECT_PATH/docs/plans/active" \
  "$PROJECT_PATH/docs/plans/completed" \
  "$PROJECT_PATH/docs/product" \
  "$PROJECT_PATH/docs/references" \
  "$PROJECT_PATH/docs/reliability" \
  "$PROJECT_PATH/docs/security" \
  "$PROJECT_PATH/docs/generated"

[ -f "$PROJECT_PATH/docs/index.md" ] || cat > "$PROJECT_PATH/docs/index.md" << 'DOCSEOF'
# Docs Index

- architecture/
- plans/active/
- plans/completed/
- product/
- references/
- reliability/
- security/
- generated/
DOCSEOF

[ -f "$PROJECT_PATH/docs/architecture/README.md" ] || printf '# Architecture\n\n핵심 구조와 변경 이유를 기록합니다.\n' > "$PROJECT_PATH/docs/architecture/README.md"
[ -f "$PROJECT_PATH/docs/product/README.md" ] || printf '# Product\n\n제품 요구사항과 사용자 흐름을 기록합니다.\n' > "$PROJECT_PATH/docs/product/README.md"
[ -f "$PROJECT_PATH/docs/references/README.md" ] || printf '# References\n\n에이전트가 참조해야 하는 외부 기술 문서를 요약/정리합니다.\n' > "$PROJECT_PATH/docs/references/README.md"
[ -f "$PROJECT_PATH/docs/reliability/README.md" ] || printf '# Reliability\n\n로그, 메트릭, 추적, 운영 체크리스트를 기록합니다.\n' > "$PROJECT_PATH/docs/reliability/README.md"
[ -f "$PROJECT_PATH/docs/security/README.md" ] || printf '# Security\n\n위험 모델, 보안 가드레일, 검토 결과를 기록합니다.\n' > "$PROJECT_PATH/docs/security/README.md"
[ -f "$PROJECT_PATH/docs/generated/README.md" ] || printf '# Generated\n\nDB schema, API surface 등 생성 산출물을 보관합니다.\n' > "$PROJECT_PATH/docs/generated/README.md"
[ -f "$PROJECT_PATH/docs/plans/active/.gitkeep" ] || : > "$PROJECT_PATH/docs/plans/active/.gitkeep"
[ -f "$PROJECT_PATH/docs/plans/completed/.gitkeep" ] || : > "$PROJECT_PATH/docs/plans/completed/.gitkeep"

# --- 3. 각 도구별 진입점 생성 (core.md 참조) ---
echo ""
echo "[진입점 파일 생성]"

create_entry_point() {
  local tool_name="$1"
  local local_path="$2"
  local managed_ref="$3"

  local dest_dir
  dest_dir="$(dirname "$local_path")"
  mkdir -p "$dest_dir"

  if [ -f "$local_path" ]; then
    echo "ℹ 진입점 파일이 이미 존재합니다 (건너뜀): $local_path"
    echo "  → 관리 영역은 $managed_ref 에서 자동 업데이트됩니다."
    return
  fi

  cat > "$local_path" << EOF
# $tool_name Instructions

> **CRITICAL**: Keep this file short and map-oriented. Durable project knowledge belongs in versioned docs under \`docs/\` and rules under \`.ai/\`.
> Before executing any task, you MUST read the following files in order:
> 1. \`.ai/core.md\` — global AI rules
> 2. \`$managed_ref\` — managed configuration (auto-updated)

---
## Project Specific Instructions
(Add only high-signal routing guidance for $tool_name here)
- Project Overview:
- Tech Stack:
- Important Docs:
- Verification Commands:
EOF

  echo "✔ 진입점 생성 완료: $local_path"
  echo "  → 관리 영역: $managed_ref (업데이트 시 자동 반영)"
}

create_claude_entry_point() {
  local local_path="$1"

  if [ -f "$local_path" ]; then
    echo "ℹ 진입점 파일이 이미 존재합니다 (건너뜀): $local_path"
    echo "  → 관리 영역은 .ai/entry-points/claude.md 에서 자동 업데이트됩니다."
    return
  fi

  cat > "$local_path" << 'CLAUDEEOF'
# Claude Code Instructions

> **CRITICAL**: Keep this file short and map-oriented. Durable project knowledge belongs in `docs/` and `.ai/`.
> Before executing any task, you MUST read and strictly adhere to the global AI rules defined in `.ai/core.md` and relevant files in `.ai/rules/`.
> Managed configuration (auto-updated): `.ai/entry-points/claude.md`

## Harness Configuration
@.ai/entry-points/claude.md

---
## Project Specific Instructions
(Add only high-signal routing guidance for Claude Code here)
- Project Overview:
- Tech Stack:
- Important Docs:
- Verification Commands:
CLAUDEEOF

  echo "✔ 진입점 생성 완료 (harness config → .ai/entry-points/claude.md): $local_path"
}

[ "${install_claude:-false}" = true ] && create_claude_entry_point "$PROJECT_PATH/CLAUDE.md"
[ "${install_copilot:-false}" = true ] && create_entry_point "GitHub Copilot" "$PROJECT_PATH/.github/copilot-instructions.md" ".ai/entry-points/copilot.md"
[ "${install_antigravity:-false}" = true ] && create_entry_point "Google Antigravity" "$PROJECT_PATH/.agent/rules/rules.md" ".ai/entry-points/antigravity.md"
if [ "${install_codex:-false}" = true ]; then
  if [ -f "$PROJECT_PATH/AGENTS.md" ]; then
    echo "ℹ 진입점 파일이 이미 존재합니다 (건너뜀): $PROJECT_PATH/AGENTS.md"
    echo "  → 관리 영역은 .ai/entry-points/codex.md 에서 자동 업데이트됩니다."
  else
    cat > "$PROJECT_PATH/AGENTS.md" << 'AGENTSEOF'
# AGENTS.md

This file is a short map for agents. Keep it concise.
Managed configuration (auto-updated): `.ai/entry-points/codex.md`

## Read First
- `.ai/core.md`
- `.ai/entry-points/codex.md`
- `docs/index.md`

## Project Map
- Product overview:
- Tech stack:
- Important docs:
- Key commands:
AGENTSEOF
    echo "✔ 진입점 생성 완료: $PROJECT_PATH/AGENTS.md"
    echo "  → 관리 영역: .ai/entry-points/codex.md (업데이트 시 자동 반영)"
  fi
fi

# --- 완료 ---
echo ""
echo "셋업 완료: $PROJECT_PATH"
echo ""
echo "다음 단계:"
echo "  1. 진입점 파일의 'Project Specific Instructions' 섹션에 프로젝트별 지침을 추가하세요."
echo "  2. 공통 규칙은 .ai/core.md 및 .ai/rules/ 폴더를 참조합니다."
echo "  3. 프로젝트 하네스가 필요하면 '하네스 구성해'라고 요청하세요. (.ai/skills/harness)"
echo "  4. (Claude Code) .claude/settings.json, .claude/agents/, .claude/skills/, CLAUDE.md를"
echo "     새로 만들거나 수정한 뒤에는 세션을 리로드해야 새 harness가 활성화됩니다:"
echo "       /exit  →  claude --resume  →  방금 종료한 세션 선택"
echo "     (이 파일들은 세션 시작 시 1회만 로드됩니다)"
echo "  5. 워크플로 업데이트 시 이 스크립트를 다시 실행하면 .ai/ 전체가 업데이트됩니다."
echo "     (진입점 파일의 프로젝트별 지침은 보존됩니다)"
