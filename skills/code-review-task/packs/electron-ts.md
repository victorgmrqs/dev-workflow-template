# Bug-hunt pack: electron-ts (Electron main/renderer + TypeScript)

| # | Padrão de bug | Onde olhar |
|---|---------------|------------|
| 1 | Promise sem `await`/rejeição não tratada em handler IPC ou ciclo de vida | main process, handlers IPC |
| 2 | Recurso nativo sem release (stream de áudio, handle de arquivo, child process) em erro/cancelamento | adapters nativos, cleanup |
| 3 | Race entre renderer e main: estado divergente após reply fora de ordem; listener duplicado | IPC, eventos |
| 4 | Dados do usuário/LLM renderizados sem escape; `openExternal`/href dinâmico sem validação | renderer |
| 5 | Query/persistência sem filtro de registro ativo (soft delete ignorado) | repositórios SQLite |
| 6 | `null`/`undefined` de API nativa ou externa desreferenciado sem guard | bordas nativas, STT/LLM |
| 7 | Config de segurança do BrowserWindow relaxada (nodeIntegration, contextIsolation, contentProtection) | criação de janelas |
| 8 | Estado inválido alcançável em máquina de estados (gravação/transcrição) | fluxos de captura |
| 9 | Dado sensível em log (transcrição, chave de API, caminho pessoal) | logging |
