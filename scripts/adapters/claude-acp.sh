#!/usr/bin/env bash
# Adaptador: expõe o Claude Code (SDK oficial, via adaptador canônico da org
# Agent Client Protocol, Apache-2.0) como agente ACP em stdio. Descarta flags
# kiro-específicas enviadas pelo gateway. Autenticação vive no `claude` do usuário.
set -euo pipefail
CLAUDE_ACP_VERSION="0.31.4"
exec npx -y "@agentclientprotocol/claude-agent-acp@${CLAUDE_ACP_VERSION}"
