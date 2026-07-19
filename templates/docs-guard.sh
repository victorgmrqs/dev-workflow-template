#!/usr/bin/env bash
# docs-guard — rede determinística: código alterado exige doc alterada no mesmo diff.
# Instalado por /setup-project (ajuste SRC_PATTERN/TEST_PATTERN à stack) e rodado no CI
# e pelo /code-review-task. Complementa (não substitui) o check semântico da skill.
set -euo pipefail

BASE_BRANCH="${BASE_BRANCH:-development}"
SRC_PATTERN="${SRC_PATTERN:-^src/}"            # código de produção
TEST_PATTERN="${TEST_PATTERN:-(\.test\.|\.spec\.|^tests?/)}"
CHANGELOG="${CHANGELOG:-CHANGELOG.md}"

files="$(git diff --name-only "origin/${BASE_BRANCH}"...HEAD 2>/dev/null || git diff --name-only "${BASE_BRANCH}"...HEAD)"

src_changed="$(echo "$files" | grep -E "$SRC_PATTERN" | grep -vE "$TEST_PATTERN" || true)"
fail=0

if [[ -n "$src_changed" ]]; then
  if ! echo "$files" | grep -qx "$CHANGELOG"; then
    echo "❌ docs-guard: código de produção alterado sem entrada no ${CHANGELOG} [Unreleased]."
    fail=1
  fi
  if ! echo "$files" | grep -qE "$TEST_PATTERN"; then
    echo "❌ docs-guard: código de produção alterado sem nenhum teste no diff."
    fail=1
  fi
fi

if [[ "$fail" -eq 0 ]]; then
  echo "✅ docs-guard: ok"
fi
exit "$fail"
