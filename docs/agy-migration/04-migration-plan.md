# 4. Plano incremental de implementação

## Premissas de estimativa

- Unidade: **dia de engenharia (DE)** de uma pessoa experiente no repositório.
- Inclui implementação, testes e documentação; não inclui espera por review externo ou credenciais Jira/Confluence.
- Faixas refletem a incerteza do schema de agents Agy e dos smoke tests de CLI.
- Total recomendado: **16–25 DE** para paridade funcional segura; MVP local sem Atlassian: **8–12 DE**.

## Fase 1 — Preparação e contratos (3–4 DE)

### Objetivo

Criar uma linha de base verificável antes de mover conteúdo.

### Tarefas

1. Fixar versões mínimas testadas de Claude Code e `agy`.
2. Criar fixtures de projeto consumidor: vazio, Python, Next e Electron.
3. Formalizar schemas de `workflow.config` e `task-brief`.
4. Inventariar capabilities por skill e efeitos externos.
5. Adicionar validação de JSON/YAML/frontmatter, links relativos e shell.
6. Criar snapshots do layout Claude v0.1.0 para impedir regressão.
7. Documentar a política de segredos e permissões.

### Arquivos afetados

- novos `shared/*.schema.json`, `shared/capabilities.yaml`;
- novos `tests/fixtures`, `tests/contracts`, `scripts/validate-dist.sh`;
- `README.md` e CI.

### Riscos

- transformar exemplos comentados em schema pode expor inconsistências atuais;
- versões do Agy podem variar entre máquinas.

### Critérios de aceite

- repositório atual passa validação de Markdown/JSON/shell/Python;
- toda skill tem capabilities e efeitos classificados;
- fixtures reproduzem setup, modo local, review e docs guard;
- nenhum segredo real é necessário nos testes.

## Fase 2 — Abstrações e núcleo canônico (4–6 DE)

### Objetivo

Separar conteúdo de negócio de detalhes Claude sem mudar o comportamento Claude.

### Tarefas

1. Criar `core/`, `shared/` e `adapters/claude-code/`.
2. Extrair templates, packs e fundamentos sem alteração semântica.
3. Definir profiles de agente e capability mapping.
4. Introduzir config `.dev-workflow/` com fallback `.claude/`.
5. Extrair o hook inline para script testável.
6. Construir gerador determinístico de artifacts Claude.
7. Migrar primeiro skills de planejamento; depois bootstrap; por último execução/review.
8. Comparar snapshots e executar smoke test Claude.

### Arquivos afetados

- `core/**`, `shared/**`, `adapters/claude-code/**`, `scripts/build-adapters.sh`;
- layout atual `skills/`, `agents/`, `hooks/`, `templates/` passa a ser gerado ou espelhado durante transição.

### Riscos

- diff grande e perda acidental de instruções;
- geração não determinística ou drift manual.

### Critérios de aceite

- build repetido não altera `git diff`;
- distribuição Claude conserva nomes, conteúdo e fluxo observável;
- CI falha se `dist` divergir do core;
- config antiga continua funcionando com aviso de depreciação.

## Fase 3 — Adapter Antigravity e vertical slice (4–7 DE)

### Objetivo

Entregar plugin nativo Agy funcional em modo local antes das integrações externas.

### Tarefas

1. Criar `plugin.json` root com schema oficial e apenas campos aceitos.
2. Gerar frontmatter Agy mínimo (`name`, `description`).
3. Gerar `hooks.json` root com `PreInvocation` e output estruturado.
4. Adaptar paths para `.agents/*`, `AGENTS.md` e config canônica.
5. Mapear delegação para subagentes Agy, com fallback inline explícito.
6. Implementar security checklist portátil em substituição aos reviews nativos Claude.
7. Testar `setup-project`, `task` local, `docs-sync` e `code-review-task` ponta a ponta.
8. Testar instalação local e remota com `agy plugin install`.
9. Verificar listagem em `/skills`, `/hooks` e `/agents`.

### Arquivos afetados

- `plugin.json`, `adapters/antigravity/**`, `dist/antigravity/**`;
- bodies de `task`, `code-review-task`, `docs-sync`, `setup-project`, `generate-rules` somente para intents neutras.

### Riscos

- campos de agents aceitos pelo loader não estão totalmente especificados;
- skill perigosa pode ser autoativada se a semântica de invocação diferir;
- hook pode repetir em todas as invocações se o guard falhar.

### Critérios de aceite

- `agy plugin install <path>` conclui sem erro de schema;
- as 11 skills aparecem e abrem os recursos corretos;
- o diagnóstico roda uma vez por conversa e nunca escreve arquivos;
- task em modo local respeita os dois checkpoints e o review gate;
- fallback inline aparece no relatório quando subagente não é usado;
- plugin Claude continua passando os smoke tests.

## Fase 4 — Integrações, testes e hardening (3–5 DE)

### Objetivo

Restaurar Jira/Confluence, provar compatibilidade e endurecer segurança.

### Tarefas

1. Adicionar `mcp_config.json` opcional ou instrução de instalação do Atlassian MCP.
2. Implementar pre-flight de capabilities e mapeamento de tools.
3. Testar leitura/criação/transição/comentário em Jira sandbox.
4. Testar update de Confluence com página de sandbox e modo ausente.
5. Cobrir hook I/O, config migration, docs guard, paths com espaços e multi-repo.
6. Testar permissões Agy: command, write_file, read_url e MCP.
7. Testar Linux/macOS; registrar Windows como suporte via WSL ou criar alternativa cross-platform.
8. Medir tamanho/contexto das descriptions e tempo dos hooks.

### Arquivos afetados

- `mcp_config.json`/template, adapters de integração, tests e docs de segurança.

### Riscos

- nomes/tools do MCP variam por servidor e versão;
- testes externos são flakey ou custosos;
- automação pode alterar tickets reais.

### Critérios de aceite

- testes externos usam projeto/space sandbox e IDs dedicados;
- ausência de MCP falha antes de qualquer mudança local relevante;
- credenciais não aparecem no repositório/logs;
- actions externas exigem permissão/checkpoint conforme política;
- matriz Claude/Agy está verde nas plataformas suportadas.

## Fase 5 — Documentação, release e operação (2–3 DE)

### Objetivo

Publicar uma versão suportável e reversível.

### Tarefas

1. Reescrever README com instalação Claude e Agy.
2. Criar guia de migração v0.1.0 → dual-platform.
3. Documentar capability matrix, fallbacks e troubleshooting.
4. Criar changelog e tag de prerelease.
5. Rodar piloto em um projeto real por stack.
6. Definir suporte, versionamento mínimo e política de compatibilidade.
7. Publicar release estável após o piloto.

### Arquivos afetados

- `README.md`, `CHANGELOG.md`, `docs/**`, release automation.

### Riscos

- documentação de paths Agy divergir entre versões;
- usuários confundirem Antigravity e Gemini CLI.

### Critérios de aceite

- instalação copiável funciona do zero nas duas plataformas;
- upgrade e rollback são documentados e testados;
- cada limitação conhecida tem comportamento/fallback explícito;
- pelo menos um projeto Python e um TypeScript completam o vertical slice.

## Sequenciamento recomendado

```text
F1 contratos
  ↓
F2 core + Claude regression safety
  ↓
F3 Agy local vertical slice
  ↓
F4 MCP + hardening
  ↓
F5 release
```

Não iniciar Jira/Confluence antes do vertical slice local. Isso separa bugs de plataforma de bugs de integração.

## Estratégia de release

| Release | Escopo | Sinal de avanço |
|---|---|---|
| `0.2.0-alpha.1` | core + adapter Claude | snapshots e smoke tests Claude verdes |
| `0.2.0-alpha.2` | Agy planning/bootstrap | instalação e skills Agy verdes |
| `0.2.0-beta.1` | task local + review/docs | vertical slice ponta a ponta |
| `0.2.0-rc.1` | Atlassian + hardening | sandbox Jira/Confluence e matriz OS |
| `0.2.0` | dual-platform suportado | pilotos concluídos, docs e rollback validados |

## Plano de rollback

- manter o layout Claude v0.1.0 publicável até a RC;
- cada dist é regenerável a partir de tag Git;
- Agy pode ser desabilitado/uninstalled sem alterar config do projeto consumidor;
- migração da config cria backup ou apenas copia para o novo path, nunca apaga a antiga automaticamente;
- efeitos remotos não são revertidos automaticamente; transições Jira são registradas para correção manual.
