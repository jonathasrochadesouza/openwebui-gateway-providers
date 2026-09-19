#!/usr/bin/env bash
# Adaptador: expõe o Antigravity CLI oficial (`agy`, google-antigravity/antigravity-cli)
# via adaptador comunitário agy-acp (Apache-2.0, versão fixada), que spawn o `agy`
# oficial e traduz ACP <-> agy. Autenticação é a do próprio `agy` do usuário
# (Google Sign-In / keyring) — sem leitura de tokens. Descarta flags kiro-específicas.
set -euo pipefail
AGY_ACP_VERSION="0.5.2"
exec npx -y "agy-acp@${AGY_ACP_VERSION}"
