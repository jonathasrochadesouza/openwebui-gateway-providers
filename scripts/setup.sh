#!/usr/bin/env bash
# Prepara o ambiente a partir de um clone novo: segredos, gateway e dependências.
set -euo pipefail
cd "$(dirname "$0")/.."

ok() { command -v "$1" >/dev/null 2>&1; }

missing=""
for c in docker curl openssl python3 git uv; do
  ok "$c" || missing="$missing $c"
done
if [ -n "$missing" ]; then
  echo "ERRO: dependências ausentes:$missing"
  echo "Instale antes de continuar (Docker Desktop em execução, uv via https://docs.astral.sh/uv/)."
  exit 1
fi
docker info >/dev/null 2>&1 || { echo "ERRO: Docker não está em execução."; exit 1; }

# 1. Segredos locais (.env nunca versionado)
if [ ! -f .env ]; then
  umask 177
  printf 'WEBUI_SECRET_KEY=%s\nLITELLM_MASTER_KEY=%s\nKIRO_GATEWAY_API_KEY=%s\n' \
    "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > .env
  chmod 600 .env
  echo ".env criado com segredos fortes (permissão 600)."
else
  echo ".env já existe — segredos preservados."
fi

# 2. Kiro Gateway comunitário (tag fixada, funciona via binário oficial kiro-cli)
if [ ! -d kiro-gateway ]; then
  echo "Clonando kiro-gateway v2.4.1..."
  git clone --branch v2.4.1 --depth 1 \
    https://github.com/ankitcharolia/kiro-gateway.git kiro-gateway
else
  echo "kiro-gateway já presente — preservado."
fi

# 3. .env do gateway (apenas loopback)
if [ ! -f kiro-gateway/.env ]; then
  KEY=$(grep '^KIRO_GATEWAY_API_KEY=' .env | cut -d= -f2-)
  printf 'KIRO_GATEWAY_API_KEY=%s\nKIRO_CLI_PATH=kiro-cli\nSERVER_HOST=127.0.0.1\nSERVER_PORT=8000\nACP_TRUST_TOOLS=true\n' \
    "$KEY" > kiro-gateway/.env
  chmod 600 kiro-gateway/.env
  echo "kiro-gateway/.env gerado (bind 127.0.0.1:8000)."
else
  echo "kiro-gateway/.env já existe — preservado."
fi

# 4. Dependências do gateway em venv isolado
(cd kiro-gateway && uv sync >/dev/null) && echo "Dependências do gateway instaladas (.venv)."

echo
echo "Ambiente pronto."
echo "Se ainda não autenticou: rode 'kiro-cli login' e conclua no browser."
echo "Depois: ./scripts/start.sh e abra http://localhost:3000"
