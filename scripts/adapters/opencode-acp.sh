#!/usr/bin/env bash
# Adaptador: expõe o OpenCode CLI (ACP nativo `opencode acp`) no formato que o
# gateway espera. Descarta flags kiro-específicas (ex.: "acp --agent-engine v2").
# Usa o binário oficial do OpenCode; autenticação vive no `opencode auth` do usuário.
set -euo pipefail
exec opencode acp
