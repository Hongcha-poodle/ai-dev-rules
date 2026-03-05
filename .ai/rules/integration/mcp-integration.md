# MCP 통합 가이드

## 개요

Model Context Protocol (MCP) 서버 및 Extended Thinking과의 통합 방법을 설명합니다.

## MCP 서버 설정

### 기본 구성
```json
{
  "mcpServers": {
    "custom-server": {
      "command": "node",
      "args": ["path/to/server.js"],
      "env": {}
    }
  }
}
```

### 보안 고려사항
- 환경 변수를 통한 인증 정보 관리
- 최소 권한 원칙 적용
- 로그 및 모니터링 설정

## 확장 사고 (Extended Thinking) 활용

Claude의 확장 사고 기능은 복잡한 추론이 필요한 경우 API 레벨에서 활성화됩니다.

### 활용 시나리오
- 복잡한 아키텍처 결정
- 다단계 알고리즘 설계
- 트레이드오프 분석

### API 설정 예시
```json
{
  "thinking": {
    "type": "enabled",
    "budget_tokens": 10000
  }
}
```

### Claude Code에서의 활용
Claude Code는 자동으로 내부적으로 사고 단계를 활용합니다.
MCP 도구를 통한 복잡한 작업에서 AI가 추론 과정을 거쳐 결과를 반환합니다.

## 커스텀 도구 개발

### 도구 정의
```typescript
interface Tool {
  name: string;
  description: string;
  inputSchema: JSONSchema;
  handler: (input: any) => Promise<any>;
}
```

### 등록 및 사용
- MCP 서버에 도구 등록
- 에이전트에서 도구 활용
- 결과 처리 및 에러 핸들링

## 디버깅 및 문제 해결

### 로깅
- 요청/응답 로그 확인
- 에러 스택 트레이스 분석

### 일반적인 문제
- 연결 실패: 서버 상태 및 네트워크 확인
- 타임아웃: 요청 크기 및 처리 시간 최적화
- 권한 오류: 인증 설정 검토
