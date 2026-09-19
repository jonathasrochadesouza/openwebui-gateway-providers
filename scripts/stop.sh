#!/usr/bin/env bash
# Para o Compose e todas as instâncias de gateway deste projeto.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/providers.sh

docker compose stop

stopped=""
for p in kiro kilo claude opencode; do
  # Encerra pelo processo que ESCUTA na porta (o pidfile pode apontar ao wrapper morto).
  PORT=$(provider_port "$p")
  PIDS=$(lsof -ti :$PORT 2>/dev/null || true)
  if [ -n "$PIDS" ]; then
    echo "$PIDS" | xargs kill 2>/dev/null && stopped="$stopped $p(:$PORT)"
  fi
  rm -f "kiro-gateway-$p.pid"
done
# Compat: pidfile antigo
if [ -f kiro-gateway.pid ]; then
  PID=$(cat kiro-gateway.pid); kill -0 "$PID" 2>/dev/null && kill "$PID" && stopped="$stopped kiro-gateway.pid (pid $PID)"
  rm -f kiro-gateway.pid
fi
[ -n "$stopped" ] && echo "Gateways encerrados:$stopped" || echo "Nenhuma instância de gateway em execução."
