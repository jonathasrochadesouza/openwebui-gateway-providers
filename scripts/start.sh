#!/usr/bin/env bash
# Sobe Kiro Gateway (host) + Open WebUI e LiteLLM (Docker).
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then echo "ERRO: .env ausente (copie .env.example e preencha)."; exit 1; fi

# Kiro Gateway em 127.0.0.1:8000
if [ -f kiro-gateway.pid ] && kill -0 "$(cat kiro-gateway.pid)" 2>/dev/null; then
  echo "Kiro Gateway já em execução (pid $(cat kiro-gateway.pid))."
else
  (cd kiro-gateway && nohup uv run main.py > ../logs/kiro-gateway.log 2>&1 & echo $! > ../kiro-gateway.pid)
  echo "Kiro Gateway iniciado (pid $(cat kiro-gateway.pid)) em 127.0.0.1:8000."
fi

docker compose up -d
echo "Pronto: Open WebUI em http://localhost:3000 | LiteLLM em http://127.0.0.1:4000"
