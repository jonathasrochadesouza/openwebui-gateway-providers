#!/usr/bin/env bash
# Sincroniza litellm_config.yaml com os modelos reais de cada gateway habilitado.
# Segurança: chaves só via os.environ/, nunca literal. Idempotente.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/providers.sh

[ -f .env ] || { echo "ERRO: .env ausente"; exit 1; }
export $(grep -E '^(LITELLM_MASTER_KEY|KIRO_GATEWAY_API_KEY)=' .env | xargs)

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
echo "# Gerado por scripts/sync-providers.sh — não versionar segredos." > "$TMP"
echo "model_list:" >> "$TMP"

written=0
for p in $(enabled_providers); do
  PORT=$(provider_port "$p")
  PIDFILE="kiro-gateway-$p.pid"
  # gateway precisa estar em execução para expor o catálogo ao vivo
  [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null || continue
  IDS=$(curl -sf -m 15 "http://127.0.0.1:$PORT/v1/models" \
        -H "Authorization: Bearer $KIRO_GATEWAY_API_KEY" \
     | python3 -c "import sys,json; [print(m['id']) for m in json.load(sys.stdin)['data']]" 2>/dev/null || true)
  [ -n "$IDS" ] || { echo "AVISO: sem modelos do '$p' (gateway :$PORT off?)"; continue; }
  for id in $IDS; do
    cat >> "$TMP" <<EOF
  - model_name: "$p/$id"
    litellm_params:
      model: "openai/$id"
      api_base: "http://host.docker.internal:$PORT/v1"
      api_key: "os.environ/KIRO_GATEWAY_API_KEY"
EOF
    written=$((written+1))
  done
done

if [ "$written" -eq 0 ]; then
  echo "AVISO: nenhum modelo coletado — litellm_config.yaml mantido."
  exit 1
fi

cat >> "$TMP" <<'EOF'
general_settings:
  master_key: "os.environ/LITELLM_MASTER_KEY"

litellm_settings:
  set_verbose: false
EOF

mv "$TMP" litellm_config.yaml
echo "litellm_config.yaml regenerado ($written modelos)."
docker compose restart litellm >/dev/null 2>&1 && echo "LiteLLM reiniciado." || echo "AVISO: LiteLLM não reiniciado (compose fora do ar?)."
