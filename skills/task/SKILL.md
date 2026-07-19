---
name: task
description: >
  Workflow completo de implementação a partir de um ticket.
  Lê o ticket (Jira via MCP, quando configurado), carrega contexto JIT do
  projeto, gera um task-brief.yaml para aprovação (checkpoint 1), cria o
  branch e move o card, implementa, testa, atualiza documentação via
  /docs-sync, valida o DoD (checkpoint 2), executa o gate /code-review-task,
  commita, faz push e move o card para In Review. PR e merge são manuais.
  Requer .dev-workflow/workflow.config.yaml (crie com /setup-project;
  .claude/workflow.config.yaml legado continua aceito durante a migração).
  Uso: /task <TICKET-ID>   ex: /task SKC-12
disable-model-invocation: true
argument-hint: <TICKET-ID>
---

# Skill: /task

## Objetivo

Executar o ciclo completo de desenvolvimento para um ticket com **dois checkpoints de aprovação humana** e **um gate de code review automatizado**. Documentação e testes fazem parte da entrega — não são etapas posteriores.

## Fase 0 — Configuração

Resolva a configuração nesta ordem:

1. `.dev-workflow/workflow.config.yaml` (canônica e multiplataforma);
2. `.claude/workflow.config.yaml` (legada; aceite com aviso de depreciação).

Se nenhuma existir, pare e instrua o usuário a rodar `/setup-project`.

Deste arquivo vêm todos os parâmetros usados abaixo: `tracker.*` (Jira/none), `git.*` (branch base, padrões), `commands.*` (lint/typecheck/test/build), `domains` (prefixo → FDD), `context_files`, `evidence`, `dod_extra`, `quality_gates`, `docs_map`, `documentation_policy` e `confluence`.

**Guard multi-repo:** se `tracker.ticket_prefix_guard` estiver definido e o título do ticket contiver o prefixo indicado para outro repositório, avise o usuário e **pare** (o ticket pertence ao repo irmão).

**Modo local (sem tracker):** se `tracker.provider: none`, o argumento é um identificador livre (ex: `TASK-auth-refresh`); pule as interações com Jira (Fases 1.1 parcial, 3.0 item 2 e 8 item 3) e use a descrição fornecida pelo usuário como ticket.

## Fase 1 — Carregamento de contexto (JIT)

1. **Ticket:** quando `tracker.provider: jira`, faça o pre-flight descrito em `../../integrations/atlassian-mcp.md`, relativo a esta skill. Resolva `jira.issue.read` no servidor `tracker.mcp_server` (default `MCP_DOCKER`) e leia o ticket. Extraia: título, descrição, tipo, critérios de aceite e comentários relevantes. Não presuma o nome concreto da tool.
2. **Contexto fixo:** leia os arquivos de `context_files` (lista curta por design — não carregue docs fora dela).
3. **Contexto por domínio:** identifique o domínio pelo prefixo/título do ticket e carregue **apenas o FDD correspondente** via `domains[].fdd`. Carregue `docs/adr/` somente se a task envolver decisão arquitetural. Se `project.canonical_docs_path` apontar para outro repo (ex: `../sc-api`), os docs vêm de lá.

## Fase 2 — task-brief.yaml

Gere `task-brief.yaml` na raiz seguindo `../../templates/task-brief.schema.yaml`, resolvido relativamente ao diretório desta skill, preenchendo:

- `ticket` (id, título, tipo), `understanding` (problema e solução em 1–3 frases cada)
- `scope`: domínios, arquivos afetados, regras de negócio modificadas/novas, e os **flags de impacto** definidos no schema (contrato de API, contrato externo, migration, custo de IA, rotas/telas novas — preencha os que se aplicam à stack)
- `risks`: `adr_required`, `ambiguities`
- `documentation`: categoria e resumo do changelog, URL do card, impacto técnico/funcional/operacional, destinos e justificativas para itens não aplicáveis; `changelog.required` e `delivery_log.required` são sempre `true`
- `implementation_plan.steps` ordenados por dependência técnica
- `dod_checklist`: itens base do schema + `dod_extra` da config

### CHECKPOINT 1 — Aprovação do brief

Apresente o resumo (problema, solução, escopo, flags, ambiguidades, plano numerado) e pergunte: **"Aprova?"**

**Aguarde a resposta antes de continuar.** Se houver correções, atualize o `task-brief.yaml` e confirme antes de implementar.

## Fase 3.0 — Branch + card In Progress (imediatamente após o CHECKPOINT 1)

1. **Branch:** partir sempre de `git.base_branch` atualizado; nome conforme `git.branch_pattern`.
   - Se o branch base não existir (bootstrap), crie-o a partir de `main` e avise o usuário.
   - Nunca trabalhar diretamente em `main` ou no branch base.
2. **Card → In Progress:** use as capabilities `jira.transitions.list` e `jira.issue.transition` resolvidas no pre-flight. Descubra o ID comparando `to.name` com `tracker.columns.in_progress`, nunca pelo nome da transição. Se a coluna/capability não existir, avise e siga somente se `integrations.atlassian.fallback: local`; caso contrário, pare.

## Fase 3 — Implementação

Siga o plano aprovado. Regras obrigatórias:

- Convenções do projeto: leia `AGENTS.md` e, quando presente, o arquivo específico da plataforma (`CLAUDE.md`/`GEMINI.md`). Carregue rules aplicáveis em `.agents/rules/` e/ou `.claude/rules/` sem duplicar instruções.
- **Regra nova de negócio declarada no brief ⇒ documente em `docs/domain-context.md` antes de referenciá-la no código** (comentário `# DOM-XX` / `// DOM-XX` no ponto de aplicação).
- **Cada flag de impacto `true` no brief ⇒ atualize o doc correspondente junto com o código** (a tabela completa está no `docs_map` da config; o `/docs-sync` fecha o que faltar).
- **Toda tarefa ⇒ uma entrada breve no `CHANGELOG.md` vinculada ao card**, independentemente do tipo (`feature`, `fix`, `chore`, `refactor`, docs ou infraestrutura) e dos arquivos tocados.
- Documentação de implementação, contratos, ADRs e runbooks executáveis fica no repositório; documentação de funcionalidade, regras para usuários e visão operacional de alto nível fica no Confluence.
- Nunca logar dados sensíveis; segredos apenas via env/config.
- **Delegação (economia de contexto):** blocos mecânicos e bem especificados podem ser delegados ao agent `implementer` pelo mecanismo de subagentes disponível no host (Agent tool no Claude Code; `invoke_subagent` no Antigravity), passando o trecho do plano + arquivos-alvo. Se subagentes não estiverem disponíveis, execute inline e registre o fallback. Mantenha no main loop tudo que exige decisão.

## Fase 4 — Testes

Cada use case/componente novo ou modificado deve ter teste com os **cenários obrigatórios**:

- `test_<unidade>_success` (ou convenção equivalente da stack) — caminho feliz
- **Um teste por linha da matriz de erros do FDD (seção 6)** coberta pelo escopo do ticket
- Dependências externas (IA, storage, rede) são fakes/mocks determinísticos nos testes de unidade

Execute `commands.test` e capture o resultado real. **Após os testes passarem**, crie a evidência conforme `evidence.type`:
- `http` → arquivo `.http` em `evidence.path`, um request comentado por cenário (fluxos assíncronos: criação + polling até estado terminal)
- `screenshot` → screenshot/GIF das telas alteradas, referenciado no brief/PR
- `cli-output` → saída real do comando registrada em `evidence.path`

## Fase 5 — Documentação

**Invoque a skill `/docs-sync`** pelo mecanismo de skills do host, passando o ticket ID. Se o host não permitir invocação programática, siga diretamente as instruções dessa skill e registre `fallback: inline`. Confirme no relatório: changelog com link para o card, registro no Histórico de entregas, docs de impacto e justificativas de não aplicabilidade. Pendências entram no relatório e bloqueiam a entrega; indisponibilidade externa deve ser corrigida e a sincronização repetida antes do DoD.

## Fase 6 — Validação do DoD

### CHECKPOINT 2 — Aprovação final

Verifique cada item do `dod_checklist` de fato (não assuma) e apresente o status `PRONTO / PENDENTE` com a lista do que falta. **Aguarde aprovação antes do code review.**

## Fase 6.5 — Code Review (gate automatizado)

**Invoque a skill `/code-review-task`** pelo mecanismo de skills do host; fallback inline deve ser explícito no relatório.

- **REPROVADO:** corrija os bloqueadores e execute o review novamente. Não prossiga com bloqueadores abertos.
- **APROVADO:** siga para a Fase 7. Recomendações não-bloqueadoras: aplicar agora ou registrar no ticket.

## Fase 7 — PR Description

Gere o body do PR **sobre** `.github/pull_request_template.md` (não edite o template):

1. Preencha todas as seções (ticket, o que foi feito, como testar, regras afetadas, veredito do review).
2. **Pré-marque** apenas os itens que o `/code-review-task` verificou de fato; deixe `[ ]` com nota o que não se aplica.
3. Acrescente os itens de checklist específicos da task indicados pelo review.

## Fase 8 — Entrega

Somente após veredito APROVADO:

1. **Commit:** conforme `git.commit_pattern` (ex: `feat(SKC-12): add register use case`). Commits atômicos se houver partes independentes; `task-brief.yaml` fora do commit.
2. **Push:** `git push -u origin <branch>`. Sem remote: avise e pare (não crie remote sem pedido).
3. **Card → In Review** pelas capabilities `jira.transitions.list`/`jira.issue.transition`, seguido de `jira.issue.comment` com resumo, branch, veredito, PR description e links para changelog, documentação técnica, páginas funcionais e Histórico de entregas. Não repita uma mutação se a resposta for ambígua: releia o ticket antes de decidir.
4. Informe: branch publicado, card movido — abrir PR e mergear são manuais; `Done` é manual no merge.

## Restrições

- Não implemente nada antes do CHECKPOINT 1 aprovado.
- Não marque DoD sem verificar cada item; não commite antes do APROVADO da Fase 6.5.
- Não abra PR nem faça merge — decisão do usuário.
- Ambiguidade sem resposta: pare e pergunte — não assuma.
- `task-brief.yaml` nunca é versionado (garanta no `.gitignore`).
