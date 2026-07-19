#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

python3 -m json.tool plugin.json >/dev/null
python3 -m json.tool hooks.json >/dev/null
python3 -m json.tool .claude-plugin/plugin.json >/dev/null
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
python3 -m json.tool hooks/hooks.json >/dev/null

sh -n scripts/agy-session-diagnostic.sh
sh -n scripts/check-mcp-docker.sh
bash -n templates/docs-guard.sh
bash -n tests/test-docs-guard.sh
bash -n skills/product-manager/scripts/validate-prd.sh
PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/dev-workflow-pycache" \
  python3 -m py_compile skills/product-manager/scripts/prioritize.py

if command -v agy >/dev/null 2>&1; then
  agy plugin validate .
else
  printf '%s\n' 'warning: agy not found; native plugin validation skipped' >&2
fi

printf '%s\n' 'dev-workflow plugin validation: ok'
