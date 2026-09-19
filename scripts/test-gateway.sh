#!/usr/bin/env bash
# Testa gateways: [provedor ...] (default: todos habilitados).
# Valida /health, /v1/models, chat sem stream e com stream por provedor.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/providers.sh

[ -f .env ] || { echo "ERRO: .env ausente"; exit 1; }
export $(grep '^KIRO_GATEWAY_API_KEY=' .env | xargs)

PROV="$*"
[ -n "$PROV" ] || PROV=$(enabled_providers)
[ -n "$PROV" ] || { echo "ERRO: nenhum provedor habilitado"; exit 1; }

overall=0
for p in $PROV; do
  PORT=$(provider_port "$p")
  BASE="http://127.0.0.1:$PORT"
  echo "===== $p ($BASE) ====="
  curl -sf -m 10 "$BASE/health" && echo || { echo "FALHA /health"; overall=1; continue; }

  IDS=$(curl -sf -m 20 "$BASE/v1/models" -H "Authorization: Bearer $KIRO_GATEWAY_API_KEY" \
        | python3 -c "import sys,json; [print(m['id']) for m in json.load(sys.stdin)['data']]" 2>/dev/null) \
    || { echo "FALHA /v1/models"; overall=1; continue; }
  echo "modelos: $(echo $IDS | wc -w | tr -d ' ') -> $IDS"

  MODEL=$(echo $IDS | awk '{print $1}')
  case $p in kiro) [ "$MODEL" = "auto" ] && MODEL=$(echo $IDS | awk '{print $2}');; esac

  RESP=$(curl -sf -m 180 "$BASE/v1/chat/completions" \
           -H "Authorization: Bearer $KIRO_GATEWAY_API_KEY" -H "Content-Type: application/json" \
           -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Responda somente: $p Gateway integrado com sucesso.\"}],\"stream\":false}" \
           | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message'].get('content',''))" 2>/dev/null) \
    || { echo "FALHA chat sem stream"; overall=1; RESP=""; }
  echo "resposta: ${RESP:0:120}"

  CH=$(curl -s -N -m 180 "$BASE/v1/chat/completions" \
        -H "Authorization: Bearer $KIRO_GATEWAY_API_KEY" -H "Content-Type: application/json" \
        -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Responda somente: $p Gateway integrado com sucesso.\"}],\"stream\":true}" \
        | grep -c '^data:') || CH=0
  [ "$CH" -gt 0 ] && echo "stream OK ($CH chunks)" || { echo "FALHA stream"; overall=1; }
done

[ "$overall" = 0 ] && echo "RESULTADO: OK" || echo "RESULTADO: FALHAS"
exit $overall
