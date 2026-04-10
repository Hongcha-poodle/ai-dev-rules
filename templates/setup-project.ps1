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
    "architecture/architecture-guide.md",
    "development/agent-authoring.md",
    "integration/mcp-integration.md",
    "integration/hooks-guide.md",
    "security/security-guide.md",
    "testing/testing-guide.md",
    "workflow/harness-engineering.md",
    "workflow/long-running-guide.md",
    "workflow/spec-workflow.md",
    "workflow/team-workflow.md"
)

foreach ($rule in $rules) {
    Download-File -RemotePath ".ai/rules/$rule" -LocalPath (Join-Path $DestAiDir "rules\$rule")
}

# language rules
Download-File -RemotePath ".ai/rules/language/README.md" -LocalPath (Join-Path $DestAiDir "rules\language\README.md")
Download-File -RemotePath ".ai/rules/language/_template.md" -LocalPath (Join-Path $DestAiDir "rules\language\_template.md")

# skills
Download-File -RemotePath ".ai/skills/README.md" -LocalPath (Join-Path $DestAiDir "skills\README.md")
Download-File -RemotePath ".ai/skills/harness/SKILL.md" -LocalPath (Join-Path $DestAiDir "skills\harness\SKILL.md")
Download-File -RemotePath ".ai/skills/harness/templates/README.md" -LocalPath (Join-Path $DestAiDir "skills\harness\templates\README.md")
Download-File -RemotePath ".ai/skills/harness/templates/fullstack-app-starter.md" -LocalPath (Join-Path $DestAiDir "skills\harness\templates\fullstack-app-starter.md")
Download-File -RemotePath ".ai/skills/harness/templates/code-review-starter.md" -LocalPath (Join-Path $DestAiDir "skills\harness\templates\code-review-starter.md")
Download-File -RemotePath ".ai/skills/harness/templates/research-content-starter.md" -LocalPath (Join-Path $DestAiDir "skills\harness\templates\research-content-starter.md")
Download-File -RemotePath ".ai/skills/harness/references/pattern-selection.md" -LocalPath (Join-Path $DestAiDir "skills\harness\references\pattern-selection.md")
Download-File -RemotePath ".ai/skills/harness/references/output-contract.md" -LocalPath (Join-Path $DestAiDir "skills\harness\references\output-contract.md")
Download-File -RemotePath ".ai/skills/harness/references/harness-100-template-pack.md" -LocalPath (Join-Path $DestAiDir "skills\harness\references\harness-100-template-pack.md")

# entry-points (managed templates — always overwritten for updates)
$entryPoints = @(
    "entry-points/claude.md",
    "entry-points/copilot.md",
    "entry-points/antigravity.md",
    "entry-points/codex.md"
)
foreach ($ep in $entryPoints) {
    Download-File -RemotePath ".ai/$ep" -LocalPath (Join-Path $DestAiDir $ep.Replace("/", "\"))
}

# --- 2.5 권장 docs/ 구조 생성 ---
Write-Host "`n[권장 docs 구조 생성]"
$docsToCreate = @(
    "docs\index.md",
    "docs\architecture\README.md",
    "docs\plans\active\.gitkeep",
    "docs\plans\completed\.gitkeep",
    "docs\product\README.md",
    "docs\references\README.md",
    "docs\reliability\README.md",
    "docs\security\README.md",
    "docs\generated\README.md"
)

foreach ($relativePath in $docsToCreate) {
    $target = Join-Path $ProjectPath $relativePath
    $dir = Split-Path -Parent $target
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
    if (-not (Test-Path $target)) {
        switch ($relativePath) {
            "docs\index.md" {
                Set-Content -Path $target -Value "# Docs Index`n`n- architecture/`n- plans/active/`n- plans/completed/`n- product/`n- references/`n- reliability/`n- security/`n- generated/`n" -Encoding UTF8
            }
            "docs\architecture\README.md" {
                Set-Content -Path $target -Value "# Architecture`n`n핵심 구조와 변경 이유를 기록합니다.`n" -Encoding UTF8
            }
            "docs\product\README.md" {
                Set-Content -Path $target -Value "# Product`n`n제품 요구사항과 사용자 흐름을 기록합니다.`n" -Encoding UTF8
            }
            "docs\references\README.md" {
                Set-Content -Path $target -Value "# References`n`n에이전트가 참조해야 하는 외부 기술 문서를 요약/정리합니다.`n" -Encoding UTF8
            }
            "docs\reliability\README.md" {
                Set-Content -Path $target -Value "# Reliability`n`n로그, 메트릭, 추적, 운영 체크리스트를 기록합니다.`n" -Encoding UTF8
            }
            "docs\security\README.md" {
                Set-Content -Path $target -Value "# Security`n`n위험 모델, 보안 가드레일, 검토 결과를 기록합니다.`n" -Encoding UTF8
            }
            "docs\generated\README.md" {
                Set-Content -Path $target -Value "# Generated`n`nDB schema, API surface 등 생성 산출물을 보관합니다.`n" -Encoding UTF8
            }
            default {
                New-Item -ItemType File -Path $target | Out-Null
            }
        }
        Write-Host "✔ 생성 완료: $target"
    } else {
        Write-Host "⚠ 이미 존재하여 건너뜀: $target"
    }
}

# --- 3. 각 도구별 진입점 생성 (core.md 참조) ---
Write-Host "`n[진입점 파일 생성]"

function Create-EntryPoint {
    param([string]$ToolName, [string]$LocalPath, [string]$ManagedRef)

    $DestDir = Split-Path -Parent $LocalPath
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir | Out-Null
    }

    if (Test-Path $LocalPath) {
        Write-Host "ℹ 진입점 파일이 이미 존재합니다 (건너뜀): $LocalPath"
        Write-Host "  → 관리 영역은 $ManagedRef 에서 자동 업데이트됩니다."
        return
    }

    try {
        $templateContent = @"
# $ToolName Instructions

> **CRITICAL**: Keep this file short and map-oriented. Durable project knowledge belongs in versioned docs under ``docs/`` and rules under ``.ai/``.
> Before executing any task, you MUST read the following files in order:
> 1. ``.ai/core.md`` — global AI rules
> 2. ``$ManagedRef`` — managed configuration (auto-updated)

---
## Project Specific Instructions
(Add only high-signal routing guidance for $ToolName here)
- Project Overview:
- Tech Stack:
- Important Docs:
- Verification Commands:
"@

        Set-Content -Path $LocalPath -Value $templateContent -Encoding UTF8
        Write-Host "✔ 진입점 생성 완료: $LocalPath"
        Write-Host "  → 관리 영역: $ManagedRef (업데이트 시 자동 반영)"
    } catch {
        Write-Warning "진입점 생성 실패: $LocalPath"
    }
}

if ($installClaude) {
    $claudePath = Join-Path $ProjectPath "CLAUDE.md"
    if (Test-Path $claudePath) {
        Write-Host "ℹ 진입점 파일이 이미 존재합니다 (건너뜀): $claudePath"
        Write-Host "  → 관리 영역은 .ai/entry-points/claude.md 에서 자동 업데이트됩니다."
    } else {
        $claudeContent = @"
# Claude Code Instructions

> **CRITICAL**: Keep this file short and map-oriented. Durable project knowledge belongs in ``docs/`` and ``.ai/``.
> Before executing any task, you MUST read and strictly adhere to the global AI rules defined in ``.ai/core.md`` and relevant files in ``.ai/rules/``.
> Managed configuration (auto-updated): ``.ai/entry-points/claude.md``

## Harness Configuration
@.ai/entry-points/claude.md

---
## Project Specific Instructions
(Add only high-signal routing guidance for Claude Code here)
- Project Overview:
- Tech Stack:
- Important Docs:
- Verification Commands:
"@
        Set-Content -Path $claudePath -Value $claudeContent -Encoding UTF8
        Write-Host "✔ 진입점 생성 완료 (harness config → .ai/entry-points/claude.md): $claudePath"
    }
}

if ($installCopilot) {
    Create-EntryPoint -ToolName "GitHub Copilot" -LocalPath (Join-Path $ProjectPath ".github\copilot-instructions.md") -ManagedRef ".ai/entry-points/copilot.md"
}

if ($installAntigravity) {
    Create-EntryPoint -ToolName "Google Antigravity" -LocalPath (Join-Path $ProjectPath ".agent\rules\rules.md") -ManagedRef ".ai/entry-points/antigravity.md"
}

if ($installCodex) {
    $agentsPath = Join-Path $ProjectPath "AGENTS.md"
    if (Test-Path $agentsPath) {
        Write-Host "ℹ 진입점 파일이 이미 존재합니다 (건너뜀): $agentsPath"
        Write-Host "  → 관리 영역은 .ai/entry-points/codex.md 에서 자동 업데이트됩니다."
    } else {
        $agentsContent = @"
# AGENTS.md

This file is a short map for agents. Keep it concise.
Managed configuration (auto-updated): ``.ai/entry-points/codex.md``

## Read First
- ``.ai/core.md``
- ``.ai/entry-points/codex.md``
- ``docs/index.md``

## Project Map
- Product overview:
- Tech stack:
- Important docs:
- Key commands:
"@
        Set-Content -Path $agentsPath -Value $agentsContent -Encoding UTF8
        Write-Host "✔ 진입점 생성 완료: $agentsPath"
        Write-Host "  → 관리 영역: .ai/entry-points/codex.md (업데이트 시 자동 반영)"
    }
}

# --- 완료 ---
Write-Host "`n셋업 완료: $ProjectPath`n"
Write-Host "다음 단계:"
Write-Host "  1. 진입점 파일의 'Project Specific Instructions' 섹션에 프로젝트별 지침을 추가하세요."
Write-Host "  2. 공통 규칙은 .ai/core.md 및 .ai/rules/ 폴더를 참조합니다."
Write-Host "  3. 프로젝트 하네스가 필요하면 '하네스 구성해'라고 요청하세요. (.ai/skills/harness)"
Write-Host "  4. 워크플로 업데이트 시 이 스크립트를 다시 실행하면 .ai/ 전체가 업데이트됩니다."
Write-Host "     (진입점 파일의 프로젝트별 지침은 보존됩니다)"
