#!/usr/bin/env bash
# Biblioteca compartilhada: detecção de provedores ACP e mapeamento porta/instância.
# Portável para bash 3.2 (macOS). Fonte única de verdade p/ setup/start/stop/status/test/sync.

PROVIDERS_ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env"
PROVIDERS_KNOWN="kiro kilo claude opencode antigravity codex"

provider_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }

provider_port() {
  case $1 in
    kiro) echo 8000 ;;
    kilo) echo 8001 ;;
    claude) echo 8002 ;;
    opencode) echo 8003 ;;
    antigravity) echo 8004 ;;
    codex) echo 8005 ;;
  esac
}

provider_bin() {
  case $1 in
    kiro) echo kiro-cli ;;
    kilo) echo kilo ;;
    claude) echo claude ;;
    opencode) echo opencode ;;
    antigravity) echo agy ;;
    codex) echo codex ;;
  esac
}

# Lê PROVIDERS do .env raiz; vazio/ausente = auto-detectar pelo que está instalado.
enabled_providers() {
  local cfg="" p out=""
  if [ -f "$PROVIDERS_ENV_FILE" ]; then
    cfg=$(grep '^PROVIDERS=' "$PROVIDERS_ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d ' "' || true)
  fi
  if [ -n "$cfg" ]; then
    local IFS=','
    for p in $cfg; do
      p=$(printf '%s' "$p" | tr -d ' ')
      for k in $PROVIDERS_KNOWN; do [ "$p" = "$k" ] && out="$out $p"; done
    done
  else
    for k in $PROVIDERS_KNOWN; do
      command -v "$(provider_bin "$k")" >/dev/null 2>&1 && out="$out $k"
    done
  fi
  echo $out
}

# Caminho do binário/wrapper que o gateway vai spawnar para cada provedor.
provider_cli_path() {
  local root p=$1
  root=$(provider_root)
  case $p in
    kiro) echo kiro-cli ;;
    kilo) echo "$root/scripts/adapters/kilo-acp.sh" ;;
    claude) echo "$root/scripts/adapters/claude-acp.sh" ;;
    opencode) echo "$root/scripts/adapters/opencode-acp.sh" ;;
    antigravity) echo "$root/scripts/adapters/antigravity-acp.sh" ;;
    codex) echo "$root/scripts/adapters/codex-acp.sh" ;;
  esac
}

# Erro claro se o requisito base do provedor não existir (R5 da issue #4).
provider_missing_error() {
  case $1 in
    kiro) echo "kiro-cli não encontrado — instale via https://kiro.dev e rode 'kiro-cli login'." ;;
    kilo) echo "kilo não encontrado — instale (kilo.ai) e autentique com 'kilo auth'." ;;
    claude) echo "claude (Claude Code) não encontrado — instale e autentique com 'claude'." ;;
    opencode) echo "opencode não encontrado — instale (npm i -g opencode-ai) e configure com 'opencode auth'." ;;
    antigravity) echo "agy (Antigravity CLI) não encontrado — instale via https://antigravity.google/cli e faça login com 'agy'." ;;
    codex) echo "codex não encontrado — instale (npm i -g @openai/codex) e autentique com 'codex'." ;;
  esac
}
