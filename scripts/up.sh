#!/usr/bin/env bash
# One-shot: sobe TODO o stack de uma vez, do zero ou em execução existente.
# Fluxo: valida pré-requisitos → setup (se necessário) → gateways por provedor
#        → sync de modelos → Compose (Open WebUI + LiteLLM) → status final.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== 1/5 Pré-requisitos ==="
command -v docker >/dev/null || { echo "ERRO: Docker ausente"; exit 1; }
docker info >/dev/null 2>&1 || { echo "ERRO: Docker Desktop não está em execução."; exit 1; }
command -v uv >/dev/null || { echo "ERRO: uv ausente (https://docs.astral.sh/uv/)"; exit 1; }

echo "=== 2/5 Setup (idempotente) ==="
if [ ! -f .env ] || [ ! -d kiro-gateway ]; then
  bash scripts/setup.sh
else
  echo "Ambiente já configurado — preservando segredos (.env) e clone."
  chmod +x scripts/adapters/*.sh 2>/dev/null || true
fi

echo "=== 3/5 Gateways por provedor + Compose ==="
bash scripts/start.sh

echo "=== 4/5 Status final ==="
bash scripts/status.sh

echo "=== 5/5 Como usar ==="
cat <<'EOF'
Open WebUI:      http://localhost:3000  (crie o admin no primeiro acesso)
Modelos:         kiro/…, kilo/…, claude/… (conforme CLIs instalados)
Parar tudo:      ./scripts/stop.sh && docker compose down
Testes rápidos:  ./scripts/test-gateway.sh  |  ./scripts/test-litellm.sh
EOF
