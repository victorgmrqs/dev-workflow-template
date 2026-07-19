# 6. Estado da implementação

Data: 2026-07-19

## Implementado

- Manifesto nativo `plugin.json` validado pelo Antigravity CLI 1.1.4.
- Instalação local realizada com `agy plugin install .`.
- Discovery confirmado: 11 skills, 6 agents e 1 hook.
- Sessão headless real confirmada com `agy --print`.
- Hook `PreInvocation` idempotente, com teste de contrato.
- Configuração canônica `.dev-workflow/workflow.config.yaml` e fallback legado `.claude/workflow.config.yaml`.
- `AGENTS.md` como contexto compartilhado e adapters de rules/skills geradas.
- Assets resolvidos relativamente às skills, sem `${CLAUDE_PLUGIN_ROOT}` no fluxo compartilhado.
- Jira/Confluence via capability discovery no servidor configurado, default `MCP_DOCKER`.
- Security review portátil quando o review nativo do Claude não existir.
- Validação estática agregada em `scripts/validate-plugin.sh`.
- Diagnóstico read-only do gateway em `scripts/check-mcp-docker.sh`.

## Compatibilidade preservada

- `.claude-plugin/plugin.json` e marketplace Claude permanecem intactos.
- O hook Claude continua em `hooks/hooks.json` e agora reconhece a configuração canônica.
- Frontmatter Claude é aceito pelo validador Agy; fallbacks funcionais foram adicionados ao corpo das skills.
- Configs antigas continuam legíveis e não são apagadas automaticamente.

## Validações executadas

| Verificação | Resultado |
|---|---|
| `agy plugin validate .` | aprovado |
| instalação `agy plugin install .` | aprovado |
| `agy plugin list` | `skills`, `agents`, `hooks` carregados |
| smoke headless | `dev-workflow-smoke-ok` |
| teste do hook | aprovado |
| JSON/shell/Python | aprovado |
| MCP_DOCKER config | encontrada |
| Docker engine | indisponível no momento |

## Pendente de ambiente externo

O adapter Atlassian está implementado, mas o smoke test com Jira/Confluence real
depende de:

1. iniciar Docker Desktop/daemon;
2. confirmar que `docker mcp tools ls` expõe as capabilities requeridas;
3. fornecer um projeto Jira e uma página/space Confluence de sandbox;
4. testar leitura primeiro e, após confirmação, criação/transição/comentário/update.

Enquanto isso, `integrations.atlassian.fallback: local` mantém os workflows
operacionais sem mutações externas.
