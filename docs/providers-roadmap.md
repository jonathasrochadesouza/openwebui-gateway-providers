# Roadmap de provedores (baseado no ecossistema Agent Client Protocol)

Análise dos provedores **interessantes** para este lab, com base no padrão ACP
([agentclientprotocol.com](https://agentclientprotocol.com) — o "LSP de agentes de IA")
e no que já implementamos (#2 Kilo, #3 Claude, #6 OpenCode, #7 catálogo completo, #8 Gemini).

## Princípio do projeto
Só entramos via **binário/CLI oficial** (nativo ACP ou adaptador canônico da org
Agent Client Protocol/Zed) — nunca extração de tokens, APIs privadas ou pooling de contas.
Cada provedor = 1 gateway em `127.0.0.1:<porta>` + rota `<prefixo>/<modelo>` no LiteLLM,
exposta só depois de **1 chat real validado por id** (regra das issues #5/#7).

## Tier 1 — recomendados (próximos passos)

| Provedor | ACP | Porta | Autenticação | Por quê |
|---|---|---|---|---|
| **Antigravity CLI** (Google) | via adaptador `agy-acp` (Apache-2.0; `agy` interativo não tem ACP) | 8004 | conta Google (`agy` login, keyring) | **Concluída (#8)**: 14/14 modelos validados (Gemini 3.x, Claude, GPT-OSS); substitui o Gemini CLI, descontinuado pelo Google |
| **Codex CLI** (OpenAI) | via adaptador `@zed-industries/codex-acp@0.16.0` | 8005 | assinatura ChatGPT | **Concluída (#9)**: `codex/auto` (gpt-5.5 via override; gpt-5.6-sol não é suportado p/ contas ChatGPT) |
| **Copilot CLI** (GitHub) | oficial (`copilot --acp`) | 8006 | assinatura GitHub Copilot | Pendente — issue **#10** |

## Tier 2 — interessantes (quando houver uso real)

| Provedor | ACP | Porta sugerida | Autenticação | Observações |
|---|---|---|---|---|
| **Cursor CLI** | oficial (`agent acp`, docs cursor.com) | 8007 | conta Cursor | ACP nativo; bom para quem já usa Cursor |
| **Qwen Code** | ACP (ecosistema) | 8008 | OAuth Qwen (free tier) | Pendente — issue **#11**; free tier real |
| **Kimi CLI** (Moonshot) | via adapters (acpx/zed) | 8009 | conta Moonshot | Modelos k2 forte em código |
| **Droid** (Factory) | via adapters | 8009 | conta Factory | Popular em automação |
| **OpenClaw** | via adapters | 8010 | própria | Multi-provider |
| **Qoder / Trae / Amp / iFlow / Pi / Cline** | via adapters | 8011+ | próprias | Nicho — só sob demanda |

## Tier 3 — sem CLI de assinatura (rota LiteLLM direta, fora do escopo atual)

| Provedor | Via | Quando |
|---|---|---|
| **Ollama** (local) | OpenAI-compatible `http://host.docker.internal:11434/v1` | modelos locais, zero custo (já documentado no README) |
| **Anthropic API** | `anthropic/` nativo do LiteLLM | quando precisar de Claude sem CLI |
| **Amazon Bedrock** | `aws/` no LiteLLM com credenciais AWS | ambientes AWS corporativos |
| **Google API / OpenRouter** | `gemini/` ou `openrouter/` no LiteLLM | sem CLI, cobrança por uso |

## Como cadastrar um novo provedor (padrão consolidado)
1. Wrapper em `scripts/adapters/<provider>-acp.sh` (pin de versão; descarta flags kiro-específicas).
2. Registrar em `scripts/providers.sh` (binário, porta, erro de ausência).
3. Instância do gateway na porta nova (loopback) + `MODEL_VALIDATION=off`.
4. Rotas no `sync-providers.sh` — **validar 1 chat real por id** antes de expor (lição #5/#7).
5. Alias `<provider>/free` para modelo free sempre vivo.
6. Testes em `test-gateway.sh` e README.

Fontes: agentclientprotocol.com (registry), acpx.sh (adapters builtin), docs oficiais de cada CLI,
Zed ACP agents. Verificação feita em 2026-09-18.
