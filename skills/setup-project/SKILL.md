---
name: setup-project
description: >
  Configura o dev-workflow em um projeto: analisa a stack, entrevista o
  usuário sobre tracker/branches/gates e gera configuração canônica em
  .dev-workflow/, AGENTS.md, adapters de plataforma, docs-guard.sh e PR template.
  Rode uma vez por projeto (ou para reconfigurar).
  Uso: /setup-project
disable-model-invocation: true
---

# Skill: /setup-project

## Objetivo

Deixar um projeto operacional com o dev-workflow em uma sessão: tudo que as skills `/task`, `/code-review-task` e `/docs-sync` precisam vem de `.dev-workflow/workflow.config.yaml`.

## Etapa 1 — Análise automática (antes de perguntar)

Detecte sozinho e apresente para confirmação:

- **Stack** (manifesto de deps, configs de build/test) → proposta de `review_pack` (`python-async` | `react-next` | `electron-ts` | `generic`) e de `commands.*` (lint/typecheck/test/coverage/build/e2e) a partir dos scripts existentes.
- **Git**: branch base existente (`development`? `main`?), padrão de commits do histórico recente.
- **Docs existentes**: presença de `docs/` (PRD/HLD/FDDs/domain-context/ADRs), CHANGELOG, `API_SPEC`/`ENTITIES`/`INTEGRATIONS`/`ARCHITECTURE` — vira proposta de `docs_map`, `context_files` e destinos técnicos/funcionais/operacionais.
- **Multi-repo**: docs canônicos em repo irmão (referências `../` nos docs)?

## Etapa 2 — Entrevista (apenas o que não dá para detectar)

Pergunte de forma agrupada, com as propostas da Etapa 1 como default:

1. **Tracker:** Jira ou modo local? Para Jira, use o servidor MCP configurado (default `MCP_DOCKER`) e resolva `atlassian.resources.list` conforme `../../integrations/atlassian-mcp.md`; não presuma o nome da tool. Pergunte project key/URL apenas se não forem detectáveis. Nomes das colunas divergem do padrão? Há guard multi-repo?
2. **Gates:** threshold de coverage? paths com threshold maior? e2e obrigatório em que fluxos?
3. **Domínios:** prefixos de domínio → glob do FDD correspondente (proponha a partir dos FDDs achados).
4. **Evidência:** `.http`, screenshot ou saída de CLI? Onde salvar?
5. **Confluence:** espelhar docs de negócio? (space, páginas)
6. **DoD extra:** itens específicos do projeto (ex: "responsivo ≥360px", "custo de IA validado").

## Etapa 3 — Geração

1. **`.dev-workflow/workflow.config.yaml`** — a partir de `../../templates/workflow.config.yaml`, relativo a esta skill. Preencha `platforms`, `tracker.mcp_server`/`confluence.mcp_server`, `documentation_policy` e valide todos os campos. Changelog e Histórico de entregas permanecem obrigatórios para toda tarefa; com `tracker.provider: jira`, habilite Confluence, localize a página aprovada e grave seu `page_id`. Se existir apenas `.claude/workflow.config.yaml`, migre por cópia e preserve o legado; nunca o apague automaticamente.
2. **`AGENTS.md`** — a partir de `../../templates/AGENTS.template.md`. **Teto: 80 linhas.** Só fatos: overview, stack, restrições, comandos, workflow e ponteiros para docs. Preserve um arquivo existente e proponha diff antes de reescrever.
3. **Contexto de plataforma:** para `claude-code`, mantenha/crie `CLAUDE.md` enxuto (pode apontar para `AGENTS.md`); para `antigravity`, `AGENTS.md` é o contexto comum e `GEMINI.md` só deve existir quando houver instruções específicas do harness.
4. **`scripts/docs-guard.sh`** — a partir de `../../templates/docs-guard.sh`, com os paths/padrões da config. Sugira o passo correspondente no CI.
5. **`.github/pull_request_template.md`** — a partir do template do plugin, preservando um existente.
6. **`.gitignore`** — garanta `task-brief.yaml` e `.dev-workflow/state/` quando estado retomável estiver habilitado.

## Etapa 4 — Próximos passos (apresente ao final)

- `/generate-rules` — gerar rules path-scoped nos targets declarados em `platforms`
- `/generate-test-guide` — gerar a skill de guia de testes do projeto
- Se o projeto ainda não tem docs de planejamento: `/product-manager` → `/hld-creator` → `/fdd-creator` → `/implementation-plan-creator`
- Primeiro ticket: `/task <ID>`

## Restrições

- Não invente valores: o que não foi detectado nem respondido fica explícito como pendência no config (comentário `# TODO`).
- Não sobrescreva arquivos existentes sem mostrar o diff e obter confirmação.
