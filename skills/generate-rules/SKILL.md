---
name: generate-rules
description: >
  Gera rules path-scoped (.claude/rules/*.md) específicas da stack do
  projeto a partir de conceitos universais: camadas/arquitetura, erros,
  persistência, testes, estilo. Analisa o código real antes de escrever.
  Rode após /setup-project e quando a arquitetura mudar.
  Uso: /generate-rules
disable-model-invocation: true
---

# Skill: /generate-rules

## Objetivo

Rules de stack não são portáveis entre projetos — os **conceitos** são. Esta skill traduz os conceitos abaixo para a stack e as convenções REAIS do projeto, gerando arquivos em `.claude/rules/` com frontmatter `paths:` (globs) para carga apenas quando arquivos correspondentes forem tocados.

## Etapa 1 — Análise

1. Leia `.claude/workflow.config.yaml` (stack, domínios) e `CLAUDE.md`.
2. Leia código representativo de cada camada (2–3 exemplos reais por conceito) — as rules devem descrever o que o projeto **já faz certo**, não um ideal abstrato.
3. Identifique o mapa de globs: onde vivem controllers/rotas, use cases, repositórios, modelos, testes, middleware de erro.

## Etapa 2 — Conceitos a materializar (um arquivo por conceito aplicável)

| Rule | Conceito universal | Conteúdo esperado |
|------|--------------------|--------------------|
| `architecture-layers.md` | Direção de dependência entre camadas (ex: ports & adapters) | quem pode importar quem; onde vive lógica de negócio; exemplo real do repo |
| `error-handling.md` | Erros de negócio vs técnicos; envelope de resposta; propagação | tipos/códigos usados; onde capturar; o que nunca engolir |
| `persistence.md` | Acesso a dados: chaves, soft delete, filtros obrigatórios (dono/ativo), transações | convenções do ORM/driver do projeto |
| `api-conventions.md` | Contrato externo: verbos/status/nomenclatura (REST) ou IPC/eventos | padrões observados + o que o API_SPEC exige |
| `testing.md` | O que testar em cada camada; convenção de nomes; fakes vs mocks | espelhar a convenção `test_<unidade>_<cenario>` e a matriz de erros do FDD |
| `coding-style.md` | Idioma, tipagem estrita, imports, nomenclatura | só o que linter/typechecker NÃO pegam (não duplicar tooling) |

## Etapa 3 — Formato de cada rule

```markdown
---
paths:
  - "<glob real do projeto>"
---
# <Título>
<Regras objetivas e curtas (≤50 linhas), cada uma verificável no diff.
Um exemplo mínimo de código real do projeto quando ajudar.>
```

Regras de escrita: imperativo, verificável, sem justificativas longas; nada que o linter já garanta; citar IDs (ADR-XXX, DOM-XX, NFR-XXX) quando a regra vier de decisão documentada.

## Etapa 4 — Validação

Apresente a lista de arquivos gerados com seus globs e peça confirmação antes de gravar. Depois, confira: nenhum glob órfão (que não casa com nada) e nenhuma sobreposição conflitante entre rules.

## Restrições

- Não gere rule para conceito que não se aplica (ex: `persistence.md` num projeto sem banco).
- Cada rule ≤50 linhas — rules são contexto carregado por glob; verbosidade custa tokens em toda edição futura.
