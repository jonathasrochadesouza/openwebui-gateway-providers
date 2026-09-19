#!/usr/bin/env bash
# Sobe um gateway por provedor habilitado (portas fixas em loopback), depois o Compose.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/providers.sh
ROOT=$(provider_root)

[ -f .env ] || { echo "ERRO: .env ausente — rode ./scripts/setup.sh"; exit 1; }
[ -d kiro-gateway ] || { echo "ERRO: kiro-gateway/ ausente — rode ./scripts/setup.sh"; exit 1; }

mkdir -p logs
PROV=$(enabled_providers)
[ -n "$PROV" ] || { echo "ERRO: nenhum provedor detectado (kiro-cli/kilo/claude)."; exit 1; }
echo "Provedores habilitados:$PROV"

for p in $PROV; do
  CLI=$(provider_cli_path "$p")
  PORT=$(provider_port "$p")
  PIDFILE="kiro-gateway-$p.pid"

  if ! command -v "$(provider_bin "$p")" >/dev/null 2>&1; then
    echo "AVISO: provedor '$p' habilitado mas $(provider_missing_error "$p") Pulando."
    continue
  fi
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "$p: gateway já em execução (pid $(cat "$PIDFILE"), porta $PORT)."
    continue
  fi

  # Env de processo tem precedência sobre o .env do gateway (load_dotenv não sobrescreve).
  EXTRA_ENV="SERVER_PORT=$PORT KIRO_CLI_PATH=$CLI KIRO_ACP_ENGINE="
  [ "$p" != "kiro" ] && EXTRA_ENV="$EXTRA_ENV MODEL_VALIDATION=off"
  # Kilo: alias 'free' -> modelo free do Kilo Gateway (kilo/kilo-auto/free), sem créditos (issue #5).
  [ "$p" = "kilo" ] && EXTRA_ENV="$EXTRA_ENV MODEL_ALIASES=free=kilo/kilo-auto/free"
  (
    cd kiro-gateway
    env $EXTRA_ENV nohup uv run main.py > "$ROOT/logs/gateway-$p.log" 2>&1 &
    echo $! > "$ROOT/$PIDFILE"
  )
  echo "$p: gateway iniciando em 127.0.0.1:$PORT (pid $(cat "$PIDFILE"))"
done

# Aguarda readiness dos gateways (limitado) e segue com o Compose.
for p in $PROV; do
  PIDFILE="kiro-gateway-$p.pid"
  [ -f "$PIDFILE" ] || continue
  kill -0 "$(cat "$PIDFILE")" 2>/dev/null || continue
  PORT=$(provider_port "$p")
  ok=""
  for _ in $(seq 1 45); do
    curl -sf -m 3 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 && { echo "$p: pronto em :$PORT"; ok=1; break; }
    sleep 2
  done
  [ "${ok:-}" = 1 ] || echo "AVISO: gateway '$p' não respondeu em :$PORT (veja logs/gateway-$p.log)."
  unset ok
done

# Gera litellm_config.yaml a partir dos gateways ativos e reinicia o LiteLLM.
bash scripts/sync-providers.sh || echo "AVISO: sync de modelos falhou — LiteLLM usa o config atual."

docker compose up -d
echo "Pronto: Open WebUI http://localhost:3000 | LiteLLM http://127.0.0.1:4000"
