#!/usr/bin/env bash
cd /Users/jonathasrochadesouza/Developer/repositories/openwebui-gateway-providers
export $(grep '^KIRO_GATEWAY_API_KEY=' .env | xargs)
OUT=/var/folders/hp/rt2mt8295mn4tb261xyy01jr0000gn/T/opencode/agy-validation.txt
: > "$OUT"
while read -r m; do
  R=$(curl -s -m 120 http://127.0.0.1:8004/v1/chat/completions \
      -H "Authorization: Bearer $KIRO_GATEWAY_API_KEY" -H "Content-Type: application/json" \
      -d "{\"model\":\"$m\",\"messages\":[{\"role\":\"user\",\"content\":\"Responda somente: ok\"}],\"stream\":false}" \
      | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    c=(d.get('choices') or [{}])[0].get('message',{}).get('content','')
    print('OK' if c.strip() else 'EMPTY')
except Exception:
    print('FAIL')" 2>/dev/null)
  echo "$m $R" >> "$OUT"
done < /var/folders/hp/rt2mt8295mn4tb261xyy01jr0000gn/T/opencode/agy-models.txt
echo DONE >> "$OUT"
