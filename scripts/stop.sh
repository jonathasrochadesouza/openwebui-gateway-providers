#!/usr/bin/env bash
# Para o Compose e todas as instâncias de gateway deste projeto.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/providers.sh

docker compose stop

stopped=""
for f in kiro-gateway-*.pid; do
  [ -f "$f" ] || continue
  PID=$(cat "$f")
  if kill -0 "$PID" 2>/dev/null; then
    kill "$PID" && stopped="$stopped $f (pid $PID)"
  fi
  rm -f "$f"
done
# Compat: pidfile antigo
if [ -f kiro-gateway.pid ]; then
  PID=$(cat kiro-gateway.pid); kill -0 "$PID" 2>/dev/null && kill "$PID" && stopped="$stopped kiro-gateway.pid (pid $PID)"
  rm -f kiro-gateway.pid
fi
[ -n "$stopped" ] && echo "Gateways encerrados:$stopped" || echo "Nenhuma instância de gateway em execução."
