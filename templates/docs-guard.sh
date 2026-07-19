#!/usr/bin/env bash
# docs-guard — toda tarefa exige changelog vinculado ao card; código exige testes/docs.
# Instalado por /setup-project (ajuste SRC_PATTERN/TEST_PATTERN à stack) e rodado no CI
# e pelo /code-review-task. Complementa (não substitui) o check semântico da skill.
set -euo pipefail

BASE_BRANCH="${BASE_BRANCH:-development}"
SRC_PATTERN="${SRC_PATTERN:-^src/}"            # código de produção
TEST_PATTERN="${TEST_PATTERN:-(\.test\.|\.spec\.|^tests?/)}"
CHANGELOG="${CHANGELOG:-CHANGELOG.md}"

base_ref="${BASE_BRANCH}"
if git rev-parse --verify "origin/${BASE_BRANCH}" >/dev/null 2>&1; then
  base_ref="origin/${BASE_BRANCH}"
fi
files="$({
  git diff --name-only "${base_ref}"...HEAD
  git diff --name-only
  git ls-files --others --exclude-standard
} | sort -u)"

src_changed="$(echo "$files" | grep -E "$SRC_PATTERN" | grep -vE "$TEST_PATTERN" || true)"
task_changed="$(echo "$files" | grep -v '^task-brief\.yaml$' | sed '/^$/d' || true)"
fail=0

if [[ -n "$task_changed" ]]; then
  if ! echo "$files" | grep -qx "$CHANGELOG"; then
    echo "❌ docs-guard: toda tarefa deve atualizar ${CHANGELOG} [Unreleased]."
    fail=1
  fi

  ticket_id="${TICKET_ID:-}"
  if [[ -z "$ticket_id" ]]; then
    branch_name="$(git branch --show-current)"
    ticket_id="$(echo "$branch_name" | grep -Eo '[A-Z][A-Z0-9]+-[0-9]+' | head -n 1 || true)"
  fi

  if [[ -z "$ticket_id" ]]; then
    echo "❌ docs-guard: informe TICKET_ID ou use o ID do card no nome da branch."
    fail=1
  elif echo "$files" | grep -qx "$CHANGELOG"; then
    changelog_diff="$({
      git diff "${base_ref}"...HEAD -- "$CHANGELOG"
      git diff -- "$CHANGELOG"
    } 2>/dev/null || true)"
    if ! echo "$changelog_diff" | grep -E "^\+.*\[${ticket_id}\]\(https?://[^)]*/browse/${ticket_id}\)" >/dev/null; then
      echo "❌ docs-guard: ${CHANGELOG} deve conter link Markdown para o card ${ticket_id}."
      fail=1
    fi
  fi
fi

if [[ -n "$src_changed" ]]; then
  if ! echo "$files" | grep -qE "$TEST_PATTERN"; then
    echo "❌ docs-guard: código de produção alterado sem nenhum teste no diff."
    fail=1
  fi
fi

if [[ "$fail" -eq 0 ]]; then
  echo "✅ docs-guard: ok"
fi
exit "$fail"
