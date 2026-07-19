# CLAUDE.md — {{project.name}}

<!-- Teto: 80 linhas. Só fatos. Procedimentos vivem nas skills; convenções por camada nas rules. -->

## Overview

{{3 frases: o que o sistema faz, para quem, arquitetura em uma linha.}}

## Stack

{{linguagem + versão, framework, banco, test runner, gerenciador de deps — uma linha cada.}}

## Comandos

```bash
{{lint}}         # lint
{{typecheck}}    # typecheck
{{test}}         # testes
{{build}}        # build (se houver)
```

## Restrições não negociáveis

{{≤8 itens. Só o que NUNCA pode ser violado, com ID quando houver (ADR-XXX, NFR-XXX). Ex:}}
- Soft delete sempre; nunca DELETE físico (ADR-003).
- Segredos apenas via env; nunca em log ou versionados (NFR-005).

## Fluxo de trabalho

- Planejamento: `docs/prd/` → `docs/hld.md` → `docs/fdds/` → tickets.
- Execução: `/task <TICKET-ID>` (brief → aprovação → implementação → testes → `/docs-sync` → DoD → `/code-review-task` → entrega).
- Configuração canônica do workflow: `.dev-workflow/workflow.config.yaml`.
- Contexto compartilhado entre plataformas: `AGENTS.md`.

## Documentação (ler sob demanda, não tudo)

- Regras de negócio: `docs/domain-context.md`
- Arquitetura: `docs/hld.md` · ADRs: `docs/adr/`
- Design por domínio: `docs/fdds/` (carregado pelo /task conforme o ticket)
