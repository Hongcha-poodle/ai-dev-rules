# setup-project.ps1
# 새 프로젝트에 ai-dev-rules를 연결하는 셋업 스크립트
#
# 사용법:
#   .\setup-project.ps1 -ProjectPath "C:\path\to\my-project"
#
# 하는 일:
#   1. .ai/rules  → ai-dev-rules/.ai/rules 심볼릭 링크 생성
#   2. .ai/core.md → ai-dev-rules/.ai/core.md 심볼릭 링크 생성 (또는 복사)
#   3. 각 AI 도구별 진입점 파일 복사 (CLAUDE.md, .github/copilot-instructions.md, .antigravityrules)

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath
)

$RulesRoot = Split-Path -Parent $PSScriptRoot  # ai-dev-rules 루트
$GlobalRules = Join-Path $RulesRoot ".ai\rules"
$GlobalCore = Join-Path $RulesRoot ".ai\core.md"
$EntrypointsDir = Join-Path $PSScriptRoot "entrypoints"

# --- 검증 ---
if (-not (Test-Path $ProjectPath)) {
    Write-Error "프로젝트 경로가 존재하지 않습니다: $ProjectPath"
    exit 1
}

if (-not (Test-Path $GlobalRules)) {
    Write-Error "전역 규칙 폴더를 찾을 수 없습니다: $GlobalRules"
    exit 1
}

# --- 1. .ai 폴더 및 심볼릭 링크 생성 ---
$DestAiDir = Join-Path $ProjectPath ".ai"
$DestRules = Join-Path $DestAiDir "rules"
$DestCore = Join-Path $DestAiDir "core.md"

if (-not (Test-Path $DestAiDir)) {
    New-Item -ItemType Directory -Path $DestAiDir | Out-Null
}

# rules 심볼릭 링크
if (Test-Path $DestRules) {
    Write-Host ".ai/rules가 이미 존재합니다. 건너뜀"
} else {
    try {
        New-Item -ItemType SymbolicLink -Path $DestRules -Target $GlobalRules | Out-Null
        Write-Host "✔ .ai/rules 심볼릭 링크 생성 완료 → $GlobalRules"
    } catch {
        Write-Warning "심볼릭 링크 생성 실패 (권한 부족). 폴더를 복사합니다."
        Copy-Item $GlobalRules $DestRules -Recurse
        Write-Host "✔ .ai/rules 복사 완료 (주의: 전역 규칙 업데이트가 자동 반영되지 않습니다)"
    }
}

# core.md 심볼릭 링크
if (Test-Path $DestCore) {
    Write-Host ".ai/core.md가 이미 존재합니다. 건너뜀"
} else {
    try {
        New-Item -ItemType SymbolicLink -Path $DestCore -Target $GlobalCore | Out-Null
        Write-Host "✔ .ai/core.md 심볼릭 링크 생성 완료 → $GlobalCore"
    } catch {
        Copy-Item $GlobalCore $DestCore
        Write-Host "✔ .ai/core.md 복사 완료"
    }
}

# --- 2. 진입점 파일 복사 함수 ---
function Copy-EntryPoint {
    param([string]$SourceFile, [string]$DestPath)
    
    $DestDir = Split-Path -Parent $DestPath
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir | Out-Null
    }

    if (Test-Path $DestPath) {
        $overwrite = Read-Host "$DestPath 파일이 이미 존재합니다. 덮어쓰시겠습니까? (y/N)"
        if ($overwrite -eq 'y') {
            Copy-Item $SourceFile $DestPath -Force
            Write-Host "✔ $DestPath 덮어쓰기 완료"
        } else {
            Write-Host "$DestPath 복사 건너뜀"
        }
    } else {
        Copy-Item $SourceFile $DestPath
        Write-Host "✔ $DestPath 복사 완료"
    }
}

# --- 3. 각 도구별 진입점 복사 ---
Write-Host "`n[진입점 파일 복사]"
Copy-EntryPoint -SourceFile (Join-Path $EntrypointsDir "CLAUDE.md") -DestPath (Join-Path $ProjectPath "CLAUDE.md")
Copy-EntryPoint -SourceFile (Join-Path $EntrypointsDir "copilot-instructions.md") -DestPath (Join-Path $ProjectPath ".github\copilot-instructions.md")
Copy-EntryPoint -SourceFile (Join-Path $EntrypointsDir ".antigravityrules") -DestPath (Join-Path $ProjectPath ".antigravityrules")

# --- 완료 ---
Write-Host "`n셋업 완료: $ProjectPath`n"
Write-Host "다음 단계:"
Write-Host "  1. 프로젝트 루트의 CLAUDE.md, .antigravityrules, .github/copilot-instructions.md 파일을 열어 프로젝트별 지침을 추가하세요."
Write-Host "  2. 공통 규칙은 .ai/core.md 및 .ai/rules/ 폴더를 참조하게 됩니다."
