#!/usr/bin/env bash
# Adaptador: expõe o Codex CLI (OpenAI) via adaptador canônico da Zed Industries
# (@zed-industries/codex-acp, versão fixada). Descarta flags kiro-específicas do
# gateway. Autenticação vive no CLI oficial `codex` (login ChatGPT do usuário).
#
# -c model: o adaptador não implementa session/set_model, então o modelo é o
# default da sessão. 'gpt-5.6-sol' (config local) não é suportado para contas
# ChatGPT — override para 'gpt-5.5' (validado com chat real, issue #9).
set -euo pipefail
CODEX_ACP_VERSION="0.16.0"
exec npx -y "@zed-industries/codex-acp@${CODEX_ACP_VERSION}" -c 'model="gpt-5.5"'
