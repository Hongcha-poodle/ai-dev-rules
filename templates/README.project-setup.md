# 새 프로젝트에 AI Dev Rules 적용하기

## 개요

이 가이드는 새로운 프로젝트에 AI Dev Rules를 적용하는 방법을 설명합니다.

## 설정 단계

### 1. 프로젝트 생성

```bash
# 새 프로젝트 디렉토리 생성
mkdir my-new-project
cd my-new-project

# Git 초기화 (선택사항)
git init
```

### 2. AI 도구 진입점 및 규칙 연결

가장 쉬운 방법은 제공된 셋업 스크립트를 사용하는 것입니다:

```powershell
# ai-dev-rules 저장소 클론 (아직 없는 경우)
# git clone https://github.com/Hongcha-poodle/ai-dev-rules.git C:\path\to\ai-dev-rules

# 셋업 스크립트 실행
& "C:\path\to\ai-dev-rules\templates\setup-project.ps1" -ProjectPath $PWD
```

스크립트를 실행하면 **사용할 AI 도구(VS Code, Claude Code, Google Antigravity)를 선택**하는 프롬프트가 나타나며, 선택한 도구에 맞는 설정 파일만 복사됩니다.

수동으로 설정하려면 다음을 수행하세요:
1. 프로젝트 루트에 `.ai` 폴더 생성
2. `ai-dev-rules/.ai/core.md` 및 `ai-dev-rules/.ai/rules`를 프로젝트의 `.ai/` 폴더 안에 심볼릭 링크로 연결
3. `ai-dev-rules/templates/entrypoints/`에 있는 진입점 파일들 중 사용하는 도구에 맞는 파일(`CLAUDE.md`, `.github/copilot-instructions.md`, `rules.md`)을 프로젝트의 적절한 위치에 복사
   - Claude Code: `CLAUDE.md`
   - VS Code (GitHub Copilot): `.github/copilot-instructions.md`
   - Google Antigravity: `.agent/rules/rules.md`

### 3. 프로젝트별 설정 커스터마이징

복사된 진입점 파일 하단을 열어 다음 섹션을 프로젝트에 맞게 수정:

- 프로젝트 개요
- 기술 스택
- 코딩 컨벤션
- 파일 구조

### 4. 전역 규칙 참조 (선택사항)

프로젝트의 진입점 파일에 전역 규칙을 참조하도록 추가:

```markdown
## 전역 규칙

이 프로젝트는 [AI Dev Rules](https://github.com/Hongcha-poodle/ai-dev-rules)의 전역 규칙을 따릅니다.

상세 내용은 다음을 참조:
- [SPEC Workflow](https://github.com/Hongcha-poodle/ai-dev-rules/blob/main/.ai/rules/workflow/spec-workflow.md)
```

### 5. IDE 설정

#### VS Code
`.vscode/settings.json` 생성:
```json
{
  "github.copilot.advanced": {
    "inlineSuggestCount": 3
  }
}
```

## 프로젝트 구조 예시

```
my-new-project/
├─ .ai/                         # 전역 AI 규칙 (심볼릭 링크)
│  ├─ core.md
│  └─ rules/
├─ CLAUDE.md                    # Claude Code 진입점
├─ .agent/
│  └─ rules/
│     └─ rules.md               # Google Antigravity 진입점
├─ .github/
│  └─ copilot-instructions.md   # GitHub Copilot 진입점
├─ src/                         # 소스 코드
├─ tests/                       # 테스트
├─ docs/                        # 문서
└─ README.md                    # 프로젝트 README
```

## AI 어시스턴트 활용

### Claude Code / Google Antigravity를 통한 개발

1. **컨텍스트 제공**: 프로젝트의 진입점 파일이 자동으로 컨텍스트로 제공됩니다
2. **규칙 준수**: AI는 정의된 규칙에 따라 코드를 생성합니다
3. **일관성 유지**: 전체 프로젝트에서 일관된 스타일과 패턴이 유지됩니다

### GitHub Copilot 활용

- `.github/copilot-instructions.md`를 통해 인라인 제안이 프로젝트 컨벤션을 따르도록 학습됩니다
- 주석 기반 코드 생성이 규칙에 맞게 동작합니다

## 팀 협업

### 규칙 공유

팀원들과 다음을 공유하세요:

1. 진입점 파일들 - 프로젝트별 규칙
2. [AI Dev Rules 저장소](https://github.com/Hongcha-poodle/ai-dev-rules) - 전역 규칙
3. 이 설정 가이드

### 규칙 업데이트

전역 규칙은 `ai-dev-rules` 저장소에서 관리되며, 심볼릭 링크를 통해 모든 프로젝트에 즉시 반영됩니다.
