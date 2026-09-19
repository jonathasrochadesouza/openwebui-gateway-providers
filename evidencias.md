# Evidências — Open WebUI + LiteLLM + Kiro Gateway (lab local)

Trilha de evidências por fase. Nenhum segredo registrado neste arquivo.
Data da execução: 2026-09-18 · macOS 15.7 arm64 · shell /bin/bash

## Fase 1 — Pré-verificação

| Item | Resultado |
|---|---|
| Sistema | macOS 15.7 (Build 24G222), arm64, shell /bin/bash, home /Users/jonathasrochadesouza |
| Docker | 28.4.0, daemon ativo |
| Docker Compose | v2.39.2-desktop.1 |
| Git | 2.45.0 |
| Python 3 | 3.14.0 |
| curl | 8.7.1 |
| OpenSSL | 3.6.3 |
| kiro-cli | 2.21.4 em ~/.local/bin/kiro-cli |
| kiro-cli auth | `kiro-cli whoami` → sessão ativa (Google) |
| Portas 3000/4000/8000 | Livres na pré-verificação |
| uv | 0.11.32 (necessário para o gateway Python) |
| Pendências | Nenhuma instalação necessária |

## Fase 2 — Preparação do Kiro CLI

| Teste | Comando | Resultado |
|---|---|---|
| Sintaxe real | `kiro-cli chat --help` | `--no-interactive`, `--list-models`, `--model` confirmados |
| Modelos locais | `kiro-cli chat --list-models` | 9 modelos (auto\*, claude-sonnet-4.5, claude-sonnet-4, claude-haiku-4.5, deepseek-3.2, minimax-m2.5, minimax-m2.1, glm-5, qwen3-coder-next) |
| Chat validado | `kiro-cli chat --no-interactive --model claude-haiku-4.5 --trust-tools= "Responda somente: Kiro CLI pronto."` | resposta: "Kiro CLI pronto." · 0,02 créditos · 1s |

## Fase 3 — Seleção e instalação do Kiro Gateway

Comparação: 1) ankitcharolia/kiro-gateway (AGPL-3.0, Python/uv, ACP, auth Bearer, 75★) — **escolhido**;
2) szympajka/kiro-bridge (MIT, Go, ACP, sem auth) — alternativa;
3) githendrik/kiro-proxy-go — **rejeitado** (lê refresh token do cache, viola a regra "apenas binário oficial").

| Item | Resultado |
|---|---|
| Clone | ~/ai-lab/openwebui-kiro/kiro-gateway |
| Versão | tag v2.4.1 (commit 94f75c1, 2026-08-25) |
| Dependências | `uv sync` — venv isolado (nenhum pacote global) |
| .env | criado a partir de .env.example; KIRO_GATEWAY_API_KEY gerada com `openssl rand -hex 32`; chmod 600 |
| Bind | SERVER_HOST=127.0.0.1, SERVER_PORT=8000 (default 0.0.0.0 ajustado) |
| Início | `uv run main.py` em background; log em logs/kiro-gateway.log |
| Log de startup | "Starting Kiro Gateway v2.4.1 (ACP mode)" · ACP initialized: agent=Kiro CLI Agent v2.21.4 · catálogo populado com 9 modelos · "Uvicorn running on http://127.0.0.1:8000" |

## Fase 4 — Testes do Kiro Gateway

| Teste | Resultado |
|---|---|
| GET /health | HTTP 200 · {"status":"ok","mode":"acp-cli-bridge","version":"2.4.1"} |
| GET /v1/models (Bearer) | HTTP 200 · 10 ids: auto, claude-sonnet-4-5, claude-sonnet-4, claude-haiku-4-5, deepseek-3-2, minimax-m2-5, minimax-m2-1, glm-5, qwen3-coder-next, claude-auto |
| POST /v1/chat/completions (stream:false, claude-haiku-4-5) | HTTP 200 · content: "Kiro Gateway integrado com sucesso." · ~30,3s |
| POST /v1/chat/completions (stream:true) | 5 chunks SSE + [DONE] recebidos · frase correta nos deltas |
| Chave usada via variável de ambiente | nenhum segredo em histórico/log |

## Fase 5 — Open WebUI em Docker

| Teste | Resultado |
|---|---|
| `docker compose config` | válido |
| Bloqueio de espaço | pull falhou (no space left) — liberados 21,2 GB build cache + 1,4 GB imagens não usadas, com aprovação do usuário |
| `docker compose up -d` | open-webui + litellm iniciados |
| `docker compose ps` | open-webui Up (healthy) · litellm Up |
| curl -I http://127.0.0.1:3000 | HTTP 200 |
| Bind 3000 | 127.0.0.1:3000 (confirmado via lsof) |
| Volume | open-webui-data persistido em /app/backend/data |
| WEBUI_SECRET_KEY | definida via .env; WEBUI_AUTH não desativado |

## Fase 6 — LiteLLM Proxy

| Teste | Resultado |
|---|---|
| Config | litellm_config.yaml com model_list kiro/claude-haiku-4-5 → openai/claude-haiku-4-5 via api_base host.docker.internal:8000/v1, api_key os.environ/KIRO_GATEWAY_API_KEY; master_key os.environ/LITELLM_MASTER_KEY; set_verbose false |
| GET /v1/models (master key) | HTTP 200 · ids: kiro/claude-haiku-4-5 |
| Chat sem stream | HTTP 200 · content: "LiteLLM integrado com sucesso." · ~8,3s |
| Chat com stream | 6 chunks SSE + [DONE] · conteúdo concatenado confirmado |
| open-webui → http://litellm:4000/v1/models (Docker interno) | HTTP 200 |
| Bind 4000 | 127.0.0.1:4000 (confirmado via lsof) |
| Sem logs de conteúdo | set_verbose: false; sem callbacks/telemetria |

## Fase 7 — Configuração no Open WebUI (manual, via UI)

| Item | Status |
|---|---|
| Criação do 1º admin | concluída pelo usuário em http://localhost:3000 |
| Cadastro da conexão | concluído: Settings → Admin Settings → Connections → OpenAI API → Add Connection (valores no README) |
| Teste final na UI | **CONFIRMADO PELO USUÁRIO** — resposta via kiro/claude-haiku-4-5: "Open WebUI conectado ao Kiro CLI." (cadeia completa Open WebUI → LiteLLM → Kiro Gateway → kiro-cli validada de ponta a ponta) |

## Fase 8 — Artefatos

| Item | Status |
|---|---|
| scripts/ start, stop, status, test-gateway, test-litellm (.sh, executáveis) | criados; sem segredos; leem .env |
| README.md | criado (arquitetura, operação, segurança, backup, remoção) |
| .env.example | placeholders fictícios apenas (chmod 600 por precaução local) |
| .gitignore | .env, *.secret, *.token, .venv/, __pycache__/ (Git não inicializado por padrão) |
| evidencias.md | este arquivo |

## Relatório final (estado em 2026-09-18)

- Arquitetura ativa: Browser → Open WebUI (127.0.0.1:3000) → LiteLLM (127.0.0.1:4000, interno http://litellm:4000) → Kiro Gateway (127.0.0.1:8000) → kiro-cli 2.21.4 (ACP v2) → modelos da conta Kiro.
- Testes executados: todos da Fase 4 e Fase 6 aprovados; conectividade container↔container aprovada.
- Modelos expostos pelo LiteLLM: kiro/claude-haiku-4-5 (única rota configurada).
- Ações manuais pendentes: criar admin e cadastrar conexão no Open WebUI (Fase 7) + teste final na UI.
- Limitações conhecidas: temperatura/top_p inertes (ACP não aplica sampling); client-side function calling não suportado pelo kiro-cli via ACP; catálogo de modelos do Kiro rotaciona; assinatura Kiro tem créditos limitados; LiteLLM usa tag main-latest (flutuante).

## Implementação das issues #1–#4 (2026-09-18)

| Issue | Implementação | Validação |
|---|---|---|
| #1 Auto-config Open WebUI | env no container: OPENAI_API_BASE_URL=http://litellm:4000/v1, OPENAI_API_KEY=${LITELLM_MASTER_KEY}, ENABLE_PERSISTENT_CONFIG=False; modelos sincronizados via scripts/sync-providers.sh (catálogo ao vivo dos gateways; fallback catálogo completo — plano free/PRO não detectável para login Google/IdP: kiro-cli profile disponível só para IAM IdC) | container com env correta; 18 modelos expostos; chat end-to-end OK |
| #2 Kilo Code | 2ª instância gateway :8001, wrapper scripts/adapters/kilo-acp.sh (npx @kilocode/cli@7.7.5 — versão instalada 0.6.0 local não tem 'kilo acp'; CLI 1.0 tem) | :8001 healthy; 4 modelos (auto, claude-opus-4-8, claude-sonnet-4-6, claude-auto); chat+stream OK via gateway e LiteLLM |
| #3 Claude Code | 3ª instância :8002, wrapper scripts/adapters/claude-acp.sh (npx @agentclientprotocol/claude-agent-acp@0.31.4, Apache-2.0) | :8002 healthy; /v1/models com claude/default, sonnet[1m], opus[1m], haiku; **chat pendente de login do usuário no claude CLI ("Authentication required")** |
| #4 Detecção/seleção | scripts/providers.sh (bash 3.2 portável), PROVIDERS no .env (vazio=auto), pidfiles por provedor, start/stop/status/test parametrizados, litellm_config.yaml gerado dinamicamente | 3 gateways no ar via PROVIDERS vazio; status.sh por provedor; retrocompat preservada |

Cenários de teste por issue: docs/issues/issue-{1..4}-teste.md

## Issues #5 e #6 (2026-09-18)

- #5 Kilo: allowlist temporária no sync (só kilo/auto); diagnóstico: upstream responde "Add credits to continue" (conta sem créditos) — mapeamento correto aplicado, rota valida quando a conta tiver créditos.
- #6 OpenCode: 4ª instância gateway :8003 com wrapper scripts/adapters/opencode-acp.sh (binário oficial opencode 1.18.31, ACP nativo). Validação: /health ✓; 4 modelos (auto, claude-opus-4-8, claude-sonnet-4-6, claude-auto) — TODOS testados com chat real ✓; LiteLLM opencode/auto chat ✓ e stream (18 chunks) ✓; webui→litellm ✓. Total exposto: 19 modelos.

## kilo/free + issue #7 (2026-09-18)

- kilo/free implementado: alias MODEL_ALIASES=free=kilo/kilo-auto/free na instância kilo; chat validado no gateway (:8001) e via LiteLLM. Correção de robustez: stop.sh encerra pelo processo que escuta na porta; pidfile captura o pid correto do uv.
- Issue #7 criada: OpenCode — validar acessos do usuário (opencode auth/models) e expor todos os modelos da conta (groq, zen, auto free, …) com validação de chat real por id.

## Issue #7 implementada (2026-09-18)

- OpenCode: catálogo completo do usuário via `opencode models` (34 ids: 27 opencode-go/* + 7 free/opencode) + 4 ids ACP.
- Validação de chat real por id (scripts/validate-opencode.sh, cache logs/opencode-validated.txt): 32/34 CLI OK (muse-spark-1.2/1.3-contributor vazios → excluídos), ACP 4/4 OK → 36 rotas + opencode/free (alias nemotron-3-ultra-free).
- Normalização LiteLLM: model_name com barras internas viram pontos (ex.: opencode/opencode-go.glm-5.3-flash); id real preservado no backend.
- Total exposto: 52 modelos (kiro 10, kilo/free 1, claude 4, opencode 37). Validação via LiteLLM: opencode/free ✓, opencode/opencode-go.glm-5.3-flash ✓, opencode/auto ✓.

## Issues #8 e #9 implementadas (2026-09-19)

- #9 Codex: 6ª instância gateway :8005, wrapper scripts/adapters/codex-acp.sh (npx @zed-industries/codex-acp@0.16.0 com override -c 'model="gpt-5.5"'). Causa-raiz inicial: config local do codex usa gpt-5.6-sol, não suportado p/ contas ChatGPT (testado: gpt-5.1/5.6/5.2-codex/5-codex/o3/codex-mini → 400; gpt-5.5 OK). O adaptador Zed não implementa session/set_model (fallback default). Validação: chat "Codex integrado com sucesso." no gateway e via LiteLLM ✓; stream 6 chunks ✓. Rota exposta: codex/auto (única, regra #5).
- #8 Gemini: 5ª instância gateway :8004 no ar, porém upstream rejeita: "This client is no longer supported for Gemini Code Assist for individuals — migrate to Antigravity". Nenhuma rota gemini exposta até o usuário reautenticar o CLI com login suportado. Estrutura pronta (wrapper, providers.sh, sync com IDS vazio).
- Robustez start.sh: checagem de instância em execução agora exige /health (evita órfão de uv).
- Total exposto: 53 modelos (kiro 10, kilo/free 1, claude 4, opencode 37, codex/auto 1).

## Issues #8/#9 — Antigravity (2026-09-19)

- #8: pivô de Gemini CLI → Antigravity CLI (Google descontinuou "Code Assist individuals" no gemini CLI; usuário aprovou usar agy). Gateway :8004 via scripts/adapters/antigravity-acp.sh (npx agy-acp@0.5.2, Apache-2.0, envolve o binário oficial agy 1.2.7 e herda seu login). `agy` não tem modo ACP nativo (apenas stream-json print) — por isso o adaptador.
- Validação: `agy models` 14/14 ids com chat real OK (gemini-3.8/3.7/3.6-flash h/m/l, gemini-3.1-pro h/l, claude-sonnet-4-6, claude-opus-4-6-thinking, gpt-oss-120b-medium). Alias antigravity/free → gemini-3.8-flash-low. set_model funciona via config options do adaptador.
- LiteLLM: antigravity/free ✓, antigravity/gemini-3.1-pro-high ✓, antigravity/claude-opus-4-6-thinking ✓. Total exposto: 68 modelos.
- Validador permanente: scripts/validate-antigravity.sh (cache logs/antigravity-validated.txt, REVALIDATE=1).

## Single-user sem login (2026-09-19, pedido do usuário)

- Backup prévio do volume: open-webui-data-backup-20260919.tgz (624 MB, pasta do projeto).
- compose.yaml: WEBUI_AUTH=False no open-webui. Volume openwebui-kiro_open-webui-data recriado vazio (com aprovação explícita — irreversível).
- Validação: /api/config → auth_required=False; webui HTTP 200 healthy; conexão LiteLLM automática mantida (env + ENABLE_PERSISTENT_CONFIG=False).
- Docs atualizadas: README (sem login, onboarding 1 clique), AGENTS.md (modo single-user decidido).
