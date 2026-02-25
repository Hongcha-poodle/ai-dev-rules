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

### 2. CLAUDE 설정 파일 복사

```bash
# 템플릿 복사
cp /path/to/ai-dev-rules/templates/project-CLAUDE.template.md ./CLAUDE.md
```

### 3. 프로젝트별 설정 커스터마이징

`CLAUDE.md` 파일을 열어 다음 섹션을 프로젝트에 맞게 수정:

- 프로젝트 개요
- 기술 스택
- 코딩 컨벤션
- 파일 구조

### 4. 전역 규칙 참조 (선택사항)

프로젝트의 `CLAUDE.md`에 전역 규칙을 참조하도록 추가:

```markdown
## 전역 규칙

이 프로젝트는 [AI Dev Rules](path/to/ai-dev-rules)의 전역 규칙을 따릅니다.

상세 내용은 다음을 참조:
- [Core Constitution](path/to/ai-dev-rules/.claude/rules/system/core/constitution.md)
- [SPEC Workflow](path/to/ai-dev-rules/.claude/rules/system/workflow/spec-workflow.md)
```

### 5. IDE 설정

#### VS Code
`.vscode/settings.json` 생성:
```json
{
  "github.copilot.advanced": {
    "inlineSuggestCount": 3
  },
  "claude.customInstructions": "./CLAUDE.md"
}
```

## 프로젝트 구조 예시

```
my-new-project/
├─ CLAUDE.md                    # 프로젝트별 AI 규칙
├─ .claude/                     # 프로젝트별 추가 규칙 (선택사항)
│  └─ rules/
│     └─ custom-rules.md
├─ src/                         # 소스 코드
├─ tests/                       # 테스트
├─ docs/                        # 문서
└─ README.md                    # 프로젝트 README
```

## AI 어시스턴트 활용

### Claude를 통한 개발

1. **컨텍스트 제공**: 프로젝트의 `CLAUDE.md`가 자동으로 컨텍스트로 제공됩니다
2. **규칙 준수**: AI는 정의된 규칙에 따라 코드를 생성합니다
3. **일관성 유지**: 전체 프로젝트에서 일관된 스타일과 패턴이 유지됩니다

### GitHub Copilot 활용

- 인라인 제안이 프로젝트 컨벤션을 따르도록 학습됩니다
- 주석 기반 코드 생성이 규칙에 맞게 동작합니다

## 팀 협업

### 규칙 공유

팀원들과 다음을 공유하세요:

1. `CLAUDE.md` 파일 - 프로젝트별 규칙
2. [AI Dev Rules 저장소](path/to/ai-dev-rules) - 전역 규칙
3. 이 설정 가이드

### 규칙 업데이트

- 팀의 합의 하에 `CLAUDE.md` 수정
- 변경사항을 커밋 메시지에 명확히 기록
- 주기적으로 전역 규칙 업데이트 확인

## 문제 해결

### AI가 규칙을 따르지 않는 경우

1. `CLAUDE.md`가 프로젝트 루트에 있는지 확인
2. 규칙이 명확하고 구체적인지 검토
3. IDE를 재시작하여 설정 새로고침

### 규칙 충돌

- 프로젝트별 규칙이 전역 규칙보다 우선
- 충돌 시 `CLAUDE.md`에 명시적으로 우선순위 기록

## 추가 리소스

- [Agent Authoring Guide](path/to/ai-dev-rules/.claude/rules/system/development/agent-authoring.md)
- [MCP Integration](path/to/ai-dev-rules/.claude/rules/system/integration/mcp-integration.md)
- [Team Workflow](path/to/ai-dev-rules/.claude/rules/system/workflow/team-workflow.md)
