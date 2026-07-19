---
name: ticket-creator
description: >
  Cria, revisa ou formata tickets (Epics/Tasks/Stories) no Jira via MCP a
  partir de FDDs, implementation-plan ou épicos, seguindo o padrão de título,
  descrição, cenários de teste obrigatórios e DoD do workflow. Elo entre o
  planejamento (/fdd-creator, /implementation-plan-creator) e a execução (/task).
  Uso: /ticket-creator <fonte>   ex: /ticket-creator docs/implementation-plan.md
disable-model-invocation: true
argument-hint: "<FDD | plano | épico | descrição>"
---

# Skill: /ticket-creator

## Objetivo

Transformar artefatos de planejamento em tickets prontos para o `/task`, com qualidade uniforme: todo ticket nasce com contexto, escopo, regras afetadas, critérios de aceite verificáveis e cenários de teste obrigatórios.

## Etapa 0 — Configuração

Leia `.dev-workflow/workflow.config.yaml`, com fallback legado para `.claude/workflow.config.yaml` e aviso (`tracker.*`, `domains`, `evidence`, `dod_extra`). Sem config: `/setup-project` primeiro. Se `tracker.provider: none`, gere os tickets como Markdown em `docs/backlog/`.

Se o projeto tiver `docs/workflow.md` (ou equivalente) com template próprio de ticket, **ele tem prioridade** — use o padrão abaixo como baseline e adapte.

## Etapa 1 — Fonte

Leia a fonte indicada (FDD, implementation-plan, épico, ou descrição livre do usuário). Para planos: cada task do plano vira um ticket; agrupe por fase/domínio em Epics. Hierarquia: `Epic (fase do roadmap / domínio) → Task/Story (unidade implementável)`.

## Etapa 2 — Padrão do ticket

### Título

```
[prefixo] TXX — Descrição curta
```

Prefixo = camada **principal** afetada (secundárias viram labels). Baseline (ajuste ao projeto):

| Prefixo | Quando usar |
|---|---|
| `[backend]` | Lógica de domínio/servidor: use cases, providers, repositories |
| `[frontend]` | UI, views, integração com backend no client |
| `[infra]` | Build, empacotamento, CI/CD |
| `[observability]` | Logs estruturados, métricas, diagnóstico |
| `[cross-service]` | Integração com serviços/APIs externas |
| `[database]` | Schema, migrations, persistência |
| `[docs]` | Apenas documentação |

Em setup multi-repo, o prefixo deve ser compatível com `tracker.ticket_prefix_guard` dos repos envolvidos.

### Descrição (5 seções fixas, nesta ordem — nunca omitir, use "N/A" se preciso)

```markdown
## Contexto
[Por que este ticket existe. Link para FDD/HLD/regra de negócio.]

## Escopo de Arquivos
- `src/...` — [o que muda]

## Regras de Negócio Afetadas
| ID | Regra | Arquivo |
|----|-------|---------|
| DOM-01 | [resumo] | `docs/domain-context.md` |

## Critérios de Aceite
- [ ] [critério funcional verificável — binário]
- [ ] Testes cobrem todos os cenários da matriz de erros (FDD §6)
- [ ] Eventos-chave logados sem dados sensíveis
- [ ] Evidência criada (conforme evidence da config)

## Cenários de Teste Obrigatórios
> DEVEM existir com exatamente estes nomes — não negociável.
- `<unidade>_success` — caminho feliz
- `<unidade>_<erro>` — um por linha da matriz de erros do FDD no escopo

## Referências
- FDD: `docs/fdds/...` · HLD: `docs/hld.md`
```

### Evidência por tipo (adaptar via `evidence` da config)

| Tipo | Evidência |
|---|---|
| `[cross-service]` | `.http` cobrindo a matriz de erros |
| `[backend]` | testes automatizados + "Como testar" no PR |
| `[frontend]` | screenshot/GIF + passos |
| `[database]` | teste de integração + asserção do estado do banco |
| `[infra]` | link da run de CI verde |

## Etapa 3 — Criação

1. Apresente a lista proposta (Epics + tickets com títulos e dependências) para **aprovação antes de criar**.
2. Quando Jira estiver ativo, faça o pre-flight de `../../integrations/atlassian-mcp.md` e resolva `jira.issue.create` no servidor `tracker.mcp_server` (default `MCP_DOCKER`). Crie na ordem das dependências, vinculando Task→Epic conforme o schema real da tool. Não presuma o nome `createJiraIssue` nem campos customizados.
3. Relatório final: IDs criados com links, e o mapeamento plano→tickets.

## Restrições

- Não criar tickets sem aprovação da lista proposta.
- Critério de aceite não verificável (vago, não-binário) não entra — reescreva.
- Um ticket = uma unidade implementável por um `/task`; se não couber, divida.
