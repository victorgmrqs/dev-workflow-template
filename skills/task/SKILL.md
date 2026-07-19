---
name: task
description: >
  Workflow completo de implementação a partir de um ticket.
  Lê o ticket (Jira via MCP, quando configurado), carrega contexto JIT do
  projeto, gera um task-brief.yaml para aprovação (checkpoint 1), cria o
  branch e move o card, implementa, testa, atualiza documentação via
  /docs-sync, valida o DoD (checkpoint 2), executa o gate /code-review-task,
  commita, faz push e move o card para In Review. PR e merge são manuais.
  Requer .claude/workflow.config.yaml (crie com /setup-project).
  Uso: /task <TICKET-ID>   ex: /task SKC-12
disable-model-invocation: true
argument-hint: <TICKET-ID>
---

# Skill: /task

## Objetivo

Executar o ciclo completo de desenvolvimento para um ticket com **dois checkpoints de aprovação humana** e **um gate de code review automatizado**. Documentação e testes fazem parte da entrega — não são etapas posteriores.

## Fase 0 — Configuração

Leia `.claude/workflow.config.yaml`. **Se não existir, pare** e instrua o usuário a rodar `/setup-project`.

Deste arquivo vêm todos os parâmetros usados abaixo: `tracker.*` (Jira/none), `git.*` (branch base, padrões), `commands.*` (lint/typecheck/test/build), `domains` (prefixo → FDD), `context_files`, `evidence`, `dod_extra`, `quality_gates`.

**Guard multi-repo:** se `tracker.ticket_prefix_guard` estiver definido e o título do ticket contiver o prefixo indicado para outro repositório, avise o usuário e **pare** (o ticket pertence ao repo irmão).

**Modo local (sem tracker):** se `tracker.provider: none`, o argumento é um identificador livre (ex: `TASK-auth-refresh`); pule as interações com Jira (Fases 1.1 parcial, 3.0 item 2 e 8 item 3) e use a descrição fornecida pelo usuário como ticket.

## Fase 1 — Carregamento de contexto (JIT)

1. **Ticket:** leia via MCP Atlassian (cloudId e projeto em `tracker`). Extraia: título, descrição, tipo, critérios de aceite, comentários relevantes.
2. **Contexto fixo:** leia os arquivos de `context_files` (lista curta por design — não carregue docs fora dela).
3. **Contexto por domínio:** identifique o domínio pelo prefixo/título do ticket e carregue **apenas o FDD correspondente** via `domains[].fdd`. Carregue `docs/adr/` somente se a task envolver decisão arquitetural. Se `project.canonical_docs_path` apontar para outro repo (ex: `../sc-api`), os docs vêm de lá.

## Fase 2 — task-brief.yaml

Gere `task-brief.yaml` na raiz seguindo o schema em `${CLAUDE_PLUGIN_ROOT}/templates/task-brief.schema.yaml`, preenchendo:

- `ticket` (id, título, tipo), `understanding` (problema e solução em 1–3 frases cada)
- `scope`: domínios, arquivos afetados, regras de negócio modificadas/novas, e os **flags de impacto** definidos no schema (contrato de API, contrato externo, migration, custo de IA, rotas/telas novas — preencha os que se aplicam à stack)
- `risks`: `adr_required`, `ambiguities`
- `implementation_plan.steps` ordenados por dependência técnica
- `dod_checklist`: itens base do schema + `dod_extra` da config

### CHECKPOINT 1 — Aprovação do brief

Apresente o resumo (problema, solução, escopo, flags, ambiguidades, plano numerado) e pergunte: **"Aprova?"**

**Aguarde a resposta antes de continuar.** Se houver correções, atualize o `task-brief.yaml` e confirme antes de implementar.

## Fase 3.0 — Branch + card In Progress (imediatamente após o CHECKPOINT 1)

1. **Branch:** partir sempre de `git.base_branch` atualizado; nome conforme `git.branch_pattern`.
   - Se o branch base não existir (bootstrap), crie-o a partir de `main` e avise o usuário.
   - Nunca trabalhar diretamente em `main` ou no branch base.
2. **Card → In Progress:** `getTransitionsForJiraIssue` para descobrir o ID da transição (compare pelo `to.name`, não pelo nome da transição) e `transitionJiraIssue` para `tracker.columns.in_progress`. Se a coluna não existir, avise e siga.

## Fase 3 — Implementação

Siga o plano aprovado. Regras obrigatórias:

- Convenções do projeto: `CLAUDE.md` + rules em `.claude/rules/` (geradas por `/generate-rules`).
- **Regra nova de negócio declarada no brief ⇒ documente em `docs/domain-context.md` antes de referenciá-la no código** (comentário `# DOM-XX` / `// DOM-XX` no ponto de aplicação).
- **Cada flag de impacto `true` no brief ⇒ atualize o doc correspondente junto com o código** (a tabela completa está no `docs_map` da config; o `/docs-sync` fecha o que faltar).
- Nunca logar dados sensíveis; segredos apenas via env/config.
- **Delegação (economia de contexto):** blocos mecânicos e bem especificados do plano (ex: gerar boilerplate de testes, aplicar padrão repetitivo em N arquivos) podem ser delegados ao agent `implementer` via Agent tool, passando o trecho do plano + arquivos-alvo. Mantenha no main loop tudo que exige decisão.

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

**Invoque a skill `/docs-sync`** (via Skill tool) passando o ticket ID. Revise o relatório dela antes de seguir — pendências (ex: Confluence) entram no comentário do ticket na Fase 8.

## Fase 6 — Validação do DoD

### CHECKPOINT 2 — Aprovação final

Verifique cada item do `dod_checklist` de fato (não assuma) e apresente o status `PRONTO / PENDENTE` com a lista do que falta. **Aguarde aprovação antes do code review.**

## Fase 6.5 — Code Review (gate automatizado)

**Invoque a skill `/code-review-task`** passando o ticket ID.

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
3. **Card → In Review** + comentário no ticket com: resumo, branch, veredito do review e a PR description pronta para colar.
4. Informe: branch publicado, card movido — abrir PR e mergear são manuais; `Done` é manual no merge.

## Restrições

- Não implemente nada antes do CHECKPOINT 1 aprovado.
- Não marque DoD sem verificar cada item; não commite antes do APROVADO da Fase 6.5.
- Não abra PR nem faça merge — decisão do usuário.
- Ambiguidade sem resposta: pare e pergunte — não assuma.
- `task-brief.yaml` nunca é versionado (garanta no `.gitignore`).
