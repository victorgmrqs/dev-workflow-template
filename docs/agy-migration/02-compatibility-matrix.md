# 2. Dependências e comparativo técnico

## 2.1 Escopo confirmado

“Agy CLI” corresponde ao **Google Antigravity CLI**, executado pelo binário `agy`. Não deve ser confundido com:

- **Gemini CLI**, que usa `gemini-extension.json` e oferece importação para o Agy;
- **Google Agents CLI** (`google/agents-cli`), voltado a criar, avaliar e publicar agentes no Google Cloud.

A documentação oficial atual descreve plugins Agy com `plugin.json`, `skills/`, `agents/`, `rules/`, `mcp_config.json` e `hooks.json`. Skills tornam-se slash commands. Plugins podem ser instalados de path local ou origem remota e são staged pelo CLI. Consulte [Plugins & skills](https://antigravity.google/docs/cli-plugins).

## 2.2 Comparativo Claude Code × Antigravity CLI

| Dimensão | Claude Code atual | Antigravity CLI (`agy`) | Impacto no projeto |
|---|---|---|---|
| Arquitetura | CLI + loader de plugins; conteúdo declarativo | TUI sobre shared agent harness; plugins declarativos e subagentes assíncronos | conceito compatível; contratos diferem |
| Manifesto | `.claude-plugin/plugin.json`; metadados amplos | `plugin.json` no root; schema oficial aceita somente `name` e `description` | adicionar segundo manifesto; não copiar `version/author/...` |
| Distribuição | marketplace JSON + `/plugin marketplace add/install` | `agy plugin install <path|source>`; list/enable/disable/uninstall | manter dois canais; Git tags continuam úteis fora do manifesto Agy |
| Carregamento | componentes no root; namespace do plugin | bundle é staged e componentes auto-descobertos | evitar paths físicos de instalação |
| Config global | `~/.claude/...` | `~/.gemini/antigravity-cli/settings.json` e configs dedicadas | não escrever config global automaticamente |
| Config workspace | `.claude/*`, `CLAUDE.md` | `.agents/*`; `AGENTS.md` e `GEMINI.md` são contexto aceito | gerar adaptador Agy e migrar config canônica |
| Commands | skills/commands e slash commands namespaced | skills viram slash commands; diretório `commands/` não é parte do layout nativo documentado | manter workflows como skills |
| Skills | `skills/<name>/SKILL.md`; frontmatter rico | plugin aceita `skills/<name>/SKILL.md`; docs de skill garantem `name` e `description` | corpo portátil; frontmatter deve ser reduzido/gerado |
| Argumentos | `$ARGUMENTS`, `argument-hint`, named arguments | invocação por slash command é suportada, mas paridade desses campos não está documentada | escrever instruções que aceitem texto de invocação sem depender de placeholder exclusivo |
| Invocação | `disable-model-invocation` controla manual/automática | skill pode ser ativada pelo agente e manualmente; campo equivalente não documentado | gates perigosos precisam de regras/checkpoints explícitos |
| Agents | Markdown estático; modelo/tools/skills/effort por frontmatter | plugin suporta `agents/`; subagentes também podem ser definidos dinamicamente; herdam modelo do pai | prompts portáveis; model/tool routing precisa de adaptador |
| Subagentes | isolamento via Agent tool; `context: fork`/`agent:` em skill | `invoke_subagent`; assíncronos; worktree opcional; permissões herdadas | substituir semântica Claude por capability `delegate` |
| Modelo | aliases `opus/sonnet/haiku` por agente | subagente documentado usa o mesmo modelo do pai; usuário escolhe em `/model` | routing exato incompatível |
| Hooks | `hooks/hooks.json`; wrapper `hooks`; `SessionStart` e vários eventos | `hooks.json` no root; hooks nomeados; Pre/PostToolUse, Pre/PostInvocation e Stop | reescrever schema e contrato; emular início com PreInvocation #0 |
| Hook I/O | JSON stdin; `SessionStart` aceita stdout como contexto | JSON stdin/out camelCase; decisões/injeções estruturadas | script adaptador obrigatório |
| MCP | `.mcp.json`; tools namespaced pelo servidor | `mcp_config.json`; stdio/remoto; `serverUrl`; permissões `mcp(server/tool)` | criar profile Agy opcional; não embutir credenciais |
| Jira/Confluence | MCP Atlassian e nomes de tools do conector | MCP Atlassian está no catálogo, mas nomes concretos devem ser descobertos | introduzir capability mapping |
| Rules | `.claude/rules/*.md`, path scoping Claude | `.agents/rules/` e rules em plugin | gerar variants; validar semântica de frontmatter |
| Contexto | `CLAUDE.md` + skill descriptions + fork | `AGENTS.md`/`GEMINI.md`, skills on demand, contexto isolado em subagentes | preferir `AGENTS.md` canônico e arquivos específicos finos |
| Checkpoints | perguntas no workflow; permissões Claude | Artifact Review Policy, permissões e perguntas estruturadas | preservar checkpoints e integrá-los ao review Agy |
| Segurança | permissions e hooks Claude | engine allow/deny/ask para files, commands, URL e MCP; sandbox | Agy oferece melhor formalização para ações externas |
| Observabilidade | debug/doctor e transcript Claude | `/tasks`, `/agents`, `/hooks`, `/mcp`, transcripts e artifact directory | adicionar diagnóstico e relatório de capacidades |
| Extensibilidade | skills, agents, hooks, MCP, LSP, monitors | skills, agents, rules, hooks, MCP e sidecars | core cabe no subset comum; extras ficam em adapters |

Fontes: [Claude plugins](https://code.claude.com/docs/en/plugins-reference), [Claude skills](https://code.claude.com/docs/en/slash-commands), [Claude hooks](https://code.claude.com/docs/en/hooks), [Agy plugins](https://antigravity.google/docs/cli-plugins), [Agy hooks](https://antigravity.google/docs/hooks), [Agy subagents](https://antigravity.google/docs/subagents), [Agy MCP](https://antigravity.google/docs/mcp) e [Agy permissions](https://antigravity.google/docs/cli-permissions).

## 2.3 Matriz das dependências específicas do Claude Code

Classificação usada:

- **facilmente substituível**: mapeamento mecânico, sem mudança de comportamento;
- **parcialmente compatível**: núcleo reaproveitável, mas contrato/semântica muda;
- **incompatível**: não existe equivalência documentada;
- **precisa ser redesenhada**: substituição local não preserva garantias.

| Dependência | Onde aparece | Classe | Adaptação |
|---|---|---|---|
| `.claude-plugin/plugin.json` | manifesto | facilmente substituível | adicionar `plugin.json` Agy no root; manter ambos |
| `marketplace.json` e `/plugin ...` | instalação/README | parcialmente compatível | documentar `agy plugin install`; marketplace continua só para Claude |
| `skills/<name>/SKILL.md` | todas as skills | facilmente substituível | formato de diretório é comum; gerar frontmatter mínimo Agy |
| `disable-model-invocation` | 11 skills | parcialmente compatível | não depender do campo no Agy; proteger ações por checkpoints/rules/permissions |
| `argument-hint`, `$ARGUMENTS` | task, review, ticket, test guide | parcialmente compatível | normalizar entrada no corpo e gerar sintaxe por adapter |
| `allowed-tools` com `Read/Write/...` | product-manager | precisa ser redesenhada | declarar capability set neutro e mapear para permissões/tools do host |
| `context: fork` e `agent: reviewer` | code-review-task/docs-sync | precisa ser redesenhada | adapter instrui `invoke_subagent`; fallback inline deve ser explícito |
| aliases `opus/sonnet/haiku` | agents | incompatível para paridade | Agy documenta herança do modelo pai; remover promessa de routing por modelo |
| tools `Read, Glob, Grep, Bash, WebSearch, WebFetch` | explorer/researcher | parcialmente compatível | mapear por capacidades `read/search/shell/web`, nunca por nomes no core |
| Agent tool / Skill tool | task e product-manager | parcialmente compatível | instruções por intenção; adapter escolhe `invoke_subagent` ou skill disponível |
| `/security-review` e `/code-review` nativos | code-review-task | incompatível | criar skill portátil de security review ou integrar plugin oficial, com feature flag |
| `${CLAUDE_PLUGIN_ROOT}` | task/review/setup | precisa ser redesenhada | referências relativas ao diretório da skill ou assets copiados pelo build |
| `.claude/workflow.config.yaml` | skills operacionais | facilmente substituível | mover para `.dev-workflow/workflow.config.yaml`; fallback de leitura durante transição |
| `CLAUDE.md` | setup/task/review/agents/template | parcialmente compatível | usar `AGENTS.md` como base comum; adapter Claude pode manter CLAUDE.md ponte |
| `.claude/rules/` | generate-rules/task/review | parcialmente compatível | fonte neutra + emissão `.claude/rules` e `.agents/rules` |
| `.claude/skills/testing-guide-*` | generate-test-guide | parcialmente compatível | destino por plataforma ou `.agents/skills` no Agy |
| hook `SessionStart` | `hooks/hooks.json` | precisa ser redesenhada | Agy `PreInvocation`, apenas `invocationNum == 0`, com JSON `injectSteps` |
| wrapper `{ "hooks": ... }` | hook Claude | incompatível como arquivo Agy | Agy usa hooks nomeados no topo; manter dois arquivos-fonte gerados |
| stdout livre do hook | hook Claude | incompatível | Agy exige JSON conforme evento |
| nomes de MCP Atlassian | task/setup/docs/ticket | parcialmente compatível | discovery + capability map; erro claro se ausente |
| config implícita do conector | workflow config | precisa ser redesenhada | pré-flight `doctor` verifica servidor e tools exigidas |
| namespace `/dev-workflow:task` | README | parcialmente compatível | Agy registra skills como slash commands e pode namespacar plugin; validar conflito em smoke test |

## 2.4 Adaptação componente a componente

### Reuso direto do corpo

- `hld-creator`, `fdd-creator` e `implementation-plan-creator`: ~95% do corpo.
- packs de review, templates PRD/tech spec/PR, testing fundamentals: 100% conceitual.
- `docs-guard.sh`: comportamento preservado, com testes e opção cross-platform futura.

### Reuso com adapter leve

- `product-manager`: remover nomes de tools e tornar subagent strategy capability-based.
- `ticket-creator`: abstrair Atlassian e path da config.
- `docs-sync`: abstrair config, MCP e isolamento.
- `generate-test-guide`: trocar destination resolver, tool names e argumento.
- `setup-project`/`generate-rules`: escolher target platform e materializar `.agents/*` ou `.claude/*`.

### Redesenho controlado

- `task`: quebrar o monólito em etapas reutilizáveis e efeitos com checkpoints.
- `code-review-task`: separar checks portáveis, security review e adapter de execução isolada.
- agents: preservar papéis, remover modelo fixo do core e mapear permissões.
- hook: novo script testável com dois serializers de evento.

## 2.5 Lacunas e inconsistências documentais

1. A página geral de plugins cita `~/.gemini/config/plugins/`; a página específica do CLI cita staging em `~/.gemini/antigravity-cli/plugins/`. A arquitetura não deve depender desse path interno.
2. A documentação Agy lista `agents/` em plugins, mas não publica na mesma página um schema completo para arquivos estáticos de agente. Use apenas campos verificados em testes de compatibilidade e trate extras como opcionais.
3. A documentação garante skills como slash commands, mas não garante equivalentes para todo frontmatter Claude. O adapter Agy deve emitir somente `name` e `description` até validação adicional.
4. A página MCP recomenda `serverUrl`; o changelog mais recente passou a aceitar também `url`. Use `serverUrl`, que é a forma estável documentada.
5. O manifesto Agy tem `additionalProperties: false`; `version`, `author`, `homepage`, `repository` e `license` do manifesto Claude não podem ser copiados.

## 2.6 Arquitetura, ciclo de vida e recomendações oficiais do Agy

### Instalação, empacotamento e distribuição

- Instalação do CLI: o instalador oficial coloca `agy` em `~/.local/bin` no macOS/Linux; há instaladores próprios para Windows.
- Instalação do plugin: `agy plugin install <path-ou-url>`; operações documentadas incluem `list`, `enable`, `disable` e `uninstall`.
- Empacotamento: `plugin.json` obrigatório no root; `skills/`, `agents/`, `rules/`, `hooks.json` e `mcp_config.json` opcionais.
- Distribuição: um repositório Git pode ser a origem remota, como demonstra o [codelab oficial do Conductor](https://codelabs.developers.google.com/conductor-plugin).
- O CLI faz staging/import dos componentes. Alterações locais de desenvolvimento devem ser testadas por reinstalação/import conforme a versão; o projeto não deve editar o diretório staged diretamente.

### Carregamento e ciclo de vida

1. `agy` autentica, abre/trusta o workspace e carrega settings/configs.
2. Plugins enabled são descobertos e seus componentes registrados.
3. Skills ficam navegáveis em `/skills` e tornam-se slash commands; o conteúdo especializado é ativado sob demanda.
4. Hooks síncronos interceptam `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation` ou `Stop`.
5. Subagentes podem ser invocados de forma assíncrona, com contexto isolado e workspace compartilhado ou worktree.
6. MCP servers stdio/remotos são descobertos de `mcp_config.json` e governados pelas permissões do CLI.
7. Disable impede uso sem apagar assets; uninstall remove o pacote importado.

### APIs e controles disponíveis

- Tools nativas para arquivos, shell, busca/web e colaboração entre agentes.
- `invoke_subagent`, `define_subagent`, `send_message` e `manage_subagents` para colaboração.
- MCP com `command` ou `serverUrl`, `args`, `env`, `cwd`, `headers`, OAuth/ADC, `disabled` e `disabledTools`.
- Engine de permissões com `allow`, `deny` e `ask` para `read_file`, `write_file`, `command`, `unsandboxed`, `read_url`, `execute_url` e `mcp`.
- Hook I/O em JSON via stdin/stdout; hooks devem ter timeout e retorno específico do evento.
- Painéis `/agents`, `/tasks`, `/skills`, `/hooks` e `/mcp` para observabilidade operacional.

### Limitações relevantes

- Subagentes herdam o modelo do pai e não recebem o histórico da conversa principal; paridade com model routing Claude não existe.
- Permissões do pai limitam o subagente; solicitações adicionais sobem para aprovação.
- Profundidade de delegação documentada: no máximo 10 níveis.
- Teamwork gerenciado permanece recurso preview/restrito a plano; o plugin não deve depender dele.
- Hooks são síncronos e podem atrasar ou prender o loop se forem lentos ou retornarem JSON inválido.
- Configurações de UI/temas do Gemini CLI têm apenas paridade parcial após importação.
- O schema público de agents empacotados é menos detalhado que o de hooks/plugin; testar a versão mínima é obrigatório.

### Recomendações aplicadas ao desenho

- usar o schema oficial no `plugin.json` e nenhuma propriedade extra;
- usar `serverUrl` para MCP remoto e nunca versionar headers/secrets;
- manter permissões não configuradas em Ask e documentar grants mínimos;
- preferir skills/resources para conhecimento sob demanda, evitando contexto global longo;
- usar subagentes para isolamento/paralelismo, não como requisito para correção funcional;
- validar hooks com payloads reais e expor seu estado em `/hooks`;
- usar `AGENTS.md`/config workspace para fatos estáveis e skills para procedimentos.
