# Bug-hunt pack: generic (fallback para qualquer stack)

| # | Padrão de bug | Onde olhar |
|---|---------------|------------|
| 1 | Operação assíncrona sem await/tratamento de erro; erro engolido silenciosamente | handlers, integrações |
| 2 | Validação de entrada ausente além do parser/framework (limites, enums, ownership) | bordas do sistema |
| 3 | Acesso a dados sem filtro de dono/ativo — vazamento entre usuários | queries, repositórios |
| 4 | Race condition: recurso compartilhado sem sincronização; resposta antiga sobrescrevendo nova | concorrência |
| 5 | Null/None desreferenciado sem guard em caminho não exercitado | bordas de dados externos |
| 6 | Injeção: interpolação de entrada do usuário em SQL/shell/HTML | queries, comandos, templates |
| 7 | Estado inválido alcançável (transições de status, dado imutável mutado) | máquinas de estado |
| 8 | Off-by-one e limites (paginação, truncamento, índices) | listagens, loops |
| 9 | Segredo ou dado sensível em log, erro ou resposta | logging, handlers de erro |
