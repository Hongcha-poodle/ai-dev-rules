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
│   │   ├── integration/        # MCP 통합 및 Hooks 가이드
│   │   ├── language/           # 언어별 규칙 (템플릿 제공, 필요 시 추가)
│   │   ├── security/           # 보안 가이드 (OWASP 기반)
│   │   ├── testing/            # 테스트 전략 가이드
│   │   └── workflow/           # SPEC, 팀, Harness 엔지니어링 워크플로우
│   └── skills/                 # 도구별 스킬 및 확장 기능
└── templates/
    ├── setup-project.sh        # 셋업 스크립트 (macOS/Linux)
    └── setup-project.ps1       # 셋업 스크립트 (Windows)
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
- `docs/` 기본 골격 생성
- 선택한 도구에 맞는 진입점 파일(`CLAUDE.md`, `.github/copilot-instructions.md`, `.agent/rules/rules.md`, `AGENTS.md`) 생성

## Harness 엔지니어링 관점의 권장 운영 방식

- 진입점 파일(`AGENTS.md`, `CLAUDE.md`)은 짧은 map으로 유지하고, 상세 지식은 `docs/`와 `.ai/rules/`에 기록합니다.
- 반복해서 실패하는 작업은 프롬프트를 늘리기보다 스크립트, 테스트, 관측 가능성, 문서 구조를 개선합니다.
- UI/로그/메트릭/추적처럼 에이전트가 직접 읽고 검증할 수 있는 표면을 늘립니다.
- 작은 PR과 빠른 검증을 기본으로 하고, 드리프트와 AI slop을 줄이기 위한 정리 루프를 둡니다.

## 전역 규칙 업데이트

프로젝트에 설치된 규칙을 최신 버전으로 업데이트하려면 셋업 스크립트를 다시 실행하세요.

## 프로젝트별 커스터마이징

각 프로젝트에 생성된 진입점 파일(`CLAUDE.md`, `.github/copilot-instructions.md`, `.agent/rules/rules.md`, `AGENTS.md`)에 프로젝트 특화 내용을 추가합니다.  
진입점 파일은 공통 규칙인 `.ai/core.md`를 참조하도록 설정되어 있으며, 전역 규칙과 충돌 시 프로젝트별 규칙이 우선합니다.
