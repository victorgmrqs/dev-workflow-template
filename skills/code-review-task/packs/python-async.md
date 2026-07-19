# Bug-hunt pack: python-async (FastAPI / SQLAlchemy async)

| # | Padrão de bug | Onde olhar |
|---|---------------|------------|
| 1 | Coroutine sem `await`; chamada bloqueante (I/O síncrono, render pesado) dentro de rota async | routers, use cases |
| 2 | Exceção engolida (`except` largo/só log) que deveria virar erro do envelope global | use cases, adapters |
| 3 | Validação de negócio ausente além do Pydantic (limites, enums, ownership) | bordas das rotas |
| 4 | Query sem filtro de dono/ativo — vazamento entre usuários | repositórios, queries novas |
| 5 | Race condition: sessão de DB compartilhada entre tasks async; commit fora de transação | repositórios, use cases |
| 6 | `None`/`Optional` desreferenciado sem guard em caminho não exercitado | bordas de dados externos (APIs, LLM) |
| 7 | SQL bruto com interpolação (`text(f"...")`) em vez de bind params | repositórios, migrations |
| 8 | Estado inválido alcançável (dado imutável mutado pós-gravação; transições de status) | máquinas de estado |
| 9 | Off-by-one e limites (paginação, truncamento de prompt, teto de custo) | listagens, integrações de IA |
