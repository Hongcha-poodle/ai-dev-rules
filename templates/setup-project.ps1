# setup-project.ps1
# GitHub에서 ai-dev-rules를 다운로드하여 현재 프로젝트에 설정하는 스크립트
#
# 사용법:
#   Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.ps1" | Invoke-Expression

$RepoUrl = "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main"
$ProjectPath = $PWD.Path

Write-Host "AI Dev Rules 셋업을 시작합니다..."
Write-Host "대상 프로젝트: $ProjectPath"

# --- 0. AI 도구 선택 ---
Write-Host "========================================"
Write-Host "어떤 AI 개발 도구를 사용하시겠습니까?"
Write-Host "1. VS Code (GitHub Copilot)"
Write-Host "2. Claude Code"
Write-Host "3. Google Antigravity"
Write-Host "4. OpenAI Codex"
Write-Host "5. 모두 설치"
Write-Host "========================================"
$choice = Read-Host "번호를 선택하세요 (1-5)"

$installCopilot = ($choice -eq '1' -or $choice -eq '5')
$installClaude = ($choice -eq '2' -or $choice -eq '5')
$installAntigravity = ($choice -eq '3' -or $choice -eq '5')
$installCodex = ($choice -eq '4' -or $choice -eq '5')

if (-not ($installCopilot -or $installClaude -or $installAntigravity -or $installCodex)) {
    Write-Error "잘못된 선택입니다. 스크립트를 종료합니다."
    exit 1
}

# --- 1. 파일 다운로드 함수 ---
function Download-File {
    param([string]$RemotePath, [string]$LocalPath)
    
    $DestDir = Split-Path -Parent $LocalPath
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir | Out-Null
    }

    $Url = "$RepoUrl/$RemotePath"
    try {
        Invoke-RestMethod -Uri $Url -OutFile $LocalPath
        Write-Host "✔ 다운로드 완료: $LocalPath"
    } catch {
        Write-Warning "다운로드 실패: $Url"
    }
}

# --- 2. .ai 폴더 및 핵심 규칙 다운로드 ---
$DestAiDir = Join-Path $ProjectPath ".ai"
if (-not (Test-Path $DestAiDir)) {
    New-Item -ItemType Directory -Path $DestAiDir | Out-Null
}

Write-Host "`n[핵심 규칙 다운로드]"
Download-File -RemotePath ".ai/core.md" -LocalPath (Join-Path $DestAiDir "core.md")

# config
Download-File -RemotePath ".ai/config/quality.yaml" -LocalPath (Join-Path $DestAiDir "config\quality.yaml")

# rules
$rules = @(
    "development/agent-authoring.md",
    "integration/mcp-integration.md",
    "workflow/spec-workflow.md",
    "workflow/team-workflow.md"
)

foreach ($rule in $rules) {
    Download-File -RemotePath ".ai/rules/$rule" -LocalPath (Join-Path $DestAiDir "rules\$rule")
}

# skills
Download-File -RemotePath ".ai/skills/README.md" -LocalPath (Join-Path $DestAiDir "skills\README.md")

# --- 3. 각 도구별 진입점 생성 (core.md 참조) ---
Write-Host "`n[진입점 파일 생성]"

function Create-EntryPoint {
    param([string]$ToolName, [string]$LocalPath)
    
    $DestDir = Split-Path -Parent $LocalPath
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir | Out-Null
    }

    if (Test-Path $LocalPath) {
        Write-Host "⚠ 진입점 파일이 이미 존재합니다. 덮어쓰지 않습니다: $LocalPath"
        return
    }

    try {
        $templateContent = @"
# $ToolName Instructions

> **중요**: 공통 AI 개발 규칙은 `.ai/core.md` 및 `.ai/rules/` 폴더의 내용을 반드시 먼저 읽고 숙지하세요.

---
## Project Specific Instructions
(Add any project-specific instructions for $ToolName here)
- 프로젝트 개요:
- 기술 스택:
- 코딩 컨벤션:
- 파일 구조:
"@

        Set-Content -Path $LocalPath -Value $templateContent -Encoding UTF8
        Write-Host "✔ 진입점 생성 완료 (core.md 참조): $LocalPath"
    } catch {
        Write-Warning "진입점 생성 실패: $LocalPath"
    }
}

if ($installClaude) {
    Create-EntryPoint -ToolName "Claude Code" -LocalPath (Join-Path $ProjectPath "CLAUDE.md")
}

if ($installCopilot) {
    Create-EntryPoint -ToolName "GitHub Copilot" -LocalPath (Join-Path $ProjectPath ".github\copilot-instructions.md")
}

if ($installAntigravity) {
    Create-EntryPoint -ToolName "Google Antigravity" -LocalPath (Join-Path $ProjectPath ".agent\rules\rules.md")
}

if ($installCodex) {
    Create-EntryPoint -ToolName "OpenAI Codex" -LocalPath (Join-Path $ProjectPath "AGENTS.md")
}

# --- 완료 ---
Write-Host "`n셋업 완료: $ProjectPath`n"
Write-Host "다음 단계:"
Write-Host "  1. 프로젝트에 생성된 진입점 파일(CLAUDE.md, .agent/rules/rules.md, .github/copilot-instructions.md, AGENTS.md 중 선택한 것)을 열어 프로젝트별 지침을 추가하세요."
Write-Host "  2. 공통 규칙은 .ai/core.md 및 .ai/rules/ 폴더를 참조하게 됩니다."
