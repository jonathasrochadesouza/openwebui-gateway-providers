#!/usr/bin/env bash
# Adaptador: expõe o Kilo Code CLI (ACP nativo da Kilo CLI 1.0) no formato que o
# gateway espera. Descarta flags kiro-específicas (ex.: "acp --agent-engine v2").
# O binário oficial do Kilo é chamado via npx com versão fixada (sem instalar global).
set -euo pipefail
KILO_VERSION="7.7.5"
exec npx -y "@kilocode/cli@${KILO_VERSION}" acp
