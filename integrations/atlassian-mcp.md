# Atlassian via MCP_DOCKER

This plugin consumes Jira and Confluence through the MCP server selected by
`integrations.atlassian.mcp_server` (default: `MCP_DOCKER`). The server is
configured by the user/host and is not bundled with the plugin.

## Pre-flight

Before the first Atlassian operation in a workflow:

1. When shell access is available, run `../../scripts/check-mcp-docker.sh`
   relative to this document. A non-zero result blocks external mutations.
2. Inspect the tools exposed by the configured MCP server.
3. Resolve every required capability below to an available tool.
4. Report the resolved mapping once. Never guess a tool that is not exposed.
5. If a required capability is missing, stop before external mutations. Offer
   `tracker.provider: none` for a local-only workflow.

Tool names may be prefixed or normalized by the host. Match by tool description
and input schema first; the names below are aliases, not hard dependencies.

## Capability map

| Capability | Common aliases |
|---|---|
| `atlassian.resources.list` | `getAccessibleAtlassianResources` |
| `jira.issue.read` | `getJiraIssue`, Jira search/fetch |
| `jira.issue.create` | `createJiraIssue` |
| `jira.transitions.list` | `getTransitionsForJiraIssue` |
| `jira.issue.transition` | `transitionJiraIssue` |
| `jira.issue.comment` | `addCommentToJiraIssue` |
| `confluence.spaces.list` | `getConfluenceSpaces` |
| `confluence.pages.list` | `getPagesInConfluenceSpace`, Confluence search |
| `confluence.page.read` | `getConfluencePage`, fetch |
| `confluence.page.update` | `updateConfluencePage` |

## Safety rules

- Reads may run during analysis when the host permits them.
- Creates, transitions, comments, and page updates are external mutations and
  must occur only in the workflow phase already approved by the user.
- Resolve a Jira transition by its destination status (`to.name`), never by
  assuming the transition label or ID.
- Read the current Confluence page before updating it and preserve unrelated
  content. Do not create spaces/pages unless the user explicitly requests it.
- Never print authentication headers, tokens, secrets, or raw MCP environment.
- On partial failure, report what changed remotely and do not retry mutations
  blindly.
