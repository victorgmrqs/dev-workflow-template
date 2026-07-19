---
name: code-review-task
description: >
  Code review automatizado do branch atual contra o branch base.
  Valida styleguide, executa lint/typecheck/testes reais, verifica os
  cenários obrigatórios do ticket, docs-guard, bug-hunt por stack
  (packs/) e suficiência de testes. Emite veredito APROVADO/REPROVADO.
  Chamada pela Fase 6.5 do /task ou avulsa.
  Uso: /code-review-task <TICKET-ID>
disable-model-invocation: true
argument-hint: <TICKET-ID>
context: fork
agent: reviewer
---

# Skill: /code-review-task

## Objetivo

Gate de qualidade antes do commit: revisar **apenas o diff do branch atual** contra o branch base e emitir veredito objetivo. Não é refatoração — é verificação de conformidade com o que o projeto já definiu.

## Etapa 0 — Configuração

Leia `.dev-workflow/workflow.config.yaml`; use `.claude/workflow.config.yaml` apenas como fallback legado com aviso. Consuma `git.base_branch`, `commands.*`, `quality_gates.*`, `domains`, `docs_map`, `documentation_policy`, `confluence` e `evidence`. Sem config: pare e peça `/setup-project`.

## Etapa 1 — Coleta

1. Diff: `git diff <base>...HEAD` + `git status` (untracked). Pré-commit (fluxo /task): working tree (`git diff <base>` + novos).
2. Contexto: `AGENTS.md`, contexto específico presente (`CLAUDE.md`/`GEMINI.md`), rules de `.agents/rules/` e/ou `.claude/rules/` que casem com o diff, e o FDD do domínio.
3. Ticket: `task-brief.yaml` se existir; senão, resolva `jira.issue.read` conforme `../../integrations/atlassian-mcp.md` (ou use a descrição do usuário em modo local).

## Etapa 2 — Checklist de styleguide (análise do diff)

Verifique o diff contra:

1. As **rules do projeto** (`.agents/rules/` e/ou `.claude/rules/`) aplicáveis aos arquivos tocados — cada violação é achado com a rule citada.
2. Restrições de `AGENTS.md` e do contexto específico da plataforma presente.
3. Segurança básica: nenhum segredo hardcoded/logado, nenhum dado sensível em log, `.env` fora do versionamento.
4. Regras de negócio: implementação nova referencia o ID da regra (`DOM-XX`) e a regra existe em `docs/domain-context.md`.

## Etapa 3 — Verificações executáveis (capturar resultado real, nunca assumir)

Execute os comandos definidos em `commands`: `lint`, `typecheck`, `test` (e `build`, `coverage`, `e2e` quando definidos e o diff justificar).

- Qualquer erro = **bloqueador**.
- `quality_gates.coverage_threshold` definido e não atingido = **bloqueador** (idem `coverage_strict_paths`).

## Etapa 4 — Cenários obrigatórios do ticket

Compare os testes existentes com os cenários obrigatórios (brief/FDD):

- Caminho feliz presente? Um teste por linha da matriz de erros do FDD §6 coberta pelo escopo?
- Nomes seguem a convenção do projeto?

Cenário obrigatório ausente = **bloqueador**; borda fora da matriz = recomendação com o caso proposto.

## Etapa 4.5 — Docs-guard

Execute `TICKET_ID=<TICKET-ID> scripts/docs-guard.sh` (se existir; mesma regra do CI) **e** aplique semanticamente o `docs_map` da config. Verifique obrigatoriamente:

1. `CHANGELOG.md` alterado em toda tarefa, sob `[Unreleased]`, com resumo breve na categoria permitida e link Markdown para o card Jira; ausência, ID sem link ou texto sem relação com a entrega = **bloqueador**.
2. Cada linha aplicável do `docs_map` atualizou o documento correto com conteúdo correspondente à mudança, não apenas um toque mecânico.
3. Cada nível técnico/funcional/operacional do brief tem documento atualizado ou justificativa específica de não aplicabilidade.
4. Com Jira configurado, o ticket existe no Histórico de entregas do Confluence e páginas funcionais/operacionais aplicáveis foram atualizadas. Ausência, integração desabilitada ou indisponibilidade externa ainda não sincronizada = **bloqueador**.

Evidência (`evidence.type`) ausente = bloqueador.

## Etapa 4.6 — Bug-hunt no diff (correção, não estilo)

Releia o diff procurando **bugs**. Carregue `packs/<quality_gates.review_pack>.md` relativamente a esta skill (fallback: `packs/generic.md`) e aplique cada padrão listado.

Classificação: bug provável com impacto real = **bloqueador**; suspeita/risco teórico = recomendação com justificativa.

## Etapa 4.7 — Suficiência de testes

1. Rode `commands.coverage` se definido (senão registre como recomendação de tooling e analise o diff manualmente).
2. Para cada branch novo/alterado sem cobertura: implementa regra `DOM-XX` ou linha da matriz de erros → **bloqueador**; demais bordas → recomendação com caso proposto (nome + cenário).
3. **Qualidade das asserções** — teste que se enquadre nos anti-padrões abaixo conta como **ausente**:

| # | Anti-padrão | Sinal |
|---|-------------|-------|
| 1 | Trivial | testa constante/estrutura estática sem comportamento |
| 2 | Snapshot-only | único snapshot como toda a asserção |
| 3 | Sem asserção | executa sem nenhum `expect`/`assert` |
| 4 | Mock-heavy | mocka a própria unidade sob teste; só verifica que o mock foi chamado |
| 5 | Detalhe de implementação | assere estado interno em vez de saída observável |
| 6 | Duplicado/inflado | testes idênticos para subir %; asserções tautológicas |

## Etapa 4.8 — Security review portátil e extras de plataforma

- Uma **security review é OBRIGATÓRIA** quando o diff toca autenticação/autorização/sessão/tokens, SQL bruto, upload/parsing, conteúdo de usuário/LLM, adapters com chaves, CORS/headers, ownership ou variáveis públicas. Verifique ao menos: autenticação versus autorização, isolamento por owner/tenant, injeção, traversal, XSS, SSRF, secrets/logs, validação de arquivos e fail-closed. Achado alto = bloqueador.
- No Claude Code, `/security-review` pode complementar o checklist. No Antigravity, use uma skill/plugin de segurança disponível ou execute o checklist portátil. A ausência do extra nativo nunca elimina o checklist.
- Um review adicional de alto esforço é recomendado no fechamento de cada fase do roadmap.

## Etapa 5 — Veredito

```
## Code Review — <TICKET-ID>

**Veredito: APROVADO | REPROVADO**

### Bloqueadores (impedem commit)
- [arquivo:linha] descrição objetiva + regra violada

### Recomendações (não bloqueiam)
- [arquivo:linha] sugestão

### Execuções
- lint: ✅/❌ · typecheck: ✅/❌ · testes: ✅ N / ❌ · build: ✅/—/❌ · coverage: X%/—

### Cenários obrigatórios
- [x] <presentes> · [ ] <ausentes> ← AUSENTE

### Docs-guard
- changelog + link do card: ✅/❌
- Histórico de entregas: ✅/❌/pendente externo
- técnico | funcional | operacional: ✅/não aplicável (<justificativa>)/❌
- <linha do docs_map>: ✅/—/❌ (por item aplicável)

### Bug-hunt (<pack>)
- N achados por severidade, ou "nenhum padrão do pack encontrado"

### Suficiência de testes
- Coverage do diff: X% · branches sem teste: [lista com caso proposto]
- security review: portátil ✅; extra nativo/plugin: executado ✅ / indisponível — (achados: N)

### Checklist do PR (para a Fase 7 do /task)
- Itens verificados para pré-marcar: [lista]
- Itens específicos da task a acrescentar: [lista]
```

## Restrições

- Reporte; **não corrija código** nesta skill (a correção é do fluxo chamador).
- Não aprove com bloqueador aberto — não existe "aprovado com ressalvas bloqueadoras".
- Revise somente o diff do branch; problemas pré-existentes viram observação final, não achado.
