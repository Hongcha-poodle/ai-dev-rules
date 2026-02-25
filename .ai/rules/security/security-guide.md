# 보안 가이드

## 개요

AI가 코드를 생성하거나 검토할 때 적용해야 할 보안 원칙을 정의합니다.
OWASP Top 10 기반으로 가장 빈번한 취약점을 우선 다룹니다.

## 핵심 원칙

- **[HARD]** 보안 취약점이 포함된 코드는 생성하지 않는다.
- **[HARD]** 민감 정보(API 키, 비밀번호, 토큰)는 코드에 하드코딩하지 않는다. 환경 변수 또는 시크릿 관리 도구를 사용한다.
- 외부 입력은 항상 검증하고 이스케이프한다 (신뢰 경계 원칙).
- 최소 권한 원칙(Principle of Least Privilege)을 기본으로 설계한다.

## 주요 취약점 방지

### 인젝션 (Injection)
- SQL, NoSQL, 커맨드, LDAP 인젝션 방지
- **항상** Prepared Statement / Parameterized Query 사용
- 사용자 입력을 쿼리 문자열에 직접 삽입 금지

```
# 금지
query = "SELECT * FROM users WHERE id = " + user_input

# 권장
query = "SELECT * FROM users WHERE id = ?"
execute(query, [user_input])
```

### 인증 및 세션 관리
- 비밀번호는 단방향 해시(bcrypt, argon2) 저장, 평문/MD5/SHA1 금지
- 세션 토큰은 충분한 엔트로피(128bit 이상)로 생성
- JWT 사용 시 알고리즘 명시 (`alg: none` 금지), 만료 시간 설정 필수

### XSS (Cross-Site Scripting)
- 사용자 입력을 HTML에 렌더링할 때 반드시 이스케이프
- CSP(Content Security Policy) 헤더 설정 권장
- `innerHTML`, `dangerouslySetInnerHTML` 사용 시 반드시 sanitize

### 민감 정보 노출
- 에러 메시지에 스택 트레이스, DB 스키마, 내부 경로 노출 금지
- 로그에 비밀번호, 토큰, 개인정보 출력 금지
- API 응답에서 불필요한 필드 제거 (최소 노출 원칙)

### 접근 제어 (Broken Access Control)
- 모든 API 엔드포인트에 인증/인가 검사 적용
- 직접 객체 참조(IDOR) 방지: 리소스 접근 전 소유권 검증
- 관리자 기능은 역할(Role) 기반으로 엄격히 제한

### 의존성 보안
- 알려진 취약점이 있는 라이브러리 버전 사용 금지
- 정기적으로 `npm audit`, `pip-audit`, `go vuln` 등으로 점검

## 코드 리뷰 보안 체크리스트

- [ ] 하드코딩된 시크릿이 없는가?
- [ ] 모든 외부 입력이 검증/이스케이프 되는가?
- [ ] SQL/커맨드 인젝션 취약점이 없는가?
- [ ] 적절한 인증/인가가 적용되어 있는가?
- [ ] 에러 메시지에 민감 정보가 노출되지 않는가?
- [ ] 의존성에 알려진 취약점이 없는가?
