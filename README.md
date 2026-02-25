# ai-dev-rules

AI 개발 규칙 허브. 여러 프로젝트에서 공통으로 사용하는 전역 AI 지침을 관리합니다.

## 구조

```
ai-dev-rules/
├── .ai/
│   ├── core.md                 # 전역 AI 오케스트레이터 지침 (각 프로젝트에 심볼릭 링크)
│   ├── config/quality.yaml     # LSP/테스트 품질 게이트 설정
│   └── rules/                  # 전역 규칙 (프로젝트에 심볼릭 링크로 연결)
│       ├── development/        # 에이전트 작성 가이드
│       ├── integration/        # MCP 통합 가이드
│       ├── language/           # 언어별 규칙 (go.md, python.md 등)
│       └── workflow/           # SPEC, 팀 워크플로우
└── templates/
    ├── setup-project.ps1                   # 새 프로젝트 셋업 스크립트
    ├── entrypoints/                        # 각 AI 도구별 진입점 템플릿
    │   ├── CLAUDE.md                       # Claude Code 진입점
    │   ├── copilot-instructions.md         # VS Code (GitHub Copilot) 진입점
    │   └── rules.md                        # Google Antigravity 진입점
    ├── project-rules.template.md           # 프로젝트별 규칙 템플릿
    └── README.project-setup.md             # 수동 설정 가이드
```

## 새 프로젝트에 적용하기

```powershell
# 1. 새 프로젝트 디렉토리로 이동
cd C:\path\to\my-project

# 2. ai-dev-rules 저장소 클론 (아직 없는 경우)
# git clone https://github.com/Hongcha-poodle/ai-dev-rules.git C:\path\to\ai-dev-rules

# 3. 셋업 스크립트 실행
& "C:\path\to\ai-dev-rules\templates\setup-project.ps1" -ProjectPath $PWD
```

스크립트가 자동으로:
- 사용자에게 **사용할 AI 도구(VS Code, Claude Code, Google Antigravity)를 선택**하도록 요청
- `ai-dev-rules/.ai/core.md` → 프로젝트의 `.ai/core.md`로 심볼릭 링크 생성
- `ai-dev-rules/.ai/rules` → 프로젝트의 `.ai/rules`로 심볼릭 링크 생성
- 선택한 도구에 맞는 진입점 파일(`CLAUDE.md`, `.github/copilot-instructions.md`, `.agent/rules/rules.md`)만 프로젝트에 복사

## 전역 규칙 업데이트

이 저장소의 `.ai/rules/` 및 `.ai/core.md`를 수정하면 심볼릭 링크로 연결된 **모든 프로젝트에 즉시 반영**됩니다.

## 프로젝트별 커스터마이징

각 프로젝트에 복사된 진입점 파일(`CLAUDE.md`, `.github/copilot-instructions.md`, `.agent/rules/rules.md`) 하단에 프로젝트 특화 내용을 추가합니다.  
전역 규칙과 충돌 시 프로젝트별 규칙이 우선합니다.
