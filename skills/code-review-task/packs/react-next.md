# Bug-hunt pack: react-next (React / Next.js App Router)

| # | Padrão de bug | Onde olhar |
|---|---------------|------------|
| 1 | Promise sem `await`/sem tratamento de erro em handler ou efeito | actions, handlers, `useEffect` |
| 2 | Race/stale state: efeito sem cleanup; polling sem cancelamento ao desmontar/navegar; resposta antiga sobrescrevendo nova | polling, fetches concorrentes |
| 3 | Estado de erro/vazio não renderizado (só happy path); loading infinito em falha | telas alteradas |
| 4 | Conteúdo de usuário/LLM sem escape em contexto perigoso (`dangerouslySetInnerHTML`, href dinâmico) | componentes de exibição |
| 5 | Dependências de hook erradas (closure velho) operando sobre dado desatualizado | `useEffect`/`useCallback`/`useMemo` |
| 6 | `undefined`/`null` de resposta da API desreferenciado sem guard; `!` sem garantia | cliente da API, parsing |
| 7 | Lógica sensível confiada só ao client (validação/autorização que o backend precisa repetir) | forms, rotas protegidas |
| 8 | Off-by-one/limites em paginação, truncamento de texto, índices de lista | listagens |
| 9 | Vazamento de config: segredo em variável pública (`NEXT_PUBLIC_*`) ou no bundle | env, imports client-side |
