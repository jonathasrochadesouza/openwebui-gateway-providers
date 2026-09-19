#!/usr/bin/env bash
# Adaptador: expõe o Gemini CLI (ACP nativo oficial `gemini --acp`) no formato que
# o gateway espera. Descarta flags kiro-específicas (ex.: "acp --agent-engine v2").
# Autenticação vive no CLI oficial do usuário (`gemini` → login Google).
set -euo pipefail
exec gemini --acp
