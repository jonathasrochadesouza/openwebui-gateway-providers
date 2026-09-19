# Cenário de teste — Issue #2 (Kilo Code CLI via ACP)

**Pré-requisito:** `kilo` instalado e autenticado (`kilo auth`). O gateway usa a Kilo CLI 1.0 via `scripts/adapters/kilo-acp.sh` (npx, versão fixada).

**Teste (direto):**
```bash
./scripts/start.sh                      # detecta kiro+kilo+claude, sobe um gateway por CLI
curl -s http://127.0.0.1:8001/health    # esperado: {"status":"ok",...}
bash scripts/test-gateway.sh kilo       # health + /v1/models + chat + stream
```

**Esperado:** gateway em `127.0.0.1:8001` spawnando `kilo acp` (npx `@kilocode/cli@7.7.5`) como subprocesso; `kilo/auto`, `kilo/claude-opus-4-8`, `kilo/claude-sonnet-4-6` em `/v1/models`; resposta do chat = "kilo Gateway integrado com sucesso."; stream com chunks SSE + `[DONE]`; `kilo/auto` acessível pelo LiteLLM (rota `kilo/*` gerada em `litellm_config.yaml`) e selecionável no Open WebUI.
