#!/usr/bin/env bash
# Testa o Kiro Gateway: /health, /v1/models, chat sem stream e com stream.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] || { echo "ERRO: .env ausente"; exit 1; }
export $(grep '^KIRO_GATEWAY_API_KEY=' .env | xargs)
BASE="http://127.0.0.1:8000"
fail=0

echo "-- /health"
curl -sf -m 10 "$BASE/health" && echo || fail=1

echo "-- /v1/models"
IDS=$(curl -sf -m 20 "$BASE/v1/models" -H "Authorization: Bearer $KIRO_GATEWAY_API_KEY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(' '.join(m['id'] for m in d['data']))") || { echo "FALHA em /v1/models"; fail=1; IDS=""; }
echo "modelos: $(echo $IDS | wc -w | tr -d ' ') -> $IDS"

MODEL=$(echo $IDS | awk '{print $1}')
[ "$MODEL" = "auto" ] && MODEL=$(echo $IDS | awk '{print $2}')

echo "-- chat sem stream (modelo: $MODEL)"
RESP=$(curl -sf -m 150 "$BASE/v1/chat/completions" -H "Authorization: Bearer $KIRO_GATEWAY_API_KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Responda somente: Kiro Gateway integrado com sucesso.\"}],\"stream\":false}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message'].get('content',''))") || { echo "FALHA no chat"; fail=1; }
echo "resposta: ${RESP:0:120}"

echo "-- chat com stream"
CH=$(curl -s -N -m 150 "$BASE/v1/chat/completions" -H "Authorization: Bearer $KIRO_GATEWAY_API_KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Responda somente: Kiro Gateway integrado com sucesso.\"}],\"stream\":true}" \
  | grep -c '^data:') || CH=0
[ "$CH" -gt 0 ] && echo "stream OK ($CH chunks)" || { echo "FALHA no stream"; fail=1; }

[ "$fail" = 0 ] && echo "RESULTADO: OK" || echo "RESULTADO: FALHAS"
exit $fail
