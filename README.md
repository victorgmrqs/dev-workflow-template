# dev-workflow

Golden template de desenvolvimento assistido por IA para **Claude Code e Google Antigravity CLI (`agy`)**: planejamento (PRD → HLD → FDD → plano), execução (ticket → PR com checkpoints humanos e gates automatizados) e agentes especializados, parametrizado por projeto via uma configuração canônica.

Origem: consolidação do workflow validado em 3 projetos reais (backend Python/FastAPI, frontend Next.js, app Electron) + práticas oficiais da Anthropic. Diagnóstico completo em `mba-ia-dev-workflow/RELATORIO-GOLDEN-TEMPLATE.md`.

## Instalação

### Como plugin (recomendado — atualização versionada)

Claude Code:

```
/plugin marketplace add victorgmrqs/dev-workflow-template
/plugin install dev-workflow@victorgmrqs
```

Antigravity CLI:

```bash
agy plugin install /caminho/para/dev-workflow-template
# ou, após publicação, use a origem Git suportada pela sua versão do agy
agy plugin list
```

O Agy deve ter o servidor `MCP_DOCKER` configurado quando Jira/Confluence forem usados. O plugin não inicia nem empacota um segundo gateway.

Diagnóstico da integração:

```bash
scripts/check-mcp-docker.sh
```

### Como template de repositório

Use "Use this template" no GitHub. Sem instalação como plugin, você não recebe atualizações versionadas.

## Quick start (novo projeto)

```
/setup-project          # entrevista → .dev-workflow/workflow.config.yaml + AGENTS.md
/generate-rules         # rules da stack em .agents/rules e/ou .claude/rules
/generate-test-guide    # skill de guia de testes do projeto
```

Planejamento (uma vez por produto/feature grande):

```
/product-manager → /hld-creator → /fdd-creator → /implementation-plan-creator → /ticket-creator
```

Execução (dia a dia):

```
/task SKC-12            # brief → aprovação → branch → implementação → testes
                        # → /docs-sync → DoD → /code-review-task (gate) → entrega
```

## Estrutura

```
.claude-plugin/    manifesto + marketplace Claude Code
plugin.json        manifesto nativo Antigravity
hooks.json         hooks nativos Antigravity
skills/
  task/                      execução de ticket (8 fases, 2 checkpoints, 1 gate)
  code-review-task/          gate de review + packs de bug-hunt por stack
  docs-sync/                 "código alterado = doc alterada no mesmo branch"
  setup-project/             gera a configuração do projeto
  generate-rules/            gera rules path-scoped da stack
  product-manager/           PRD, priorização, épicos
  hld-creator/               High-Level Design + ADRs
  fdd-creator/               Feature Design Docs (a matriz de erros §6 vira testes)
  implementation-plan-creator/  plano de tasks por dependência
  ticket-creator/            plano/FDD → Epics + Tasks no Jira (padrão de ticket)
  generate-test-guide/       gera a skill de testes do projeto
agents/            model routing: implementer/test-writer (sonnet),
                   explorer (haiku), reviewer/architect/researcher (opus)
hooks/             SessionStart: estado da configuração
templates/         workflow.config.yaml, task-brief.schema, CLAUDE.template,
                   docs-guard.sh, pull_request_template
integrations/      contratos de capabilities MCP (MCP_DOCKER/Atlassian)
scripts/           diagnóstico Agy + validação do pacote
tests/             testes de contrato do adapter Agy
```

## Princípios

1. **Motor vs configuração** — as skills são compartilhadas; tudo que é do projeto vive em `.dev-workflow/workflow.config.yaml` (`.claude/workflow.config.yaml` permanece como fallback legado).
2. **Contexto JIT** — o `/task` carrega só o FDD do domínio; `context_files` é curto; `AGENTS.md` contém fatos comuns; rules carregam por escopo.
3. **Checkpoints + gates** — humano aprova o brief (antes de codar) e o DoD (antes do review); o gate `/code-review-task` bloqueia commit com bloqueador aberto.
4. **Docs como parte da entrega** — toda tarefa atualiza o changelog com link para o card e o Histórico de entregas no Confluence; impactos técnicos, funcionais e operacionais são classificados no brief, aplicados pelo `/docs-sync` e verificados pelo review/CI. Veja [`docs/documentation-policy.md`](docs/documentation-policy.md).
5. **Papel certo por tarefa** — Claude pode aplicar aliases por agent; no Agy os subagentes herdam o modelo do pai, preservando papel e permissões sem prometer paridade de modelo.
6. **Melhoria nasce no projeto, mora no template** — customização útil em um projeto sobe por PR aqui e chega aos demais via atualização do plugin.

## Migrando um projeto existente (sc-api, sc-frontend, etc.)

1. Instale o plugin no projeto.
2. Rode `/setup-project` — ele detecta stack/comandos/docs e gera `.dev-workflow/workflow.config.yaml`; uma config Claude antiga é preservada durante a migração.
3. Compare as skills locais (`.claude/skills/task`, `code-review-task`, `docs-sync`) com as do plugin; mova qualquer regra específica ainda não coberta para `workflow.config.yaml` (`dod_extra`, `docs_map`, `domains`).
4. Apague as skills locais — as do plugin assumem (namespace `/dev-workflow:task` ou `/task` se não houver conflito).

## Compatibilidade e evolução

- O mesmo diretório `skills/` e `agents/` é validado pelos dois loaders; detalhes exclusivos têm fallback explícito.
- Atlassian é resolvido por capabilities no servidor `MCP_DOCKER`, não por nomes rígidos de tools.
- Rode `scripts/validate-plugin.sh` antes de publicar.
- Revisão trimestral: changelogs Claude Code e Antigravity CLI → issues neste repo.

## Migração para Antigravity CLI (`agy`)

A análise arquitetural, a matriz de compatibilidade, a arquitetura proposta e o plano incremental estão em [`docs/agy-migration/`](docs/agy-migration/README.md). O material preserva o plugin Claude atual e propõe um núcleo compartilhado com adapters por plataforma.
