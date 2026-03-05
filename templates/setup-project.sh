#!/usr/bin/env bash
# setup-project.sh
# GitHub에서 ai-dev-rules를 다운로드하여 현재 프로젝트에 설정하는 스크립트
#
# 사용법:
#   bash <(curl -fsSL "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.sh")

set -e

REPO_URL="https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main"
PROJECT_PATH="$(pwd)"

echo "AI Dev Rules 셋업을 시작합니다..."
echo "대상 프로젝트: $PROJECT_PATH"

# --- 0. AI 도구 선택 ---
echo "========================================"
echo "어떤 AI 개발 도구를 사용하시겠습니까?"
echo "1. VS Code (GitHub Copilot)"
echo "2. Claude Code"
echo "3. Google Antigravity"
echo "4. OpenAI Codex"
echo "5. 모두 설치"
echo "========================================"
read -r -p "번호를 선택하세요 (1-5): " choice

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
  if curl -fsSL "$url" -o "$local_path"; then
    echo "✔ 다운로드 완료: $local_path"
  else
    echo "⚠ 다운로드 실패: $url"
  fi
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
  "security/security-guide.md"
  "testing/testing-guide.md"
  "workflow/spec-workflow.md"
  "workflow/team-workflow.md"
)

for rule in "${rules[@]}"; do
  download_file ".ai/rules/$rule" "$AI_DIR/rules/$rule"
done

# language rules
download_file ".ai/rules/language/README.md" "$AI_DIR/rules/language/README.md"
download_file ".ai/rules/language/_template.md" "$AI_DIR/rules/language/_template.md"

# skills
download_file ".ai/skills/README.md" "$AI_DIR/skills/README.md"

# --- 3. 각 도구별 진입점 생성 (core.md 참조) ---
echo ""
echo "[진입점 파일 생성]"

create_entry_point() {
  local tool_name="$1"
  local local_path="$2"

  local dest_dir
  dest_dir="$(dirname "$local_path")"
  mkdir -p "$dest_dir"

  if [ -f "$local_path" ]; then
    echo "⚠ 진입점 파일이 이미 존재합니다. 덮어쓰지 않습니다: $local_path"
    return
  fi

  cat > "$local_path" << EOF
# $tool_name Instructions

> **CRITICAL**: Before executing any task, you MUST read and strictly adhere to the global AI rules defined in \`.ai/core.md\` and all rules in \`.ai/rules/\`.

---
## Project Specific Instructions
(Add any project-specific instructions for $tool_name here)
- Project Overview:
- Tech Stack:
- Coding Conventions:
- File Structure:
EOF

  echo "✔ 진입점 생성 완료 (core.md 참조): $local_path"
}

[ "${install_claude:-false}" = true ] && create_entry_point "Claude Code" "$PROJECT_PATH/CLAUDE.md"
[ "${install_copilot:-false}" = true ] && create_entry_point "GitHub Copilot" "$PROJECT_PATH/.github/copilot-instructions.md"
[ "${install_antigravity:-false}" = true ] && create_entry_point "Google Antigravity" "$PROJECT_PATH/.agent/rules/rules.md"
[ "${install_codex:-false}" = true ] && create_entry_point "OpenAI Codex" "$PROJECT_PATH/AGENTS.md"

# --- 완료 ---
echo ""
echo "셋업 완료: $PROJECT_PATH"
echo ""
echo "다음 단계:"
echo "  1. 프로젝트에 생성된 진입점 파일(CLAUDE.md, .agent/rules/rules.md, .github/copilot-instructions.md, AGENTS.md 중 선택한 것)을 열어 프로젝트별 지침을 추가하세요."
echo "  2. 공통 규칙은 .ai/core.md 및 .ai/rules/ 폴더를 참조하게 됩니다."
