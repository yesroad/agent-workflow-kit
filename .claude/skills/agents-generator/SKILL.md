---
name: agents-generator
description: 프로젝트를 분석하고 도구 우선순위에 맞는 루트 지시문(CLAUDE.md 또는 AGENTS.md)을 생성/업데이트합니다. 모노레포 자동 감지 및 워크스페이스별 중첩 파일 생성.
disable-model-invocation: false
argument-hint: "[선택사항: 특정 워크스페이스 경로]"
metadata:
  version: 1.=.0
  category: documentation
  priority: high
---

# Instruction File Generator

## 목적

프로젝트를 분석하고 최적화된 루트 지시문 시스템을 생성하거나 업데이트합니다:

1. **신규 생성** — 대상 파일(CLAUDE.md 또는 AGENTS.md)이 없으면 자동 생성
2. **자동 업데이트** — 기존 파일이 있으면 diff 분석 후 개선사항 적용
3. **모노레포 지원** — 각 워크스페이스마다 중첩 지시문 파일 생성
4. **프레임워크 감지** — Next.js, TypeScript/Node.js 패턴 자동 적용

## 실행 시점

- 새 프로젝트 시작 시 루트 지시문 생성
- 워크스페이스 추가/삭제 후 규칙 파일 업데이트
- 주요 의존성 변경 후 문서 동기화
- 프로젝트 구조 리팩토링 후 라우팅 정보 갱신

## 핵심 원칙

- **파일당 500라인 제한**
- **이모지 금지, 군더더기 금지** — 모든 줄은 실행 가능해야 함
- **중앙 통제 + 위임** — 루트 파일이 전문 파일로 라우팅
- **자가 치유** — 규칙이 코드와 괴리될 때 업데이트 트리거
- **발견 가능성** — 의심스러우면 파일 생성

## 실행 프로토콜

### Step 0: 모드 판단

```bash
ls CLAUDE.md AGENTS.md 2>/dev/null | head -n 1 >/dev/null && echo "UPDATE_MODE" || echo "CREATE_MODE"
```

### Step 1: 프로젝트 분석

```bash
ls package.json tsconfig.json 2>/dev/null
find . -maxdepth 3 -type d ! -path "*/node_modules/*" ! -path "*/.git/*"
cat package.json | grep -A 10 '"workspaces"'
ls pnpm-workspace.yaml turbo.json 2>/dev/null
ls README.md CLAUDE.md AGENTS.md .claude/rules/*.md 2>/dev/null
```

판단 항목:

1. 프로젝트 유형 (Monorepo / Backend / Frontend / Fullstack)
2. 주요 프레임워크 (Next.js / Express / NestJS)
3. 워크스페이스 구조 (apps/_, packages/_, services/\*)
4. 기존 컨벤션 (.eslintrc, .prettierrc)

### Step 2: 프로젝트 유형 감지

**MONOREPO 신호:**

- 루트 package.json에 "workspaces" 필드
- pnpm-workspace.yaml 또는 turbo.json 존재
- apps/, packages/, services/ 폴더에 자체 package.json

**FRONTEND (Next.js) 신호:**

- 프레임워크: next
- 파일: app/, pages/, components/

**BACKEND (Node.js) 신호:**

- 프레임워크: express, nestjs, fastify
- 파일: src/, routes/, controllers/

### Step 3: 업데이트 모드

```bash
cat CLAUDE.md AGENTS.md 2>/dev/null
find apps packages services -maxdepth 1 -type d -exec sh -c 'ls {}/package.json 2>/dev/null && echo {}' \; 2>/dev/null
```

### Step 4: 중첩 파일 생성 규칙

다음 중 하나라도 존재하면 중첩 지시문 파일(AGENTS.md 또는 CLAUDE.md) 생성:

- 별도 package.json 존재 (모노레포 워크스페이스)
- 프레임워크 경계 (apps/web vs services/api)
- 고유 런타임 환경 (Edge Functions, Workers)

### Step 5: 루트 지시문 생성 스키마

````markdown
# 프로젝트 규칙

## 개요

[1-2문장: 무엇을, 누구를 위해, 왜]

## 기술 스택

- 런타임: [Node.js 버전]
- 빌드 시스템: [Turborepo / Nx]
- 언어: [TypeScript 버전]
- 주요 라이브러리: [핵심 3-5개]

## 명령어

```bash
dev:   [명령어]
build: [명령어]
test:  [명령어]
lint:  [명령어]
```
````

## 아키텍처

[간소화된 트리, 최대 15줄]

## 골든 룰

### 불변

### 해야 할 것

### 하지 말아야 할 것

## 표준

- 파일: [네이밍 컨벤션]
- 커밋: [형식]

## 컨텍스트 라우팅

- **[작업/영역](./경로/AGENTS.md 또는 ./경로/CLAUDE.md)** — 읽어야 할 때

````

### Step 6: 프레임워크별 규칙

**Next.js (App Router):**
- 기본으로 Server Components 사용
- Server Actions로 mutation
- SEO를 위한 Metadata API
- 정당한 이유 없이 'use client' 금지

**TypeScript/Node.js:**
- strict mode 유지
- 외부 API 응답은 Zod 검증
- 비즈니스 로직은 서비스 레이어에
- 명시적 any 사용 금지

### Step 7: 출력 파일 선택

```bash
echo "claude   -> CLAUDE.md"
echo "codex    -> AGENTS.md"
echo "opencode -> AGENTS.md"
echo "cursor   -> .cursor/rules/frontend.mdc (+ .cursorrules)"
echo "copilot  -> .github/copilot-instructions.md"
echo "gemini   -> GEMINI.md"
````

### Step 8: 검증

```bash
for f in CLAUDE.md AGENTS.md; do
  [ -f "$f" ] || continue
  wc -l "$f"
  grep -E '[\x{1F600}-\x{1F64F}]' "$f" && echo "EMOJI_FOUND: $f" || echo "OK: $f"
  grep -o '\./[^)]*' "$f" | while read path; do
    ls "$path" 2>/dev/null || echo "BROKEN($f): $path"
  done
done
```

체크리스트:

- [ ] 파일당 500줄 미만
- [ ] 이모지 없음
- [ ] 모든 명령어 실행 가능
- [ ] 컨텍스트 라우팅 경로 유효

## 예외 처리

| 상황                     | 조치                                      |
| ------------------------ | ----------------------------------------- |
| 기술 스택 판단 불가      | 사용자에게 확인 요청                      |
| 혼합/불명확한 컨벤션     | 충돌 문서화, 명시적 규칙 선택             |
| 최소 프로젝트 (< 5 파일) | 단일 간결한 루트 지시문 파일 (100줄 미만) |
| 기존 규칙 파일 존재      | 유용한 내용 보존, diff 분석 후 개선       |
| 기존 파일이 최신 상태    | "변경사항 없음" 메시지 출력 후 종료       |

## Related Files

| File                    | Purpose                      |
| ----------------------- | ---------------------------- |
| `/CLAUDE.md`            | Claude Code 루트 규칙 파일   |
| `/AGENTS.md`            | 루트 규칙 파일               |
| `/apps/*/CLAUDE.md`     | 앱별 Claude 규칙             |
| `/apps/*/AGENTS.md`     | 앱별 Codex/OpenCode 규칙     |
| `/packages/*/CLAUDE.md` | 패키지별 Claude 규칙         |
| `/packages/*/AGENTS.md` | 패키지별 Codex/OpenCode 규칙 |
