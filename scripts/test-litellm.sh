#!/usr/bin/env bash
# Testa o LiteLLM Proxy: /v1/models, chat sem stream e com stream.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] || { echo "ERRO: .env ausente"; exit 1; }
export $(grep '^LITELLM_MASTER_KEY=' .env | xargs)
BASE="http://127.0.0.1:4000"
fail=0

echo "-- /v1/models"
IDS=$(curl -sf -m 20 "$BASE/v1/models" -H "Authorization: Bearer $LITELLM_MASTER_KEY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(' '.join(m['id'] for m in d['data']))") || { echo "FALHA em /v1/models"; fail=1; IDS=""; }
echo "modelos: $IDS"

MODEL=$(echo $IDS | awk '{print $1}')
[ -z "$MODEL" ] && { echo "sem modelos"; exit 1; }

echo "-- chat sem stream (modelo: $MODEL)"
RESP=$(curl -sf -m 150 "$BASE/v1/chat/completions" -H "Authorization: Bearer $LITELLM_MASTER_KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Responda somente: LiteLLM integrado com sucesso.\"}],\"stream\":false}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message'].get('content',''))") || { echo "FALHA no chat"; fail=1; }
echo "resposta: ${RESP:0:120}"

echo "-- chat com stream"
CH=$(curl -s -N -m 150 "$BASE/v1/chat/completions" -H "Authorization: Bearer $LITELLM_MASTER_KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Responda somente: LiteLLM integrado com sucesso.\"}],\"stream\":true}" \
  | grep -c '^data:') || CH=0
[ "$CH" -gt 0 ] && echo "stream OK ($CH chunks)" || { echo "FALHA no stream"; fail=1; }

echo "-- conectividade open-webui -> litellm (Docker interno)"
docker exec open-webui sh -c 'exit 0' 2>/dev/null && \
docker exec open-webui sh -c 'command -v curl >/dev/null && curl -s -m 10 -o /dev/null -w "http://litellm:4000 HTTP %{http_code}\n" http://litellm:4000/health/liveliness || echo "curl ausente no container"' || \
echo "container open-webui não está em execução"

[ "$fail" = 0 ] && echo "RESULTADO: OK" || echo "RESULTADO: FALHAS"
exit $fail
