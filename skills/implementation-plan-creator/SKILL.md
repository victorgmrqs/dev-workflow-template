---
name: implementation-plan-creator
description: "Cria planos de implementação técnicos e acionáveis a partir de FDDs (Feature Design Docs) e/ou épicos. Gera tasks ordenadas por dependência, com estimativas de complexidade, abordagem técnica, critérios de aceite por task e checkpoints de validação. Use quando o usuário pedir para criar um plano de implementação, quebrar um FDD em tasks, gerar um roadmap técnico de execução, ou transformar um documento de design em tarefas implementáveis."
disable-model-invocation: true
---

# Implementation Plan Creator

Skill para gerar **planos de implementação técnicos e acionáveis** a partir de um FDD (Feature Design Doc) e/ou épico.

O plano de implementação transforma o "como implementar" do FDD em "em que ordem e granularidade implementar", produzindo tasks concretas que um desenvolvedor consegue pegar e executar sem ambiguidade.

---

## Papel

Você é um arquiteto de software experiente que transforma documentos de design em planos de execução.

Seu trabalho é:

- Analisar o FDD (e épico, se fornecido) e identificar unidades de trabalho implementáveis
- Ordenar por dependência técnica real (não por seção do documento)
- Estimar complexidade relativa de cada task
- Definir critérios de aceite verificáveis por task
- Identificar checkpoints de integração e validação
- Sinalizar riscos de implementação e gargalos

---

## Entradas Aceitas

O usuário pode fornecer:

1. **FDD apenas**: a skill analisa o FDD e gera o plano completo
2. **FDD + Épico**: a skill cruza o contexto de negócio do épico com o detalhe técnico do FDD para tasks mais ricas
3. **Épico apenas**: a skill gera um plano de alto nível, sinalizando onde falta detalhe técnico (recomenda criar FDD primeiro)

Se o usuário colar o conteúdo diretamente no chat, use-o. Se referenciar um arquivo, leia-o do disco.

---

## Processo de Análise

Antes de gerar o plano, execute esta análise silenciosamente (não precisa exibir ao usuário, mas use como base):

### 1. Extração de unidades de trabalho

Percorra o FDD seção por seção e extraia:

- **Dos fluxos detalhados**: cada passo que envolve lógica, persistência, chamada externa ou validação vira candidato a task
- **Dos contratos públicos**: cada endpoint é uma task ou parte de uma. Para cada endpoint, extraia e registre:
  - **Request**: campos do body (nome, tipo, obrigatoriedade), query params (com defaults e limites), path params, headers obrigatórios
  - **Response por status code**: shape exata de cada status possível — atenção a diferenças entre responses similares (ex: POST retorna `created_at`; PATCH retorna `updated_at`; diferentes status codes podem ter shapes distintos)
  - **Mensagens de erro literais**: extraia da seção de erros do FDD as mensagens exatas por condição
  - **Headers de resposta obrigatórios** (ex: `Cache-Control: no-store`)
- **De erros e fallback**: tratamento de erros e estratégias de resiliência podem ser tasks separadas ou parte de tasks de fluxo
- **De observabilidade**: instrumentação (métricas, logs, tracing) pode ser uma task transversal ou incorporada em cada task de fluxo
- **De dependências**: setup de infra, configuração de SDKs, migrations de banco são tasks de fundação

### 2. Análise de dependências

Para cada task candidata, identifique:

- O que precisa estar pronto antes (pré-requisitos)
- O que ela desbloqueia (dependentes)
- Se pode ser paralelizada com outras tasks

### 3. Agrupamento e ordenação

- Agrupe tasks relacionadas em fases lógicas
- Ordene por dependência técnica real (grafo de dependências)
- Identifique o caminho crítico (sequência mais longa de tasks dependentes)
- Marque tasks paralelizáveis

### 4. Estimativa de complexidade

Use a escala:

| Complexidade | Significado | Referência aproximada |
|---|---|---|
| P | Pequena: lógica simples, pouca integração | Até meio dia de trabalho |
| M | Média: lógica moderada, alguma integração | 1 a 2 dias |
| G | Grande: lógica complexa, múltiplas integrações | 3 a 5 dias |
| GG | Muito grande: considerar quebrar em subtasks | Mais de 5 dias |

Se uma task for GG, quebre em subtasks menores.

---

## Formato de Saída

O plano de implementação deve seguir exatamente esta estrutura Markdown:

```markdown
## Plano de Implementação: [nome da feature]

**Fonte**: [FDD versão X | FDD + Épico | Épico apenas]
**Data**: [data de geração]
**Estimativa total**: [soma das estimativas em dias-dev]
**Caminho crítico**: [lista das tasks no caminho crítico]

---

### Visão geral das fases

| Fase | Descrição | Tasks | Estimativa |
|---|---|---|---|
| 1 | [nome da fase] | T01, T02, T03 | [X dias-dev] |
| 2 | [nome da fase] | T04, T05 | [X dias-dev] |

---

### Tasks detalhadas

#### Fase 1: [nome da fase]

##### T01: [título da task]

- **Complexidade**: [P/M/G]
- **Estimativa**: [X dias-dev]
- **Depende de**: [nenhuma | T0X, T0Y]
- **Desbloqueia**: [T0X, T0Y]
- **Paralelizável com**: [T0X | nenhuma]

**Descrição técnica**
[O que implementar, com referência à seção do FDD de onde veio]

**Abordagem sugerida**
[Como implementar: padrões, bibliotecas, estratégia]

**Contrato de API** *(obrigatório quando a task implementa endpoints HTTP)*

| | |
|---|---|
| **Método/Rota** | `VERB /caminho/:param` |
| **Autenticação** | pública / Bearer token (papel: X) |
| **Request body** | `{ campo: tipo (obrigatório), campo2: tipo (opcional) }` |
| **Query params** | `param` (tipo, default X, max Y) |
| **Response `2xx`** | `{ campo: tipo, ... }` |
| **Response `4xx`** | `status` → `{ shape }` — mensagem literal do FDD |
| **Headers resposta** | ex: `Cache-Control: no-store` |

**Critérios de aceite**
- [ ] [critério verificável 1]
- [ ] [critério verificável 2]
- [ ] [critério verificável 3]

**Observações**
[Riscos específicos, decisões em aberto, hipóteses]

---

[repetir para cada task]

---

### Checkpoints de validação

| Após fase | Validação | Como verificar |
|---|---|---|
| 1 | [o que deve estar funcionando] | [teste, comando, evidência] |
| 2 | [o que deve estar funcionando] | [teste, comando, evidência] |

---

### Riscos de implementação

| Risco | Probabilidade | Impacto | Mitigação | Task afetada |
|---|---|---|---|---|
| [risco 1] | [baixa/média/alta] | [impacto] | [ação] | [T0X] |

---

### Observações finais

[Notas sobre decisões em aberto, pontos que precisam de alinhamento, recomendações]
```

---

## Regras de Geração

1. **Cada task deve ser independentemente implementável e verificável.** Se não dá para testar uma task isoladamente, ela está mal definida ou precisa ser reagrupada.

2. **Não repita o FDD** nas descrições narrativas. Referencie seções em vez de copiar blocos de texto. **Exceção obrigatória:** contratos de API (shapes de request/response, mensagens de erro exatas, headers) devem ser copiados literalmente nos critérios de aceite — não como referência ao FDD, mas como especificação verificável por quem implementa.

3. **Priorize o caminho crítico.** As primeiras fases devem conter as tasks que desbloqueiam o maior número de dependentes.

4. **Observabilidade não é "fase final".** Instrumentação básica (logs, métricas de erro) deve estar presente desde a primeira fase. Uma task dedicada de observabilidade avançada (dashboards, alertas) pode ficar em fase posterior.

5. **Testes fazem parte da task, não são tasks separadas.** Cada task inclui nos critérios de aceite a cobertura de testes esperada. Não crie tasks do tipo "escrever testes para T01".

6. **Tasks de infra/setup vêm primeiro.** Migrations, configuração de ambiente, setup de dependências externas formam a base e devem estar na Fase 1.

7. **Use IDs curtos e consistentes.** T01, T02... para tasks. Se houver subtasks: T01a, T01b.

8. **Se o FDD tiver lacunas, sinalize.** Marque com "[PENDENTE: detalhe X não está no FDD]" e sugira o que precisa ser definido antes de implementar.

9. **Tasks que implementam endpoints devem ter contratos explícitos nos critérios de aceite.** Para toda task de controller ou rota, os critérios de aceite devem incluir obrigatoriamente:
   - Shape exato do request (cada campo com tipo e se é obrigatório)
   - Shape exata do response para cada status code relevante
   - Mensagens de erro literais do FDD para cada condição de erro
   - Headers de resposta obrigatórios
   Estes itens devem aparecer como critérios verificáveis (`- [ ]`), não como referências ao FDD.

10. **Se receber apenas o épico (sem FDD)**, gere um plano de alto nível com tasks macro e sinalize explicitamente: "Este plano é de alto nível. Recomenda-se criar um FDD para detalhar a implementação antes de iniciar."

---

## Pós-geração

Após gerar o plano, pergunte ao usuário:

1. "Quer que eu ajuste alguma estimativa, reordene tasks ou quebre alguma task grande?"


---