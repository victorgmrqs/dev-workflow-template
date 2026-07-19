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

Garantir a invariante: **código alterado = documentação alterada no mesmo branch**. Esta skill aplica as atualizações; a verificação (gate) é do `/code-review-task` + docs-guard do CI.

## Etapa 0 — Configuração

Leia `.claude/workflow.config.yaml` (`git.base_branch`, `docs_map`, `confluence`, `evidence`). Sem config: pare e peça `/setup-project`.

## Etapa 1 — Detectar o que mudou

```bash
git diff <base>...HEAD --name-only    # pré-commit: git diff <base> --name-only + untracked
```

Inclua o diff do manifesto de dependências (ex: `package.json`, `pyproject.toml`) para detectar mudanças de versão.

## Etapa 2 — Aplicar o docs_map (TODAS as linhas que casarem)

Para cada entrada do `docs_map` cujo padrão `if_diff_touches` casa com arquivos do diff, atualize os docs listados em `update`. Regras de escrita:

- Atualize **apenas** o que o diff justifica — sem reescrever seções intactas.
- CHANGELOG: entrada em `[Unreleased]` na seção certa (Added/Changed/Fixed), com sufixo `(<TICKET-ID>)`; dependências na seção Dependencies com `pacote: x.y.z → a.b.c`.
- Datas absolutas (YYYY-MM-DD); IDs de regra e de ticket sempre referenciados.
- Regra de negócio nova/modificada: atualizar `docs/domain-context.md` **e** marcar para a Etapa 3.
- Decisão arquitetural tomada durante a task: novo `docs/adr/ADR-XXX-*.md` + referência no HLD.
- Fluxo/erro novo em domínio com FDD: FDD seções de fluxos e matriz de erros.

## Etapa 3 — Confluence (somente se `confluence.enabled: true`, e somente docs de NEGÓCIO)

Política: o repositório é fonte de verdade da documentação **técnica**; o Confluence espelha apenas documentação de **negócio** (`confluence.business_docs`: regras de negócio, PRD, roadmap).

1. Localize a página no space `confluence.space` (use `getConfluenceSpaces`/`getPagesInConfluenceSpace` se necessário).
2. Atualize via `updateConfluencePage`, refletindo a mesma mudança — não reescreva a página inteira.
3. Página/space inexistente: **não crie por conta própria**; registre como pendência no relatório.

## Etapa 4 — Relatório

```
## Docs Sync — <TICKET-ID>

Atualizados:
- CHANGELOG.md ([Unreleased] > Added)
- <doc> (<o que mudou>)

Confluence: [x] atualizado <link> | [ ] pendente: <motivo> | — desabilitado

Sem mudança necessária: <docs do map que não casaram>
```

## Restrições

- Não inventar conteúdo: cada atualização deve ser rastreável a uma linha do diff.
- Não criar páginas/spaces no Confluence sem aprovação do usuário.
- Não tocar em código — esta skill só escreve documentação.
