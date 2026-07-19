# 1. Arquitetura atual

## 1.1 Visão geral

O projeto é um **pacote declarativo de workflow de desenvolvimento assistido por IA**. Ele não executa um daemon nem expõe uma biblioteca. Claude Code descobre arquivos convencionais e o modelo interpreta os procedimentos descritos em Markdown.

O fluxo funcional tem três trilhas:

```text
Planejamento
PRD → HLD → FDD → plano de implementação → tickets

Execução
ticket → brief → aprovação → branch → código/testes → docs → DoD
       → review automático → commit/push → Jira In Review

Bootstrap do projeto consumidor
detecção de stack → entrevista → config → CLAUDE.md → rules → guia de testes
```

O princípio arquitetural mais importante é “motor versus configuração”:

- `skills/`, `agents/`, `templates/` e `hooks/` são o motor distribuído pelo plugin;
- `.claude/workflow.config.yaml`, criado no projeto consumidor, contém branches, comandos, Jira, domínios, docs, evidências e quality gates;
- `task-brief.yaml` é estado efêmero por execução e não é versionado;
- Git, Jira e Confluence são os sistemas externos de estado.

## 1.2 Inventário e responsabilidades

### Empacotamento

| Arquivo | Responsabilidade | Acoplamento atual |
|---|---|---|
| `.claude-plugin/plugin.json` | identidade, versão e metadados do plugin | formato exclusivo Claude Code |
| `.claude-plugin/marketplace.json` | marketplace do autor e origem do plugin | distribuição exclusiva Claude Code |
| `README.md` | instalação, quick start e modelo operacional | comandos `/plugin` e paths Claude |
| `CHANGELOG.md` | histórico SemVer | neutro, embora descreva apenas Claude |

O manifesto não declara runtime, MCP ou dependências. A instalação depende do marketplace e da descoberta convencional dos diretórios no root.

### Skills de execução

| Skill | Papel | Entrada/saída e efeitos |
|---|---|---|
| `task` | orquestrador de ticket em oito fases | lê config/ticket/docs; cria brief e branch; edita código; roda testes; chama outras skills; faz commit/push; transiciona Jira |
| `code-review-task` | gate binário pré-commit | analisa diff, rules, FDD, testes, cobertura, docs e pack; executa checks; emite APROVADO/REPROVADO; não corrige |
| `docs-sync` | sincronização documental | cruza diff com `docs_map`; edita docs; opcionalmente atualiza Confluence |
| `ticket-creator` | ponte entre design e execução | lê FDD/plano; cria Epics/Tasks via MCP Atlassian ou Markdown local |

`task` é o componente de maior fan-in/fan-out. Ele depende das outras skills, dos templates, de Git, de um projeto já configurado e, opcionalmente, de Atlassian.

### Skills de bootstrap e metaprogramação

| Skill | Papel | Artefatos gerados no projeto consumidor |
|---|---|---|
| `setup-project` | detectar stack e entrevistar apenas lacunas | `.claude/workflow.config.yaml`, `CLAUDE.md`, `scripts/docs-guard.sh`, PR template e `.gitignore` |
| `generate-rules` | traduzir conceitos neutros para convenções reais | `.claude/rules/*.md` com `paths:` |
| `generate-test-guide` | pesquisar práticas por versão e produzir guia específico | `.claude/skills/testing-guide-<project>/...` |

Essas skills geram configuração de uma plataforma dentro do projeto consumidor; por isso são o segundo maior foco da migração.

### Skills de planejamento

| Skill | Papel | Observação |
|---|---|---|
| `product-manager` | PRDs, tech specs, priorização, épicos e histórias | possui templates, referências e scripts próprios; frontmatter lista tools Claude |
| `hld-creator` | entrevista e gera HLD/ADRs | conteúdo essencialmente neutro |
| `fdd-creator` | entrevista e gera FDD técnico | matriz de erros alimenta testes e review |
| `implementation-plan-creator` | converte design em fases/tasks dependentes | conteúdo essencialmente neutro |

O conteúdo dessas quatro skills é portátil. O acoplamento concentra-se no frontmatter, em paths e na estratégia de subagentes do `product-manager`.

### Agentes

| Agente | Função | Modelo/tools declarados |
|---|---|---|
| `architect` | decisões e ADRs | `opus` |
| `explorer` | exploração read-only | `haiku`; `Read, Glob, Grep, Bash` |
| `implementer` | execução mecânica de plano aprovado | `sonnet` |
| `researcher` | pesquisa externa citada | `opus`; `Read, Glob, Grep, Bash, WebSearch, WebFetch` |
| `reviewer` | revisão adversarial, sem correção | `opus` |
| `test-writer` | testes a partir de cenários | `sonnet`, `effort: low` |

Eles implementam routing por custo/capacidade e isolamento de contexto. Não há código de orquestração; a seleção depende da semântica do Claude Code e de instruções nas skills.

### Hook

`hooks/hooks.json` registra um único `SessionStart` shell inline. Ele verifica:

- `.claude/workflow.config.yaml` presente → informa que o plugin está configurado;
- Git presente sem config → recomenda `/setup-project`;
- fora de Git → não produz saída.

É informativo e não persiste estado. O formato externo `{ "hooks": { ... } }`, o evento e o contrato de stdout são Claude Code.

### Templates e packs

| Componente | Uso |
|---|---|
| `workflow.config.yaml` | fonte única de parâmetros por projeto |
| `task-brief.schema.yaml` | contrato do estado efêmero do ticket |
| `CLAUDE.template.md` | contexto persistente curto do projeto |
| `docs-guard.sh` | gate determinístico de docs/testes no diff |
| `pull_request_template.md` | entrega padronizada |
| `code-review-task/packs/*.md` | heurísticas de bugs por stack |
| `product-manager/templates/*` | PRD e tech spec |
| `product-manager/scripts/*` | priorização e validação de PRD |
| `generate-test-guide/testing-fundamentals.md` | política canônica de testes |

Esses recursos são majoritariamente neutros. O problema é como as skills localizam os arquivos após instalação.

## 1.3 Fluxo de execução e ciclo de vida

1. O usuário registra o marketplace e instala o plugin.
2. Claude Code descobre manifesto, skills, agents e hook.
3. Em `SessionStart`, o hook diagnostica a configuração do workspace.
4. `/setup-project` analisa o consumidor e materializa arquivos `.claude/*`.
5. Skills de planejamento produzem documentos versionados.
6. `/ticket-creator` persiste backlog em Jira ou `docs/backlog/`.
7. `/task` cria `task-brief.yaml` e para no checkpoint humano.
8. Após aprovação, Git/Jira mudam de estado; implementação e testes ocorrem.
9. `/docs-sync` atualiza docs/Confluence.
10. O segundo checkpoint humano antecede `/code-review-task`.
11. Somente com review aprovado ocorrem commit, push e Jira `In Review`.
12. PR, merge e Jira `Done` permanecem manuais.

Não há hook de uninstall, migração de config, rollback automatizado ou garbage collection. Atualizações são controladas pelo marketplace/SemVer e pelas instruções do README.

## 1.4 Estado e persistência

| Estado | Local | Vida útil | Fonte de verdade |
|---|---|---|---|
| configuração do workflow | `.claude/workflow.config.yaml` | por projeto | repositório consumidor |
| regras de stack | `.claude/rules/*.md` | por projeto | geradas a partir do código |
| contexto persistente | `CLAUDE.md` | por projeto | repositório consumidor |
| brief | `task-brief.yaml` | por ticket/sessão | efêmero; `.gitignore` |
| documentação | `docs/*`, `CHANGELOG.md` | versionada | Git |
| status do trabalho | branch/commits | versionado/remoto | Git |
| backlog/status | Jira | remoto | Jira |
| espelho de negócio | Confluence | remoto | repositório é canônico para técnico |

Não existe schema validation executável para `workflow.config.yaml` ou `task-brief.yaml`; o arquivo chamado “schema” é um exemplo comentado, não JSON Schema/YAML Schema formal.

## 1.5 Dependências

### Internas

- Convenção de diretórios do plugin.
- Referências cruzadas entre `task`, `docs-sync` e `code-review-task`.
- Matriz de erros do FDD como origem dos cenários obrigatórios.
- `docs_map` e flags de impacto do brief.
- Packs de stack selecionados por `quality_gates.review_pack`.

### Externas

- Claude Code e seu loader de plugins.
- Git e um remote para a etapa de publicação.
- Shell POSIX/Bash; `grep`; comandos do projeto consumidor.
- MCP Atlassian para Jira/Confluence quando habilitado.
- Web search nas skills de pesquisa/guia de testes.
- Python 3 para `prioritize.py`.
- Ambiente de CI para `docs-guard.sh`.

## 1.6 Pontos de extensão

- `workflow.config.yaml`: providers, branches, comandos, gates, domínios, docs e evidências.
- `dod_extra`: DoD por projeto.
- `docs_map`: política código → documentação.
- `domains`: roteamento JIT para FDD.
- packs de `code-review-task`: heurísticas por stack.
- `.claude/rules/`: convenções path-scoped.
- templates de PRD/tech spec/PR.
- Jira `tracker.provider: none` como modo offline.

## 1.7 Limitações atuais

1. O “core” está misturado a paths e nomes Claude em quase todas as skills operacionais.
2. Não há testes automatizados do pacote nem fixtures de workspace consumidor.
3. Não há schema formal nem migração versionada da configuração.
4. O hook shell inline é difícil de testar e não é cross-platform.
5. O routing de modelo é uma política de plataforma embutida nos agentes.
6. As chamadas de MCP usam nomes de tools específicos do conector, sem capability discovery ou fallback padronizado.
7. `generate-test-guide` gera outra skill Claude e contém referências diretas a tools (`WebSearch`) e `$ARGUMENTS`.
8. A instalação via template e via plugin pode causar duplicação/sombreamento de skills.
9. `docs-guard.sh` usa Bash/grep e pressupõe `origin/<base>` ou branch local.
10. O README afirma degradação silenciosa de campos não suportados; silêncio reduz observabilidade e pode enfraquecer gates.

