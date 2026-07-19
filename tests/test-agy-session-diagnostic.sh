#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
hook="$repo_root/scripts/agy-session-diagnostic.sh"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

cd "$fixture"
mkdir .git

actual=$(printf '%s' '{"invocationNum":0}' | "$hook")
expected='{"injectSteps":[{"ephemeralMessage":"dev-workflow: installed but not configured in this project. Run /setup-project."}]}'
[ "$actual" = "$expected" ]

actual=$(printf '%s' '{"invocationNum":1}' | "$hook")
[ "$actual" = '{"injectSteps":[]}' ]

mkdir -p .dev-workflow
: > .dev-workflow/workflow.config.yaml
actual=$(printf '%s' '{"invocationNum":0}' | "$hook")
expected='{"injectSteps":[{"ephemeralMessage":"dev-workflow: configured (.dev-workflow/workflow.config.yaml). Skills: /task, /code-review-task, /docs-sync."}]}'
[ "$actual" = "$expected" ]

printf '%s\n' 'agy session diagnostic tests: ok'
