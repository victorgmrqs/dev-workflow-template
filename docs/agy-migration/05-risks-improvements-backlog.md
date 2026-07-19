# 5. Riscos, melhorias e backlog

## 5.1 Registro de riscos

Escala: probabilidade (P) e impacto (I) de 1 a 5; prioridade = P × I.

| ID | Risco | P | I | Prioridade | Mitigação | Evidência/controle |
|---|---|---:|---:|---:|---|---|
| R01 | frontmatter Claude ser ignorado ou mudar semântica no Agy | 4 | 5 | 20 | adapter mínimo e contract tests por versão | skills listadas + teste de invocação |
| R02 | model routing não ter paridade | 5 | 3 | 15 | profiles funcionais; modelo como hint | relatório indica modelo herdado |
| R03 | hook Agy repetir ou bloquear o loop | 3 | 5 | 15 | `invocationNum == 0`, timeout e fixtures stdin/stdout | hook test + `/hooks` |
| R04 | caminhos físicos de staging mudarem | 4 | 4 | 16 | referências relativas e resolver de assets | instalação local/remota |
| R05 | names de tools MCP variarem | 4 | 5 | 20 | capability discovery e pre-flight | doctor mostra mapa real |
| R06 | ticket/Confluence real alterado em teste | 2 | 5 | 10 | sandbox dedicado e deny-by-default | IDs sandbox e auditoria |
| R07 | push/commit ocorrer sem checkpoint | 2 | 5 | 10 | máquina de estados e permissões | teste negativo de cada gate |
| R08 | drift entre core e adapters | 4 | 4 | 16 | geração determinística e CI | `build && git diff --exit-code` |
| R09 | regressão no plugin Claude | 3 | 5 | 15 | snapshots e matriz dual | smoke test de versão mínima |
| R10 | config duplicada divergir | 4 | 4 | 16 | uma fonte canônica + fallback read-only | doctor acusa duplicidade |
| R11 | rules path-scoped terem semântica diferente | 3 | 4 | 12 | fixtures por glob/plataforma | testes de ativação |
| R12 | segurança enfraquecida ao substituir `/security-review` | 3 | 5 | 15 | checklist portátil + plugin opcional + gate | cenários sensíveis obrigatórios |
| R13 | shell não funcionar em Windows | 4 | 3 | 12 | declarar suporte, WSL ou scripts cross-platform | matriz OS |
| R14 | prompts longos aumentarem contexto/custo | 3 | 3 | 9 | progressive disclosure e assets sob demanda | orçamento de tokens/tamanho |
| R15 | documentação oficial Agy mudar rapidamente | 4 | 4 | 16 | versão mínima, testes semanais/por release | job de compatibilidade |
| R16 | permissões amplas para subagentes/MCP | 3 | 5 | 15 | least privilege; write/MCP off por padrão | policy tests |
| R17 | dependência em Git branch/remotes frágeis | 3 | 4 | 12 | pre-flight e modo dry-run | fixtures sem remote/base |
| R18 | estado efêmero sobrescrever outro ticket | 3 | 4 | 12 | brief por ID em `.dev-workflow/state/` | teste concorrente |
| R19 | updates quebrarem configs antigas | 3 | 4 | 12 | `schema_version` + migrations idempotentes | fixtures v0/v1 |
| R20 | duplicação de skills por template + plugin | 3 | 3 | 9 | doctor detecta shadowing; docs de remoção | teste de resolução de nomes |

## 5.2 Melhorias priorizadas

| Melhoria | Impacto | Esforço | Prioridade | Justificativa |
|---|---|---|---|---|
| schema formal + `schema_version` | alto | médio | P0 | impede config inválida e habilita evolução |
| core + adapters gerados | alto | alto | P0 | resolve acoplamento e duplicação estrutural |
| testes de contrato e fixtures | alto | médio | P0 | hoje não existe proteção de comportamento |
| capability discovery/doctor | alto | médio | P0 | evita falha tardia em MCP/tools |
| config neutra `.dev-workflow/` | alto | médio | P0 | remove principal acoplamento de workspace |
| hook extraído e testável | alto | baixo | P0 | reduz risco de loop e melhora portabilidade |
| segurança portátil no review | alto | médio | P0 | substitui dependência nativa incompatível |
| máquina de estados explícita de `/task` | alto | alto | P1 | checkpoints e efeitos ficam auditáveis |
| estado por ticket, não arquivo único | alto | baixo | P1 | permite retomada e evita colisão |
| agents por profiles funcionais | médio | médio | P1 | remove lock-in de modelos |
| geração dual de rules/skills locais | alto | médio | P1 | fecha bootstrap Agy sem duplicação manual |
| dry-run para task/ticket/docs | alto | médio | P1 | reduz risco operacional |
| logs estruturados sem dados sensíveis | médio | médio | P1 | melhora suporte e auditoria |
| docs-guard cross-platform | médio | médio | P2 | amplia Windows sem alterar núcleo |
| reduzir duplicação em product-manager | médio | baixo | P2 | `REFERENCE.md` e resource repetem conteúdo |
| normalizar idioma e nomenclatura | baixo | baixo | P2 | skills misturam inglês/pt-BR e “Etapa/Fase” |
| orçamento de contexto por skill | médio | baixo | P2 | algumas skills têm 300–460 linhas e resources grandes |
| adapter Codex | médio | médio | futuro | arquitetura permitirá, mas fora do escopo imediato |

## 5.3 Backlog técnico por fase

### Fase 1 — Preparação

| ID | Item | Estimativa | Dependências | Aceite resumido |
|---|---|---:|---|---|
| PREP-01 | criar schemas formais | 1 DE | — | fixtures válidas/inválidas cobertas |
| PREP-02 | inventário de capabilities/efeitos | 0,5 DE | — | 11 skills classificadas |
| PREP-03 | fixtures de workspaces | 1 DE | — | 4 stacks/estados representados |
| PREP-04 | lint/validation scripts | 1 DE | PREP-01 | CI valida JSON/YAML/frontmatter/shell/Python |
| PREP-05 | snapshots Claude v0.1.0 | 0,5 DE | PREP-03 | baseline versionada |

### Fase 2 — Abstrações

| ID | Item | Estimativa | Dependências | Aceite resumido |
|---|---|---:|---|---|
| CORE-01 | criar layout core/shared/adapters | 0,5 DE | PREP-* | build mínimo executa |
| CORE-02 | extrair assets e templates | 1 DE | CORE-01 | hashes/conteúdo equivalentes |
| CORE-03 | config neutra + migration/fallback | 1 DE | PREP-01 | v0.1.0 segue legível |
| CORE-04 | profiles de agentes/capabilities | 1 DE | PREP-02 | Claude gerado preserva routing |
| CORE-05 | extrair hook e serializer Claude | 0,5 DE | CORE-01 | comportamento idêntico |
| CORE-06 | migrar skills de planning | 0,5–1 DE | CORE-02 | snapshots equivalentes |
| CORE-07 | migrar bootstrap/execution | 1–2 DE | CORE-03/04 | smoke Claude verde |

### Fase 3 — Antigravity

| ID | Item | Estimativa | Dependências | Aceite resumido |
|---|---|---:|---|---|
| AGY-01 | manifesto e build Agy | 0,5 DE | CORE-01 | schema oficial válido |
| AGY-02 | serializer de skills/frontmatter | 1 DE | CORE-06 | 11 skills descobertas |
| AGY-03 | adapter de paths/context/rules | 1 DE | CORE-03 | `.agents/*` gerado corretamente |
| AGY-04 | hook PreInvocation | 0,5–1 DE | CORE-05 | roda uma vez e injeta JSON válido |
| AGY-05 | agents/subagent adapter | 1–2 DE | CORE-04 | roles invocáveis; fallback explícito |
| AGY-06 | security review portátil | 1 DE | PREP-02 | superfícies sensíveis bloqueiam corretamente |
| AGY-07 | vertical slice local | 1–1,5 DE | AGY-01..06 | task completa sem Atlassian |

### Fase 4 — Testes e integrações

| ID | Item | Estimativa | Dependências | Aceite resumido |
|---|---|---:|---|---|
| INT-01 | doctor/capability discovery | 1 DE | PREP-02 | missing tools detectadas antes do fluxo |
| INT-02 | MCP Atlassian adapter | 1–1,5 DE | INT-01 | Jira sandbox ponta a ponta |
| INT-03 | Confluence adapter | 0,5 DE | INT-01 | update e fallback validados |
| TEST-01 | matriz CLI/OS | 1–1,5 DE | AGY-07 | versões mínimas verdes |
| TEST-02 | segurança, paths e concorrência | 1 DE | CORE-03/AGY-04 | cenários negativos cobertos |

### Fase 5 — Release

| ID | Item | Estimativa | Dependências | Aceite resumido |
|---|---|---:|---|---|
| DOC-01 | README dual e migration guide | 0,5–1 DE | AGY-07 | instalação limpa reproduzida |
| DOC-02 | troubleshooting/capability matrix | 0,5 DE | INT-01 | falhas conhecidas pesquisáveis |
| REL-01 | prerelease + pilotos | 1 DE | TEST-* | Python e TS completam fluxo |
| REL-02 | release estável/rollback | 0,5 DE | REL-01 | tag, changelog e rollback testados |

## 5.4 Definition of Done da migração

- [ ] O mesmo core gera distribuições Claude e Agy sem edição manual.
- [ ] As 11 skills estão disponíveis nas duas plataformas.
- [ ] Os dois checkpoints de `/task` e o gate de review são preservados.
- [ ] Nenhuma action remota ocorre quando capability/permissão está ausente.
- [ ] Routing de modelo degradado é relatado, nunca presumido.
- [ ] Config v0.1.0 é migrável e continua legível durante a janela de compatibilidade.
- [ ] Hooks, schemas, scripts e adapters têm testes automatizados.
- [ ] Jira/Confluence foram testados apenas em sandbox.
- [ ] Instalação, update, disable/uninstall e rollback estão documentados.
- [ ] README não confunde Agy, Gemini CLI e Agents CLI.

## 5.5 Métricas operacionais sugeridas

- taxa de instalação e discovery bem-sucedidas por versão de CLI;
- duração e falhas de hook;
- percentual de skills executadas `native`, `portable`, `inline`, `unsupported`;
- falhas de capability pre-flight;
- regressões de snapshot por adapter;
- número de checkpoints respeitados/abortados;
- tempo médio do vertical slice e custo/contexto por skill;
- incidentes de permissão, secrets ou efeitos externos indevidos (meta: zero).
