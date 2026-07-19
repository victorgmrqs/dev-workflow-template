# Política de documentação por tarefa

## Invariantes

1. Toda tarefa altera o `CHANGELOG.md`, independentemente do tipo ou dos arquivos modificados.
2. Toda entrada do changelog resume o resultado em uma linha e aponta para o card Jira por link Markdown.
3. Toda tarefa Jira é registrada em uma página única de Histórico de entregas no Confluence.
4. Documentação técnica tem o repositório como fonte de verdade.
5. Documentação funcional e visão operacional de alto nível têm o Confluence como fonte de verdade.
6. Um impacto não aplicável precisa de justificativa explícita no `task-brief.yaml`.

## Níveis

| Nível | Quando | Fonte de verdade | Exemplos |
|---|---|---|---|
| Registro | Toda tarefa | Repositório + Confluence | changelog, card, Histórico de entregas |
| Técnico | Impacto de implementação | Repositório | ADR, API, schema, banco, integração, runbook executável |
| Funcional | Comportamento/regra muda | Confluence | finalidade, fluxo, regra, permissão, limitação, FAQ |
| Operacional | Operação/hospedagem muda | Dividida | IaC e comandos no repo; ambientes, URLs, ownership e diagramas no Confluence |

Segredos, tokens, credenciais e valores sensíveis não pertencem a nenhum desses destinos.

## Changelog

A entrada fica em `[Unreleased]` e usa uma das categorias:

- `Added`
- `Changed`
- `Fixed`
- `Security`
- `Deprecated`
- `Removed`
- `Maintenance`

Formato:

```markdown
### Changed

- Padronizada a política documental do workflow. ([DWT-123](https://example.atlassian.net/browse/DWT-123))
```

O changelog não substitui a documentação detalhada. Ele funciona como índice cronológico e rastreável das entregas.

## Histórico de entregas

Use uma página estável do Confluence em vez de criar uma página por ticket. Cada tarefa acrescenta uma linha sem duplicar o card:

| Data | Ticket | Tipo | Resumo | Impacto funcional | Documentação |
|---|---|---|---|---|---|
| 2026-07-19 | DWT-123 | Feature | Resumo da entrega | Sim | links técnicos e funcionais |

O ID da página deve ser salvo em `documentation_policy.delivery_log.page_id`.

## Momento da atualização

1. O `/task` classifica o impacto no brief antes da aprovação.
2. A documentação técnica evolui junto com o código.
3. O `/docs-sync` atualiza changelog, documentos aplicáveis e Confluence.
4. O `/code-review-task` bloqueia a entrega quando faltar registro, link, conteúdo ou justificativa.
5. O comentário final no Jira reúne branch, review e links de documentação.

Indisponibilidade externa deve ser registrada como pendência real; nunca deve ser convertida silenciosamente em item concluído.
