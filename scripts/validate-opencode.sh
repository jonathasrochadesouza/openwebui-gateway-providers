#!/usr/bin/env bash
# Valida com 1 chat curto real cada id do catálogo do OpenCode (regra da issue #5:
# nenhuma rota exposta pode falhar). Cache em logs/opencode-validated.txt (ids OK).
# Revalidar: REVALIDATE=1 ./scripts/validate-opencode.sh
set -euo pipefail
cd "$(dirname "$0")/.."

CACHE=logs/opencode-validated.txt
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

if [ -s "$CACHE" ] && [ "${REVALIDATE:-0}" != "1" ]; then
  echo "cache válido: $(wc -l < "$CACHE" | tr -d ' ') ids (REVALIDATE=1 para forçar)"
  exit 0
fi

export $(grep '^KIRO_GATEWAY_API_KEY=' .env | xargs)

# ids = catálogo ACP do gateway (:8003) + catálogo completo do CLI (providers do usuário)
IDS_ACP=$(curl -sf -m 15 http://127.0.0.1:8003/v1/models \
  -H "Authorization: Bearer $KIRO_GATEWAY_API_KEY" \
  | python3 -c "import sys,json; [print(m['id']) for m in json.load(sys.stdin)['data']]" 2>/dev/null || true)
IDS_CLI=$(opencode models 2>/dev/null || true)

: > "$TMP"
total=0; ok=0
for id in $(echo "$IDS_ACP $IDS_CLI" | tr ' ' '\n' | sort -u); do
  [ -n "$id" ] || continue
  total=$((total+1))
  R=$(curl -s -m 90 "http://127.0.0.1:8003/v1/chat/completions" \
      -H "Authorization: Bearer $KIRO_GATEWAY_API_KEY" -H "Content-Type: application/json" \
      -d "{\"model\":\"$id\",\"messages\":[{\"role\":\"user\",\"content\":\"Responda somente: ok\"}],\"stream\":false}" \
      | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    c=(d.get('choices') or [{}])[0].get('message',{}).get('content','')
    print('OK' if c.strip() else 'EMPTY')
except Exception:
    print('FAIL')" 2>/dev/null || echo FAIL)
  if [ "$R" = "OK" ]; then
    echo "$id" >> "$TMP"
    ok=$((ok+1))
  else
    echo "skip: $id ($R)" >&2
  fi
done

mv "$TMP" "$CACHE"
echo "validação opencode: $ok/$total ids funcionais (cache: $CACHE)"
