#!/usr/bin/env bash
# Status dos serviços: Docker, Kiro Gateway, portas.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Docker =="
docker compose ps

echo; echo "== Kiro Gateway =="
if curl -s -m 5 -o /dev/null http://127.0.0.1:8000/health; then
  echo "Kiro Gateway 127.0.0.1:8000: $(curl -s -m 5 http://127.0.0.1:8000/health)"
else
  echo "Kiro Gateway: inacessível"
fi

echo; echo "== HTTP local =="
curl -s -m 5 -o /dev/null -w "Open WebUI  http://127.0.0.1:3000  -> HTTP %{http_code}\n" http://127.0.0.1:3000 || true
curl -s -m 5 -o /dev/null -w "LiteLLM     http://127.0.0.1:4000  -> HTTP %{http_code}\n" http://127.0.0.1:4000/health/liveliness || true

echo; echo "== Bind de portas (deve ser 127.0.0.1) =="
lsof -nP -iTCP:3000 -iTCP:4000 -iTCP:8000 -sTCP:LISTEN | awk 'NR==1 || /LISTEN/' || true
