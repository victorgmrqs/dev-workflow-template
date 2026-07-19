# 3. Arquitetura proposta

## 3.1 Decisão

Adotar uma **arquitetura compartilhada com adaptadores gerados**, não uma cópia independente do plugin.

As alternativas avaliadas:

| Alternativa | Vantagens | Desvantagens | Veredito |
|---|---|---|---|
| Adaptação direta in-place | entrega inicial rápida | condicionais espalhadas, frontmatter conflitante, risco de quebrar Claude | rejeitada |
| Fork Agy do repositório | isolamento total | duplicação imediata, drift de prompts e gates | rejeitada |
| Camada de compatibilidade em runtime | flexível | exige runtime novo para um projeto hoje declarativo | adiar; excessiva no início |
| Core canônico + gerador de adapters | preserva conteúdo, diferenças explícitas, testável | introduz build e fixtures | recomendada |

## 3.2 Princípios

1. **O core não conhece nomes de ferramentas.** Ele pede capacidades: `read_ticket`, `transition_ticket`, `delegate_readonly`, `invoke_skill`, `web_search`.
2. **Efeitos externos são declarados.** Push, Jira e Confluence exigem pre-flight e aprovação conforme política.
3. **Compatibilidade nunca é silenciosa.** Capability ausente gera `unsupported`, fallback documentado ou parada segura.
4. **Conteúdo é canônico uma vez.** Frontmatter, paths e instruções específicas são templates de adapter.
5. **Configuração do workflow é neutra.** `.dev-workflow/workflow.config.yaml` substitui `.claude/workflow.config.yaml` como fonte de verdade.
6. **Contexto usa padrão amplo.** `AGENTS.md` é o contexto compartilhável; `CLAUDE.md` e `GEMINI.md` podem apontar/importar o conteúdo quando necessário.
7. **Modelo é hint, não contrato.** Papéis indicam `reasoning_profile: deep|balanced|fast`; adapters usam o melhor mecanismo disponível.

## 3.3 Estrutura final esperada

```text
.
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── plugin.json                         # manifesto Antigravity
├── core/
│   ├── skills/
│   │   ├── task/body.md
│   │   ├── code-review-task/body.md
│   │   └── ...
│   ├── agents/
│   │   ├── architect.md
│   │   ├── reviewer.md
│   │   └── ...
│   ├── prompts/
│   ├── templates/
│   ├── review-packs/
│   └── workflows/
│       ├── task.yaml                   # fases, gates, capabilities e efeitos
│       └── planning.yaml
├── adapters/
│   ├── claude-code/
│   │   ├── skill-frontmatter.yaml
│   │   ├── agent-frontmatter.yaml
│   │   ├── hooks.json.tmpl
│   │   └── paths.yaml
│   └── antigravity/
│       ├── skill-frontmatter.yaml
│       ├── agent-frontmatter.yaml
│       ├── hooks.json.tmpl
│       ├── plugin.json.tmpl
│       └── paths.yaml
├── shared/
│   ├── capabilities.yaml
│   ├── config.schema.json
│   ├── task-brief.schema.json
│   └── scripts/
│       ├── docs-guard.sh
│       └── session-diagnostic.sh
├── dist/
│   ├── claude-code/                    # gerado, não editado à mão
│   └── antigravity/                    # gerado, não editado à mão
├── scripts/
│   ├── build-adapters.sh
│   ├── validate-dist.sh
│   └── smoke-test.sh
├── tests/
│   ├── fixtures/
│   ├── contracts/
│   └── snapshots/
├── docs/
└── README.md
```

Durante a transição, o layout atual pode continuar sendo a distribuição Claude para evitar um big bang. O movimento para `core/` deve ocorrer skill por skill.

## 3.4 Camadas

### Core de conteúdo

Contém procedimentos e políticas independentes do host:

- fases, checkpoints, invariantes e critérios de parada;
- formatos dos relatórios;
- templates, packs e fundamentos;
- papéis de agentes sem nomes de modelo/tool;
- intents de integração.

Exemplo de intent neutra:

```yaml
capability: issue.transition
required_when: tracker.provider == "jira"
input:
  issue_id: ticket.id
  target_status: tracker.columns.in_progress
failure: warn_and_continue
```

O primeiro release não precisa de um executor YAML. O arquivo pode servir como contrato validável enquanto o corpo Markdown continua orquestrando.

### Adaptadores de plataforma

Responsáveis por:

- frontmatter de skills e agents;
- paths de workspace e contexto;
- nomes/contratos de tools;
- formato de hooks;
- manifestos e instalação;
- política de subagentes;
- diagnóstico de capacidades.

### Integrações

O core usa contratos conceituais:

| Capability | Claude | Antigravity | Fallback |
|---|---|---|---|
| `issue.read` | MCP Atlassian tool descoberta | MCP Atlassian tool descoberta | descrição do usuário |
| `issue.transition` | MCP Atlassian | MCP Atlassian | registrar pendência |
| `docs.publish_business` | Confluence MCP | Confluence MCP | manter apenas Git |
| `delegate.readonly` | Agent/subagent explorer | `invoke_subagent` read-only | execução inline |
| `delegate.review` | skill fork + reviewer | custom/built-in subagent | execução inline com aviso |
| `review.security` | `/security-review` | skill portátil ou plugin | checklist portátil |
| `web.search` | WebSearch | ferramenta web disponível | pedir fonte/URL ao usuário |

O adapter deve descobrir tools por capacidade, não assumir `createJiraIssue` para sempre.

## 3.5 Configuração canônica

Novo path:

```text
.dev-workflow/workflow.config.yaml
```

Estratégia de leitura:

1. ler o novo path;
2. se ausente, ler `.claude/workflow.config.yaml` e avisar depreciação;
3. nunca manter dois arquivos editáveis como fontes de verdade;
4. oferecer migração idempotente que preserve comentários quando possível;
5. incluir `schema_version` e `platforms`.

Exemplo:

```yaml
schema_version: 1
platforms:
  claude_code: true
  antigravity: true

project:
  name: ""
  language: pt-BR

integrations:
  tracker:
    provider: jira
    required_capabilities: [issue.read, issue.transition, issue.comment]
```

Um JSON Schema formal deve validar tipos, enums, campos obrigatórios e compatibilidade de versão.

## 3.6 Contexto, rules e skills geradas

### Contexto

- `AGENTS.md`: regras compartilhadas do projeto, curto e factual.
- `CLAUDE.md`: adapter Claude, contendo apenas diferenças Claude ou ponte para o contexto comum.
- `GEMINI.md`: somente se necessário para contexto persistente específico do harness Google; Agy também lê `AGENTS.md` segundo a documentação de migração.

### Rules

Os conceitos ficam em uma representação neutra e o gerador emite:

- `.claude/rules/*.md` para Claude;
- `.agents/rules/*.md` para Agy.

Os bodies podem ser iguais; apenas path/frontmatter deve variar.

### Skills específicas do projeto

`generate-test-guide` recebe `platform_targets` e emite um único conteúdo canônico mais wrappers:

```text
.dev-workflow/generated/testing-guide-foo/...
.claude/skills/testing-guide-foo/SKILL.md       # wrapper/cópia gerada
.agents/skills/testing-guide-foo/SKILL.md       # wrapper/cópia gerada
```

Se symlinks não forem confiáveis na distribuição, cópias geradas são aceitáveis desde que CI detecte drift e proíba edição manual.

## 3.7 Hooks

O diagnóstico de sessão vira um script compartilhado com serializers:

```text
shared/scripts/session-diagnostic.sh
adapters/claude-code/hooks.json.tmpl
adapters/antigravity/hooks.json.tmpl
```

No Agy:

- usar `PreInvocation`;
- executar somente quando `invocationNum == 0`;
- retornar `injectSteps: [{"ephemeralMessage": "..."}]`;
- manter o hook informativo, rápido e idempotente;
- não usar o hook para escrever config ou pedir credenciais.

No Claude, preservar `SessionStart`. Os dois adapters chamam a mesma lógica de diagnóstico.

## 3.8 Agents e routing

Papéis canônicos:

```yaml
name: reviewer
reasoning_profile: deep
capabilities: [read, search, shell_checks]
write_policy: deny
delegation_policy: deny
```

Mapeamento:

- Claude: `deep → opus`, `balanced → sonnet`, `fast → haiku`, enquanto aliases existirem;
- Agy: herdar modelo do pai e preservar apenas papel/capabilities; usuário controla `/model`;
- futuro Codex/outros: mapear para níveis de esforço e tool policy.

O comportamento correto do reviewer não pode depender do modelo: read-only e veredito binário devem ser reforçados por permissões e testes de contrato.

## 3.9 Segurança e observabilidade

- Manifesto Agy sem propriedades extras, conforme schema oficial.
- MCP config sem secrets versionados; autenticação via OAuth/ADC/env/keychain.
- `doctor` lista capabilities disponíveis/ausentes antes do primeiro efeito.
- permissões Agy recomendadas em documentação, não instaladas globalmente sem consentimento.
- logs não incluem ticket privado, transcrição, tokens ou headers.
- cada fallback aparece no relatório final: `native`, `portable`, `inline` ou `unsupported`.
- hook e scripts têm timeout explícito.

## 3.10 Evolução para outras plataformas

A separação por capabilities permite adapters futuros para Codex, Cursor ou Gemini CLI, mas o escopo inicial deve permanecer em Claude + Agy. O critério para aceitar novo adapter é:

- cobrir o contrato mínimo de skills, contexto, shell, files e checkpoints;
- declarar capabilities ausentes;
- passar o mesmo conjunto de fixtures do core;
- não adicionar condicionais de plataforma ao body canônico.

