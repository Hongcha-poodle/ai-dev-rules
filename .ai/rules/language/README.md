# Language-Specific Rules

이 디렉토리에는 언어/프레임워크별 전문 규칙이 위치합니다.
core.md §4에서 참조됩니다.

## 파일 명명 규칙

```
.ai/rules/language/
├── _template.md   # 새 언어 규칙 작성용 템플릿
├── go.md          # (예시) Go 언어 규칙
├── python.md      # (예시) Python 규칙
├── typescript.md  # (예시) TypeScript/JavaScript 규칙
└── ...            # _template.md를 복사하여 필요한 언어 규칙 추가
```

## 새 언어 규칙 추가 방법
1. `_template.md`를 복사하여 `{언어명}.md`로 이름 변경
2. 플레이스홀더(`{...}`)를 실제 값으로 채우기
3. 프로젝트에 해당 언어가 등장하면 오케스트레이터가 자동 로드

각 파일에는 해당 언어의 다음 항목을 포함합니다:
- 테스트 실행 명령어
- 포매팅 도구 및 설정
- 린터 설정
- 빌드 명령어
- 언어별 주의사항
