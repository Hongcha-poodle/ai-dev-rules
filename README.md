# ai-dev-rules

AI 개발 규칙 허브. 여러 프로젝트에서 공통으로 사용하는 전역 AI 지침을 관리합니다.

## 구조

```
ai-dev-rules/
├── .ai/
│   ├── core.md                 # 전역 AI 오케스트레이터 지침
│   ├── config/quality.yaml     # LSP/테스트 품질 게이트 설정
│   ├── rules/                  # 전역 규칙
│   │   ├── architecture/       # 아키텍처 설계 원칙
│   │   ├── development/        # 에이전트 작성 가이드
│   │   ├── integration/        # MCP 통합 가이드
│   │   ├── language/           # 언어별 규칙 (go.md, python.md 등)
│   │   ├── security/           # 보안 가이드 (OWASP 기반)
│   │   ├── testing/            # 테스트 전략 가이드
│   │   └── workflow/           # SPEC, 팀 워크플로우
│   └── skills/                 # 도구별 스킬 및 확장 기능
└── templates/
    ├── setup-project.ps1                   # 새 프로젝트 셋업 스크립트
    ├── project-rules.template.md           # 프로젝트별 규칙 템플릿
    └── README.project-setup.md             # 수동 설정 가이드
```

## 새 프로젝트에 적용하기

새 프로젝트 폴더에서 아래 명령어를 실행하면 GitHub에서 최신 규칙을 다운로드하여 자동으로 설정합니다.

**macOS / Linux (bash/zsh)**

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.sh")
```

**Windows (PowerShell)**

```powershell
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.ps1" | Invoke-Expression
```

스크립트가 자동으로:
- 사용자에게 **사용할 AI 도구(VS Code, Claude Code, Google Antigravity, OpenAI Codex)를 선택**하도록 요청
- GitHub에서 최신 `.ai/core.md` 및 `.ai/rules/` 다운로드
- 선택한 도구에 맞는 진입점 파일(`CLAUDE.md`, `.github/copilot-instructions.md`, `.agent/rules/rules.md`, `AGENTS.md`) 생성

## 전역 규칙 업데이트

프로젝트에 설치된 규칙을 최신 버전으로 업데이트하려면 셋업 스크립트를 다시 실행하세요.

## 프로젝트별 커스터마이징

각 프로젝트에 생성된 진입점 파일(`CLAUDE.md`, `.github/copilot-instructions.md`, `.agent/rules/rules.md`, `AGENTS.md`)에 프로젝트 특화 내용을 추가합니다.  
진입점 파일은 공통 규칙인 `.ai/core.md`를 참조하도록 설정되어 있으며, 전역 규칙과 충돌 시 프로젝트별 규칙이 우선합니다.
