# ai-dev-rules

AI 개발 규칙 허브. 여러 프로젝트에서 공통으로 사용하는 전역 AI 지침을 관리합니다.

## 핵심 규칙 체계

`core.md`는 모든 AI 에이전트가 따르는 오케스트레이터 지침이며, 다음을 정의합니다:

- **Hard Rules** — 한국어 응답, 병렬 실행, 접근 방식 선승인, 재현 우선 버그 수정, 루프 감지(동일 오류 3회 시 중단), 완료 전 자체 검증 등 15개 필수 규칙
- **Request Pipeline** — Analyze → Route(Plan/Run/Sync/Harness) → Execute → Report
- **Agent Delegation** — 복잡도별 직접 실행 / 서브 에이전트 위임 기준
- **Quality Gates** — LSP 제로 에러, 아키텍처·보안·테스트·배포·운영·하네스 검증
- **Context Loading** — 트리거 기반 온디맨드 규칙 파일 로딩

## 구조

```
ai-dev-rules/
├── .ai/
│   ├── core.md                          # 전역 AI 오케스트레이터 지침
│   ├── config/
│   │   └── quality.yaml                 # LSP/테스트 품질 게이트 설정
│   ├── entry-points/                    # 관리 영역 (셋업 시 항상 최신으로 덮어씀)
│   │   ├── claude.md                    # Claude Code 하네스 설정
│   │   ├── copilot.md                   # GitHub Copilot 설정
│   │   ├── antigravity.md               # Google Antigravity 설정
│   │   └── codex.md                     # OpenAI Codex 설정
│   ├── rules/
│   │   ├── architecture/
│   │   │   └── architecture-guide.md    # 아키텍처 설계 원칙
│   │   ├── development/
│   │   │   └── agent-authoring.md       # 에이전트/스킬 작성 가이드
│   │   ├── integration/
│   │   │   ├── hooks-guide.md           # 하네스 Hooks 자동화 가이드
│   │   │   └── mcp-integration.md       # MCP 서버 통합 가이드
│   │   ├── language/
│   │   │   ├── README.md                # 언어별 규칙 안내
│   │   │   └── _template.md             # 새 언어 규칙 작성 템플릿
│   │   ├── security/
│   │   │   └── security-guide.md        # 보안 가이드 (OWASP 기반)
│   │   ├── testing/
│   │   │   └── testing-guide.md         # 테스트 전략 가이드
│   │   └── workflow/
│   │       ├── harness-engineering.md   # 하네스 엔지니어링 운영 가이드
│   │       ├── long-running-guide.md    # 장기 실행/멀티세션 작업 가이드
│   │       ├── spec-workflow.md         # SPEC 워크플로우 (Plan-Run-Sync)
│   │       └── team-workflow.md         # 팀 역할 매핑 및 협업 워크플로우
│   └── skills/
│       ├── README.md                    # 커스텀 스킬 추가 방법 안내
│       └── harness/                     # "하네스 구성해"용 harness bootstrap skill
└── templates/
    ├── setup-project.sh                 # 셋업 스크립트 (macOS/Linux)
    └── setup-project.ps1                # 셋업 스크립트 (Windows)
```

## 새 프로젝트에 적용하기

새 프로젝트 폴더에서 아래 명령어를 실행하면 GitHub에서 최신 규칙을 다운로드하여 자동으로 설정합니다.

**macOS / Linux (bash/zsh)**

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.sh")
```

Claude Code, OpenAI Codex, Google Antigravity만 설치하려면:

```bash
AI_TOOL=claude,codex,antigravity bash <(curl -fsSL "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.sh")
```

**Windows (PowerShell)**

```powershell
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.ps1" | Invoke-Expression
```

Claude Code, OpenAI Codex, Google Antigravity만 설치하려면:

```powershell
$env:AI_TOOL = "claude,codex,antigravity"
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.ps1" | Invoke-Expression
Remove-Item Env:AI_TOOL -ErrorAction SilentlyContinue
```

대화형 실행에서는 `2,3,4`처럼 쉼표로 여러 도구를 선택할 수 있습니다. `AI_TOOL=all` 또는 `5`는 GitHub Copilot까지 포함한 전체 설치입니다.

### 셋업 스크립트 동작

스크립트가 자동으로 수행하는 작업:

1. **AI 도구 선택** — VS Code (GitHub Copilot), Claude Code, Google Antigravity, OpenAI Codex 중 단일/복수 선택 또는 전체 설치
2. **`.ai/` 규칙 다운로드** — `core.md`, `config/quality.yaml`, 모든 `rules/` 파일, `entry-points/` 관리 템플릿, `skills/README.md`
   - 포함 스킬: `harness` (`하네스 구성해`, `build a harness for this project` 요청용)
   - 포함 스크립트: `scripts/generate-hooks.py`, `scripts/apply-hooks.py`, `scripts/hook-runner.mjs`, `scripts/harness-audit.py`
3. **`docs/` 권장 구조 생성** — 아래 표준 디렉토리와 기본 파일을 생성합니다:
   ```
   docs/
   ├── index.md               # 문서 인덱스 (시작 맵)
   ├── architecture/           # 핵심 구조와 변경 이유
   ├── plans/active/           # 진행 중인 계획
   ├── plans/completed/        # 완료된 계획
   ├── product/                # 제품 요구사항과 사용자 흐름
   ├── references/             # 외부 기술 문서 요약/정리
   ├── reliability/            # 로그, 메트릭, 추적, 운영 체크리스트
   ├── security/               # 위험 모델, 보안 가드레일
   └── generated/              # DB schema, API surface 등 생성 산출물
   ```
4. **진입점 파일 생성** — 선택한 도구에 맞는 파일을 생성합니다:

   | AI 도구 | 진입점 파일 | 특징 |
   |---|---|---|
   | Claude Code | `CLAUDE.md` | `.ai/entry-points/claude.md` 참조 (하네스 설정) |
   | GitHub Copilot | `.github/copilot-instructions.md` | `.ai/entry-points/copilot.md` 참조 |
   | Google Antigravity | `.agent/rules/rules.md` | `.ai/entry-points/antigravity.md` 참조 |
   | OpenAI Codex | `AGENTS.md` | `.ai/entry-points/codex.md` 참조 |

> 이미 존재하는 진입점 파일은 덮어쓰지 않습니다. 하지만 관리 영역(`.ai/entry-points/`)은 항상 최신으로 업데이트됩니다.

### Claude Code 사용자: 셋업/하네스 변경 후 세션 리로드

`.claude/settings.json`, `.claude/agents/`, `.claude/skills/`, `CLAUDE.md`는 **세션 시작 시점에만 1회 로드**됩니다. 셋업 스크립트나 `하네스 구성해`로 이 파일들을 새로 만들거나 수정했다면, 현재 세션은 여전히 옛 harness를 사용합니다. 새 harness를 활성화하려면:

1. `/exit` — 현재 세션 종료
2. `claude --resume` (또는 `cc --resume`) — 같은 대화 컨텍스트 유지
3. 방금 종료한 세션 선택
4. 새로 추가된 skill/agent를 한 번 호출해 동작 확인

`.ai/rules/*.md` 같은 on-demand 규칙은 매번 새로 읽히므로 리로드가 필요 없습니다. 이 절차는 Claude Code에만 해당하며, Codex/Copilot/Antigravity는 진입점을 요청마다 다시 읽습니다.

## Harness 엔지니어링 관점의 권장 운영 방식

- **진입점은 짧은 map으로 유지** — `AGENTS.md`, `CLAUDE.md` 등은 라우팅 역할만 하고, 상세 지식은 `docs/`와 `.ai/rules/`에 기록합니다.
- **하네스 우선 개선** — 반복 실패하는 작업은 프롬프트를 늘리기보다 스크립트, 테스트, 관측 가능성, 문서 구조를 개선합니다.
- **에이전트 가독성 표면 확대** — UI/로그/메트릭/추적처럼 에이전트가 직접 읽고 검증할 수 있는 인터페이스를 늘립니다.
- **작은 PR + 정리 루프** — 작은 PR과 빠른 검증을 기본으로 하고, 드리프트와 AI slop을 줄이기 위한 정리 루프를 둡니다.
- **루프 감지** — 동일 파일 3회 이상 편집 또는 동일 테스트 3회 이상 실패 시 재시도 대신 접근 방식을 재평가합니다.

## `하네스 구성해` 명령 지원

이 저장소에는 프로젝트 맞춤 harness를 부트스트랩하는 `.ai/skills/harness/` 스킬이 포함되어 있습니다.

- 트리거 예시:
  - `하네스 구성해`
  - `하네스 설치해`
  - `하네스 세팅해`
  - `하네스 셋팅해`
  - `이 프로젝트에 맞는 하네스 설계해`
  - `build a harness for this project`
- 스킬이 수행하는 일:
  - 현재 프로젝트의 entrypoint, `docs/`, 검증 명령, hook/automation 가능성을 감사
  - entrypoint/docs 안의 backtick path가 실제 파일을 가리키는지 `scripts/harness-audit.py`로 검사
  - 작업 성격에 맞는 orchestration pattern 선택
  - tool/environment에 맞는 harness 산출물 생성
  - verification surface와 cleanup loop까지 포함한 validation plan 작성
- Claude Code 프로젝트에서는 `.claude/agents/`, `.claude/skills/`, `.claude/settings.json`까지 포함하는 쪽을 우선 검토합니다.
- 그 외 환경에서는 `docs/harness/`, verification contract, role map, harness bootstrap plan 같은 repo-local artifacts를 생성합니다.
- `revfactory/harness-100`의 검증된 패키지 관례를 distilled template pack 형태로 참고하여, 공통 골격은 재사용하고 도메인 세부사항은 프로젝트에 맞게 재구성합니다.
- starter template packs:
  - `fullstack-app-starter`
  - `code-review-starter`
  - `research-content-starter`
- Claude Code hook generator는 JavaScript repo에서 `vitest`와 `jest`를 감지해 impacted test command를 분기하고, shell one-liner 대신 `node scripts/hook-runner.mjs ...`를 사용합니다.
- Windows에서 hook generation을 실행할 때는 `python` alias보다 `py -3 scripts/generate-hooks.py ...` 또는 `uv run python scripts/generate-hooks.py ...`를 우선 사용하세요.

## Dry-Run Fixture

- `fixtures/fullstack-harness-smoke/`는 설치 후 `하네스 설치해` 또는 `하네스 구성해` 요청이 들어왔을 때 기대하는 산출물 형태를 보여주는 fullstack fixture입니다.
- 포함 내용:
  - 짧은 `AGENTS.md`, `CLAUDE.md`
  - `docs/harness/` 문서 세트
  - `.claude/agents/` specialist roles
  - `.claude/skills/` orchestrator / extension skill 예시
  - `_workspace/` artifact convention

## 전역 규칙 업데이트

프로젝트에 설치된 규칙을 최신 버전으로 업데이트하려면 셋업 스크립트를 다시 실행하세요.

Claude Code, OpenAI Codex, Google Antigravity를 함께 쓰는 프로젝트라면 설치 때와 같은 조합을 지정해서 다시 실행합니다.

**macOS / Linux**

```bash
AI_TOOL=claude,codex,antigravity bash <(curl -fsSL "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.sh")
```

**Windows (PowerShell)**

```powershell
$env:AI_TOOL = "claude,codex,antigravity"
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Hongcha-poodle/ai-dev-rules/main/templates/setup-project.ps1" | Invoke-Expression
Remove-Item Env:AI_TOOL -ErrorAction SilentlyContinue
```

GitHub Copilot까지 포함한 전체 업데이트가 필요하면 `AI_TOOL=all` 또는 대화형 선택 `5`를 사용합니다.

- 기존 `.ai/` 규칙 파일과 `.ai/entry-points/`는 최신 버전으로 **덮어쓰기**됩니다.
- 진입점 파일(`CLAUDE.md`, `AGENTS.md`, `.agent/rules/rules.md` 등)은 이미 존재하면 **건너뜁니다** — 프로젝트별 커스터마이징이 유지됩니다.
- 워크플로 템플릿 변경 사항은 `.ai/entry-points/`를 통해 기존 프로젝트에도 자동 반영됩니다.
- `docs/` 디렉토리의 기존 파일도 건너뜁니다.

## 프로젝트별 커스터마이징

각 프로젝트에 생성된 진입점 파일에 프로젝트 특화 내용을 추가합니다.

- 진입점 파일의 `Project Specific Instructions` 섹션에 프로젝트 개요, 기술 스택, 핵심 문서, 검증 명령어를 기입합니다.
- 진입점 파일은 공통 규칙인 `.ai/core.md`를 참조하도록 설정되어 있으며, **전역 규칙과 충돌 시 프로젝트별 규칙이 우선**합니다.
- 언어별 규칙이 필요하면 `.ai/rules/language/_template.md`를 복사하여 `{lang}.md`로 작성합니다.
- 커스텀 스킬이 필요하면 `.ai/skills/README.md`의 안내를 따라 스킬 파일을 추가합니다.
