---
name: setup-project
description: >
  Configura o dev-workflow em um projeto: analisa a stack, entrevista o
  usuário sobre tracker/branches/gates e gera .claude/workflow.config.yaml,
  CLAUDE.md enxuto (≤80 linhas), docs-guard.sh e pull_request_template.md.
  Rode uma vez por projeto (ou para reconfigurar).
  Uso: /setup-project
disable-model-invocation: true
---

# Skill: /setup-project

## Objetivo

Deixar um projeto operacional com o dev-workflow em uma sessão: tudo que as skills `/task`, `/code-review-task` e `/docs-sync` precisam vem do `.claude/workflow.config.yaml` gerado aqui.

## Etapa 1 — Análise automática (antes de perguntar)

Detecte sozinho e apresente para confirmação:

- **Stack** (manifesto de deps, configs de build/test) → proposta de `review_pack` (`python-async` | `react-next` | `electron-ts` | `generic`) e de `commands.*` (lint/typecheck/test/coverage/build/e2e) a partir dos scripts existentes.
- **Git**: branch base existente (`development`? `main`?), padrão de commits do histórico recente.
- **Docs existentes**: presença de `docs/` (PRD/HLD/FDDs/domain-context/ADRs), CHANGELOG, `API_SPEC`/`ENTITIES`/`INTEGRATIONS`/`ARCHITECTURE` — vira proposta de `docs_map` e `context_files`.
- **Multi-repo**: docs canônicos em repo irmão (referências `../` nos docs)?

## Etapa 2 — Entrevista (apenas o que não dá para detectar)

Pergunte de forma agrupada, com as propostas da Etapa 1 como default:

1. **Tracker:** Jira (project key, URL — descubra o cloudId via MCP `getAccessibleAtlassianResources`) ou modo local? Nomes das colunas divergem do padrão To Do/In Progress/In Review/Done? Guard de prefixo multi-repo (ex: tickets `[frontend]` pertencem a outro repo)?
2. **Gates:** threshold de coverage? paths com threshold maior? e2e obrigatório em que fluxos?
3. **Domínios:** prefixos de domínio → glob do FDD correspondente (proponha a partir dos FDDs achados).
4. **Evidência:** `.http`, screenshot ou saída de CLI? Onde salvar?
5. **Confluence:** espelhar docs de negócio? (space, páginas)
6. **DoD extra:** itens específicos do projeto (ex: "responsivo ≥360px", "custo de IA validado").

## Etapa 3 — Geração

1. **`.claude/workflow.config.yaml`** — a partir de `${CLAUDE_PLUGIN_ROOT}/templates/workflow.config.yaml`, preenchido com as respostas. Valide: todo campo referenciado pelas skills presente; comandos executam sem erro de sintaxe.
2. **`CLAUDE.md`** — a partir de `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.template.md`. **Teto: 80 linhas.** Só fatos: overview em 3 frases, stack, restrições não negociáveis, comandos, fluxo de trabalho (referência às skills), ponteiros para docs (sem colar conteúdo). Se já existir CLAUDE.md, proponha a versão enxuta como diff e deixe o usuário decidir.
3. **`scripts/docs-guard.sh`** — a partir de `${CLAUDE_PLUGIN_ROOT}/templates/docs-guard.sh`, com os paths/padrões da config. Sugira o passo correspondente no CI.
4. **`.github/pull_request_template.md`** — a partir do template do plugin, com o checklist do DoD do projeto. Não sobrescreva um existente sem confirmação.
5. **`.gitignore`** — garanta a linha `task-brief.yaml`.

## Etapa 4 — Próximos passos (apresente ao final)

- `/generate-rules` — gerar rules path-scoped da stack em `.claude/rules/`
- `/generate-test-guide` — gerar a skill de guia de testes do projeto
- Se o projeto ainda não tem docs de planejamento: `/product-manager` → `/hld-creator` → `/fdd-creator` → `/implementation-plan-creator`
- Primeiro ticket: `/task <ID>`

## Restrições

- Não invente valores: o que não foi detectado nem respondido fica explícito como pendência no config (comentário `# TODO`).
- Não sobrescreva arquivos existentes sem mostrar o diff e obter confirmação.
