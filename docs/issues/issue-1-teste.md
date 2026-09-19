# Cenário de teste — Issue #1 (auto-config Open WebUI → LiteLLM)

**Setup (uma vez):**
```bash
git clone https://github.com/jonathasrochadesouza/openwebui-gateway-providers.git && cd openwebui-gateway-providers
./scripts/setup.sh && ./scripts/start.sh
```

**Teste (direto):**
```bash
# 1. Conexão já configurada sem tocar na UI (env do container)
docker exec open-webui env | grep OPENAI_API_BASE_URL
# esperado: http://litellm:4000/v1

# 2. Modelos sincronizados automaticamente (sem cadastro manual)
grep -c model_name litellm_config.yaml
curl -s http://127.0.0.1:4000/v1/models -H "Authorization: Bearer $(grep '^LITELLM_MASTER_KEY=' .env | cut -d= -f2)" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['data']), 'modelos')"

# 3. Chat end-to-end
curl -s http://127.0.0.1:4000/v1/chat/completions -H "Authorization: Bearer $(grep '^LITELLM_MASTER_KEY=' .env | cut -d= -f2)" -H "Content-Type: application/json" -d '{"model":"kiro/claude-haiku-4-5","messages":[{"role":"user","content":"Responda somente: auto-config OK."}],"stream":false}'
```

**Esperado:** container com `OPENAI_API_BASE_URL=http://litellm:4000/v1` + `ENABLE_PERSISTENT_CONFIG=False`; LiteLLM e `litellm_config.yaml` com todos os modelos detectados nos gateways; chat responde "auto-config OK."; no Open WebUI os modelos aparecem no seletor sem nenhuma configuração manual. Conta free → catálogo do plano (com fallback documentado para catálogo completo quando o plano não é detectável, ex.: login Google/IdP).
