# Cenário de teste — Issue #3 (Claude Code via adaptador ACP canônico)

**Pré-requisitos:** Node 20+; `claude` (Claude Code) instalado **e autenticado** (`claude` → `/login`). Sem login, o gateway responde `Authentication required` (comportamento correto).

**Teste (direto):**
```bash
./scripts/start.sh                      # claude = terceira instância em :8002
curl -s http://127.0.0.1:8002/health    # esperado: {"status":"ok",...}
bash scripts/test-gateway.sh claude     # health + /v1/models + chat + stream
```

**Esperado:** gateway em `127.0.0.1:8002` spawnando `scripts/adapters/claude-acp.sh` (npx `@agentclientprotocol/claude-agent-acp@0.31.4` — Apache-2.0, SDK oficial); `/v1/models` com `claude/default`, `claude/sonnet[1m]`, `claude/opus[1m]`, `claude/haiku`; com `claude` autenticado, chat responde e stream chega com chunks + `[DONE]`; rota `claude/*` no LiteLLM e modelo `claude/*` selecionável no Open WebUI. Nenhuma API key envolvida (usa a assinatura do Claude Code).
