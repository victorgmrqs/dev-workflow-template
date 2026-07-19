---
name: docs-sync
description: >
  Sincroniza a documentação com as mudanças de código do branch atual:
  aplica o docs_map do workflow.config.yaml ("mudou X → atualiza doc Y")
  e, se habilitado, espelha docs de negócio no Confluence via MCP.
  Chamada pela Fase 5 do /task ou avulsa após mudanças manuais.
  Uso: /docs-sync [TICKET-ID]
disable-model-invocation: true
argument-hint: "[TICKET-ID]"
context: fork
---

# Skill: /docs-sync

## Objetivo

Garantir as invariantes: **toda tarefa = registro documental**, **código alterado = documentação técnica correspondente no mesmo branch** e **mudança funcional = documentação funcional no Confluence**. Esta skill aplica as atualizações; a verificação (gate) é do `/code-review-task` + docs-guard do CI.

## Etapa 0 — Configuração

Leia `.dev-workflow/workflow.config.yaml`, com fallback legado para `.claude/workflow.config.yaml` e aviso. Consuma `git.base_branch`, `tracker`, `docs_map`, `documentation_policy`, `confluence` e `evidence`. Leia `task-brief.yaml`; sem config, pare e peça `/setup-project`.

## Etapa 1 — Detectar o que mudou

```bash
git diff <base>...HEAD --name-only    # pré-commit: git diff <base> --name-only + untracked
```

Inclua o diff do manifesto de dependências (ex: `package.json`, `pyproject.toml`) para detectar mudanças de versão.

## Etapa 2 — Registro obrigatório da tarefa

Atualize `documentation_policy.changelog.path` mesmo quando nenhuma linha de `docs_map` casar e mesmo para `chore`, `refactor`, docs ou infraestrutura.

- Escreva uma entrada curta em `[Unreleased]`, na categoria aprovada no brief: `Added`, `Changed`, `Fixed`, `Security`, `Deprecated`, `Removed` ou `Maintenance`.
- Descreva o **resultado observável** em uma linha; não replique detalhes de implementação.
- Com Jira, termine obrigatoriamente com link Markdown para o card: `([<TICKET-ID>](<tracker.url>/browse/<TICKET-ID>))`. ID sem link não satisfaz o gate.
- Em modo local, use `(<TICKET-ID>)` e registre que não há card externo.
- Não duplique uma entrada existente do mesmo ticket e mesmo resultado; complemente-a quando necessário.

## Etapa 3 — Aplicar o docs_map (TODAS as linhas que casarem)

Para cada entrada do `docs_map` cujo padrão `if_diff_touches` casa com arquivos do diff, atualize os docs listados em `update`. Regras de escrita:

- Atualize **apenas** o que o diff justifica — sem reescrever seções intactas.
- O changelog global já foi tratado na Etapa 2; uma regra do mapa pode exigir detalhes técnicos adicionais, mas não substitui esse registro.
- Datas absolutas (YYYY-MM-DD); IDs de regra e de ticket sempre referenciados.
- Regra de negócio nova/modificada: atualizar `docs/domain-context.md` **e** marcar para a Etapa 3.
- Decisão arquitetural tomada durante a task: novo `docs/adr/ADR-XXX-*.md` + referência no HLD.
- Fluxo/erro novo em domínio com FDD: FDD seções de fluxos e matriz de erros.

## Etapa 4 — Documentação por nível

Use `task-brief.yaml.documentation` como contrato:

- **Técnica — repositório:** implementação, contratos, schemas, ADRs, APIs e runbooks executáveis. Atualize os `targets` no mesmo branch.
- **Funcional — Confluence:** finalidade, comportamento, regras, fluxos, permissões, limitações e uso. Atualize páginas existentes organizadas por domínio; não crie uma página por ticket.
- **Operacional:** detalhes executáveis/IaC ficam no repositório; hospedagem, ambientes, URLs, ownership e diagramas de alto nível ficam no Confluence. Nunca documente segredos.
- Todo nível `required: false` precisa de `not_applicable_reason` específico. Campo vazio é pendência bloqueante.

## Etapa 5 — Confluence (quando `confluence.enabled: true`)

Política: o repositório é fonte de verdade da documentação **técnica**; o Confluence é fonte de verdade da documentação **funcional** e da visão operacional de alto nível.

1. Faça o pre-flight de `../../integrations/atlassian-mcp.md` no servidor `confluence.mcp_server` (default `MCP_DOCKER`). Resolva `confluence.spaces.list`, `confluence.pages.list`, `confluence.page.read` e `confluence.page.update` por descrição/schema.
2. Localize e leia a página atual antes de editar.
3. Atualize pela capability resolvida, refletindo a mesma mudança e preservando conteúdo não relacionado — não reescreva a página inteira.
4. Registre **toda tarefa** na página estável de `documentation_policy.delivery_log` com data, ticket/link, tipo, resumo, impacto funcional e links de documentação. Leia antes de editar e não duplique o ticket.
5. Página/space/capability inexistente: **não crie por conta própria**; registre como pendência externa no relatório. A criação exige aprovação prévia e depois o `page_id` deve ser salvo na config.

## Etapa 6 — Relatório

```
## Docs Sync — <TICKET-ID>

Atualizados:
- CHANGELOG.md ([Unreleased] > Added; card: <link>)
- <doc> (<o que mudou>)

Níveis:
- técnico: atualizado <links> | não aplicável: <justificativa>
- funcional: atualizado <links> | não aplicável: <justificativa>
- operacional: atualizado <links> | não aplicável: <justificativa>

Confluence:
- Histórico de entregas: [x] registrado <link> | [ ] pendente externo: <motivo>
- páginas funcionais/operacionais: <links ou justificativa>

Sem mudança necessária: <docs do map que não casaram>
```

## Restrições

- Não inventar conteúdo: cada atualização deve ser rastreável a uma linha do diff.
- Nunca concluir com changelog ausente, sem link para o card Jira ou com justificativa de não aplicabilidade vazia.
- Não criar páginas/spaces no Confluence sem aprovação do usuário.
- Não tocar em código — esta skill só escreve documentação.
