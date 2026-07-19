# dev-workflow

Golden template de desenvolvimento assistido por IA para Claude Code: **planejamento** (PRD → HLD → FDD → plano), **execução** (ticket → PR com checkpoints humanos e gates automatizados) e **model routing** (cada tipo de tarefa no modelo certo), parametrizado por projeto via um único arquivo de configuração.

Origem: consolidação do workflow validado em 3 projetos reais (backend Python/FastAPI, frontend Next.js, app Electron) + práticas oficiais da Anthropic. Diagnóstico completo em `mba-ia-dev-workflow/RELATORIO-GOLDEN-TEMPLATE.md`.

## Instalação

### Como plugin (recomendado — atualização versionada)

```
/plugin marketplace add victorgmrqs/dev-workflow-template
/plugin install dev-workflow@victorgmrqs
```

### Como template de repositório

Use "Use this template" no GitHub (ou copie `skills/`, `agents/`, `hooks/` para `.claude/` do projeto). Sem o plugin, você não recebe atualizações — prefira o plugin.

## Quick start (novo projeto)

```
/setup-project          # entrevista → .claude/workflow.config.yaml + CLAUDE.md enxuto
/generate-rules         # rules path-scoped da sua stack em .claude/rules/
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
.claude-plugin/    plugin.json + marketplace.json
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
```

## Princípios

1. **Motor vs configuração** — as skills são genéricas; tudo que é do projeto (Jira, branches, comandos, gates, doc-map, domínios) vive em `.claude/workflow.config.yaml`.
2. **Contexto JIT** — o `/task` carrega só o FDD do domínio do ticket; `context_files` tem teto curto; CLAUDE.md ≤80 linhas; rules carregam por glob.
3. **Checkpoints + gates** — humano aprova o brief (antes de codar) e o DoD (antes do review); o gate `/code-review-task` bloqueia commit com bloqueador aberto.
4. **Docs como parte da entrega** — `docs_map` aplicado pelo `/docs-sync`, verificado pelo review e pelo `docs-guard.sh` no CI.
5. **Modelo certo por tarefa** — implementação em Sonnet, exploração em Haiku, review/arquitetura em Opus; sempre aliases, nunca IDs fixos de modelo.
6. **Melhoria nasce no projeto, mora no template** — customização útil em um projeto sobe por PR aqui e chega aos demais via atualização do plugin.

## Migrando um projeto existente (sc-api, sc-frontend, etc.)

1. Instale o plugin no projeto.
2. Rode `/setup-project` — ele detecta stack/comandos/docs e gera a config a partir do que já existe.
3. Compare as skills locais (`.claude/skills/task`, `code-review-task`, `docs-sync`) com as do plugin; mova qualquer regra específica ainda não coberta para `workflow.config.yaml` (`dod_extra`, `docs_map`, `domains`).
4. Apague as skills locais — as do plugin assumem (namespace `/dev-workflow:task` ou `/task` se não houver conflito).

## Compatibilidade e evolução

- Frontmatter usa apenas aliases de modelo (`sonnet`, `opus`, `haiku`) — novas gerações são absorvidas sem mudança.
- `context: fork` + `agent:` nas skills de review/docs: se a versão instalada do Claude Code não suportar algum campo, a skill degrada para o modelo da sessão (sem quebrar).
- Revisão trimestral: changelog do Claude Code + releases da Anthropic → issues neste repo.
