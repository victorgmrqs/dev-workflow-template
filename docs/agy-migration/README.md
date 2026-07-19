# Migração do dev-workflow para Antigravity CLI (`agy`)

Data da análise: 2026-07-19  
Estado analisado: `main` em `bc0e316`, plugin Claude Code v0.1.0  
Alvo: Google Antigravity CLI, binário `agy`

## Decisão executiva

A migração é viável sem reescrever o conteúdo de negócio. O repositório já é majoritariamente declarativo: 11 skills em Markdown, 6 perfis de agente, 4 packs de revisão, templates YAML/Markdown e três scripts (dois shell e um Python, sendo um shell distribuído como template). Não existe runtime de aplicação, banco ou serviço próprio.

A estratégia recomendada é **núcleo canônico + adaptadores gerados por plataforma**:

- manter workflows, prompts, templates, packs e schemas em um núcleo neutro;
- gerar artefatos finos para Claude Code e Antigravity CLI;
- manter os dois manifestos no mesmo repositório;
- substituir referências físicas `.claude/*` por uma configuração canônica em `.dev-workflow/`, com fallback temporário para a configuração v0.1.0;
- tratar hooks, agents, model routing e reviews nativos como capacidades de plataforma, não como pressupostos do núcleo.

Uma cópia direta de `skills/` funciona apenas parcialmente. Ela preserva o texto das skills, mas deixa quebrados ou silenciosamente degradados o hook `SessionStart`, `${CLAUDE_PLUGIN_ROOT}`, `context: fork`, `agent: reviewer`, aliases `opus/sonnet/haiku`, tools com nomes Claude e os caminhos `.claude/*`.

## Entregáveis

| Solicitado | Documento |
|---|---|
| 1. Relatório da arquitetura atual | [01-current-architecture.md](01-current-architecture.md) |
| 2. Comparativo Claude Code × Agy | [02-compatibility-matrix.md](02-compatibility-matrix.md) |
| 3. Arquitetura proposta | [03-target-architecture.md](03-target-architecture.md) |
| 4. Plano detalhado de migração | [04-migration-plan.md](04-migration-plan.md) |
| 5. Lista de riscos | [05-risks-improvements-backlog.md](05-risks-improvements-backlog.md) |
| 6. Melhorias priorizadas | [05-risks-improvements-backlog.md](05-risks-improvements-backlog.md) |
| 7. Backlog por fases | [05-risks-improvements-backlog.md](05-risks-improvements-backlog.md) |
| 8. Estimativas por fase | [04-migration-plan.md](04-migration-plan.md) |
| 9. Estrutura final esperada | [03-target-architecture.md](03-target-architecture.md) |
| 10. Recomendações finais | seção abaixo |

Estado da execução: [06-implementation-status.md](06-implementation-status.md).

## Recomendações finais

1. Não renomear o produto para “Gemini CLI”. O alvo confirmado é Antigravity CLI (`agy`); Gemini CLI é o antecessor e tem outro manifesto (`gemini-extension.json`).
2. Não remover o suporte Claude Code na primeira versão Agy. Os componentes compartilháveis são muitos e a convivência de `.claude-plugin/plugin.json` com `plugin.json` é simples.
3. Não prometer equivalência de modelo. Antigravity documenta que subagentes herdam o modelo do pai; o routing `opus/sonnet/haiku` deve virar preferência/função, com degradação explícita.
4. Fazer um vertical slice primeiro: `setup-project` → `task` em modo local → `docs-sync` → `code-review-task`. Jira/Confluence e os workflows de planejamento vêm depois.
5. Introduzir validação automática dos artefatos gerados e smoke tests nos dois CLIs antes de publicar.
6. Tratar comandos destrutivos ou externos (`git push`, transições Jira, Confluence) como permissões declaradas e checkpoints humanos, aproveitando o modelo de permissões do Agy.
7. Validar a versão mínima suportada em CI. A máquina analisada tem `agy 1.1.4`; a documentação oficial consultada é da linha Antigravity 2.0. A versão do produto e a versão do binário não devem ser comparadas como se fossem o mesmo esquema de versionamento.

## Fontes oficiais principais

- [Antigravity CLI — Plugins & skills](https://antigravity.google/docs/cli-plugins)
- [Antigravity — Hooks](https://antigravity.google/docs/hooks)
- [Antigravity — MCP](https://antigravity.google/docs/mcp)
- [Antigravity — Subagents](https://antigravity.google/docs/subagents)
- [Antigravity CLI — Permissions](https://antigravity.google/docs/cli-permissions)
- [Antigravity — Migration from Gemini CLI](https://antigravity.google/docs/gcli-migration)
- [Antigravity CLI — Reference](https://antigravity.google/docs/cli-reference)
- [Google Codelab — Conductor plugin on Antigravity CLI](https://codelabs.developers.google.com/conductor-plugin)
- [Claude Code — Plugins reference](https://code.claude.com/docs/en/plugins-reference)
- [Claude Code — Skills](https://code.claude.com/docs/en/slash-commands)
- [Claude Code — Hooks](https://code.claude.com/docs/en/hooks)
