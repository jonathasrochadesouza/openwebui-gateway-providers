#!/usr/bin/env bash
# Status: Compose + uma linha por gateway de provedor + conferência de binds.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/providers.sh

echo "== Docker =="
docker compose ps

echo; echo "== Gateways por provedor =="
PROV=$(enabled_providers)
[ -n "$PROV" ] || echo "(nenhum provedor habilitado/detectado)"
for p in $PROV; do
  PORT=$(provider_port "$p")
  H=$(curl -sf -m 3 "http://127.0.0.1:$PORT/health" 2>/dev/null || true)
  [ -n "$H" ] && echo "$p  127.0.0.1:$PORT  $H" || echo "$p  127.0.0.1:$PORT  inacessível (logs/gateway-$p.log)"
done

echo; echo "== HTTP local =="
curl -s -m 5 -o /dev/null -w "Open WebUI  http://127.0.0.1:3000  -> HTTP %{http_code}\n" http://127.0.0.1:3000 || true
curl -s -m 5 -o /dev/null -w "LiteLLM     http://127.0.0.1:4000  -> HTTP %{http_code}\n" http://127.0.0.1:4000/health/liveliness || true

echo; echo "== Bind de portas (deve ser 127.0.0.1) =="
lsof -nP -iTCP:3000 -iTCP:4000 -iTCP:8000 -iTCP:8001 -iTCP:8002 -sTCP:LISTEN | awk 'NR==1 || /LISTEN/' || true
