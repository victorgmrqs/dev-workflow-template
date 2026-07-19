# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) · versionamento: [SemVer](https://semver.org/lang/pt-BR/).

## [Unreleased]

### Planejado
- Emagrecer `product-manager` (mover frameworks para referência sob demanda) — FEAT-04.2
- Hooks de enforcement: docs-guard no Stop, lint no PostToolUse — EPIC-06
- `/sync-assets` para derivar `.cursor`/`.github` da fonte canônica — EPIC-07

## [0.1.0] — 2026-07-19

### Added
- Estrutura de plugin (`.claude-plugin/plugin.json`) + marketplace próprio (`marketplace.json`).
- Skills de execução promovidas dos projetos reais (sc-api/sc-frontend/stealth-meeting-copilot) e parametrizadas via `.claude/workflow.config.yaml`: `task`, `code-review-task` (com packs de bug-hunt `python-async`, `react-next`, `electron-ts`, `generic`), `docs-sync`.
- Skill `ticket-creator`: plano/FDD/épico → Epics + Tasks no Jira via MCP, com o padrão de ticket (título prefixado, 5 seções, cenários de teste obrigatórios, evidência por tipo) — substitui a instrução global `~/.claude/jira-ticket-pattern.md`.
- Meta-skills: `setup-project` (gera config + CLAUDE.md ≤80 linhas + docs-guard + PR template) e `generate-rules` (rules path-scoped por stack).
- Skills de planejamento herdadas do template MBA: `product-manager`, `hld-creator`, `fdd-creator`, `implementation-plan-creator`, `generate-test-guide`.
- Agents com model routing: `implementer`/`test-writer` (sonnet), `explorer` (haiku), `reviewer`/`architect`/`researcher` (opus).
- Templates: `workflow.config.yaml`, `task-brief.schema.yaml`, `CLAUDE.template.md`, `docs-guard.sh`, `pull_request_template.md`.
- Hook `SessionStart` indicando estado de configuração do workflow no projeto.
