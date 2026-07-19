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

Leia `.claude/workflow.config.yaml` (`git.base_branch`, `commands.*`, `quality_gates.*`, `domains`, `docs_map`, `evidence`). Sem config: pare e peça `/setup-project`.

## Etapa 1 — Coleta

1. Diff: `git diff <base>...HEAD` + `git status` (untracked). Pré-commit (fluxo /task): working tree (`git diff <base>` + novos).
2. Contexto: `CLAUDE.md`, rules de `.claude/rules/` que casem com os arquivos do diff, e o FDD do domínio do ticket (matriz de erros §6, critérios §9).
3. Ticket: `task-brief.yaml` na raiz se existir; senão, MCP Atlassian (ou descrição do usuário em modo local).

## Etapa 2 — Checklist de styleguide (análise do diff)

Verifique o diff contra:

1. As **rules do projeto** (`.claude/rules/`) aplicáveis aos arquivos tocados — cada violação é achado com a rule citada.
2. Restrições do `CLAUDE.md` (tipagem estrita sem escapes não justificados, camadas/ports respeitados, nomenclatura consistente com o código vizinho).
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

Execute `scripts/docs-guard.sh` (se existir; mesma regra do CI) **e** aplique semanticamente o `docs_map` da config: para cada linha cujo padrão casa com o diff, confira se o doc exigido foi atualizado **e se o conteúdo corresponde à mudança** (não apenas se o arquivo foi tocado). Severidade conforme a config. Evidência (`evidence.type`) ausente = bloqueador.

## Etapa 4.6 — Bug-hunt no diff (correção, não estilo)

Releia o diff procurando **bugs**. Carregue o pack da stack: `${CLAUDE_PLUGIN_ROOT}/skills/code-review-task/packs/<quality_gates.review_pack>.md` (fallback: `generic.md`) e aplique cada padrão listado.

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

## Etapa 4.8 — Reviews nativos do Claude Code (camada extra)

- **`/security-review` é OBRIGATÓRIO** quando o diff toca superfície sensível: autenticação/autorização/sessão/tokens, SQL bruto, upload/parsing de arquivos, renderização de conteúdo de usuário/LLM, adapters com chaves, CORS/headers, filtros de ownership, variáveis públicas novas. Achados de severidade alta = bloqueador.
- **`/code-review` com esforço alto** é recomendado no fechamento de cada fase do roadmap (diff acumulado do épico), fora do fluxo por task.

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
- <linha do docs_map>: ✅/—/❌ (por item aplicável)

### Bug-hunt (<pack>)
- N achados por severidade, ou "nenhum padrão do pack encontrado"

### Suficiência de testes
- Coverage do diff: X% · branches sem teste: [lista com caso proposto]
- /security-review nativo: executado ✅ (achados: N) / não exigido

### Checklist do PR (para a Fase 7 do /task)
- Itens verificados para pré-marcar: [lista]
- Itens específicos da task a acrescentar: [lista]
```

## Restrições

- Reporte; **não corrija código** nesta skill (a correção é do fluxo chamador).
- Não aprove com bloqueador aberto — não existe "aprovado com ressalvas bloqueadoras".
- Revise somente o diff do branch; problemas pré-existentes viram observação final, não achado.
