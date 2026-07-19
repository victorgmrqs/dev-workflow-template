#!/usr/bin/env sh

# Read-only diagnostic for the MCP_DOCKER gateway used by Jira/Confluence.
set -eu

found=0
for config in \
  .agents/mcp_config.json \
  "$HOME/.gemini/antigravity-cli/mcp_config.json" \
  "$HOME/.gemini/config/mcp_config.json"
do
  if [ -f "$config" ] && grep -q '"MCP_DOCKER"' "$config"; then
    printf 'MCP_DOCKER config: %s\n' "$config"
    found=1
    break
  fi
done

if [ "$found" -ne 1 ]; then
  printf '%s\n' 'MCP_DOCKER config: not found' >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  printf '%s\n' 'Docker CLI: not found' >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  printf '%s\n' 'Docker engine: unavailable (start Docker Desktop/daemon)' >&2
  exit 2
fi

printf '%s\n' 'Docker engine: available'
if docker mcp tools ls >/dev/null 2>&1; then
  printf '%s\n' 'MCP_DOCKER gateway tools: discoverable'
else
  printf '%s\n' 'MCP_DOCKER gateway tools: unavailable; inspect Docker MCP Toolkit configuration' >&2
  exit 3
fi
