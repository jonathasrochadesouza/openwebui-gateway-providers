#!/usr/bin/env bash
# Para LiteLLM/Open WebUI (Docker) e o Kiro Gateway deste projeto.
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose stop

if [ -f kiro-gateway.pid ]; then
  PID=$(cat kiro-gateway.pid)
  if kill -0 "$PID" 2>/dev/null; then
    kill "$PID" && echo "Kiro Gateway (pid $PID) encerrado."
  else
    echo "pidfile obsoleto; removido."
  fi
  rm -f kiro-gateway.pid
else
  echo "Sem pidfile do Kiro Gateway. (Se estiver em outro terminal, encerre manualmente.)"
fi
