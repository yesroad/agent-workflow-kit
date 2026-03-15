#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

TARGET_DIR="${1:-$BUILD_DIR}"
require_dir "$TARGET_DIR"

log_step "Codex 빌드 검증"

patterns=(
  'Task\('
  '\.claude/'
  '@\.claude/'
  '^tools:'
  '^model:'
  '^allowed-tools:'
  '\bhaiku\b'
  '\bsonnet\b'
  '\bopus\b'
  'TeamCreate'
  'Task 병렬'
  '일반 Task'
)

for pattern in "${patterns[@]}"; do
  rg_args=("$TARGET_DIR" "-S")
  case "$pattern" in
    '\.claude/'|'@\.claude/')
      rg_args+=(-g '!**/skills/docs-creator/SKILL.md')
      ;;
  esac

  if rg -n "$pattern" "${rg_args[@]}" >/dev/null 2>&1; then
    echo "금지 패턴 발견: $pattern"
    rg -n "$pattern" "${rg_args[@]}" || true
    exit 1
  fi
done

required_paths=(
  "$TARGET_DIR/agents"
  "$TARGET_DIR/commands"
  "$TARGET_DIR/instructions"
  "$TARGET_DIR/rules/core"
  "$TARGET_DIR/skills"
)

for path in "${required_paths[@]}"; do
  [[ -e "$path" ]] || fail "필수 경로 없음 → $path"
done

STAGE_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

"$SCRIPT_DIR/install.sh" "$STAGE_DIR" "$TARGET_DIR" > /dev/null
validate_installed_markdown_refs "$STAGE_DIR"

[[ -f "$STAGE_DIR/AGENTS.md" ]] || fail "루트 AGENTS.md 없음"

docs_creator="$STAGE_DIR/.agents/skills/docs-creator/SKILL.md"
if [[ -f "$docs_creator" ]]; then
  if rg -n '\| Codex \| `CLAUDE\.md` \|' "$docs_creator" -S >/dev/null 2>&1; then
    fail "docs-creator에 잘못된 Codex/CLAUDE.md 매핑이 남아 있음"
  fi

  if rg -n '^\s*\.codex/docs/library/\[lib\]/index\.md$' "$docs_creator" -S >/dev/null 2>&1; then
    fail "docs-creator의 CLAUDE.md 예제가 Codex 경로로 오염됨"
  fi
fi

log_success "검증 완료"
