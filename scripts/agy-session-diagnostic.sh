#!/usr/bin/env sh

# Antigravity PreInvocation hook. It is intentionally read-only and emits
# context only for the first model invocation of a conversation.
set -eu

payload=$(cat)
if ! printf '%s' "$payload" | grep -Eq '"invocationNum"[[:space:]]*:[[:space:]]*0'; then
  printf '%s\n' '{"injectSteps":[]}'
  exit 0
fi

if [ -f .dev-workflow/workflow.config.yaml ]; then
  message='dev-workflow: configured (.dev-workflow/workflow.config.yaml). Skills: /task, /code-review-task, /docs-sync.'
elif [ -f .claude/workflow.config.yaml ]; then
  message='dev-workflow: legacy Claude configuration detected (.claude/workflow.config.yaml). It remains supported; run /setup-project to migrate to .dev-workflow/workflow.config.yaml.'
elif [ -d .git ]; then
  message='dev-workflow: installed but not configured in this project. Run /setup-project.'
else
  printf '%s\n' '{"injectSteps":[]}'
  exit 0
fi

printf '{"injectSteps":[{"ephemeralMessage":"%s"}]}\n' "$message"
