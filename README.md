# Open WebUI + LiteLLM + Kiro Gateway (lab local)

Ambiente local, seguro e reproduzível para usar o Open WebUI com os modelos da conta Kiro,
via gateway comunitário que opera **exclusivamente pelo binário oficial `kiro-cli`** (ACP),
intermediado pelo LiteLLM Proxy.

## Arquitetura

```
Browser
  │  http://localhost:3000
  ▼
Open WebUI (Docker, 127.0.0.1:3000)
  │  http://litellm:4000/v1  (rede interna do Compose)
  ▼
LiteLLM Proxy (Docker, 127.0.0.1:4000 — bind de diagnóstico)
  │  http://host.docker.internal:8000/v1
  ▼
Kiro Gateway (host, 127.0.0.1:8000)
  │  spawn `kiro-cli acp` (JSON-RPC/stdio) — apenas o binário oficial
  ▼
kiro-cli oficial autenticado → modelos disponíveis na sua conta Kiro
```

## Pré-requisitos (versões detectadas no ambiente de instalação)

| Item | Versão |
|---|---|
| macOS | 15.7 (arm64) |
| Docker / Compose | 28.4.0 / v2.39.2 |
| Python | 3.14.0 |
| uv | 0.11.32 |
| kiro-cli | 2.21.4 (`~/.local/bin/kiro-cli`, já autenticado) |
| Kiro Gateway (ankitcharolia) | v2.4.1 (commit `94f75c1`) |
| curl / OpenSSL | 8.7.1 / 3.6.3 |

## Estrutura de diretórios

```
~/ai-lab/openwebui-kiro/
├── compose.yaml            # Open WebUI + LiteLLM (binds 127.0.0.1)
├── litellm_config.yaml     # rota kiro/* → Kiro Gateway
├── .env                    # segredos (NUNCA versionar)
├── .env.example            # placeholders fictícios
├── .gitignore              # .env, *.secret, *.token, .venv/, __pycache__/
├── kiro-gateway.pid        # pid do gateway em execução
├── kiro-gateway/           # clone do gateway (v2.4.1)
├── logs/kiro-gateway.log   # log do gateway (sem prompts/respostas completos)
├── scripts/                # start / stop / status / test-gateway / test-litellm
└── evidencias.md           # trilha de evidências por fase
```

## Portas (todas somente loopback)

| Porta | Serviço | Bind |
|---|---|---|
| 3000 | Open WebUI (container 8080) | 127.0.0.1 |
| 4000 | LiteLLM (diagnóstico) | 127.0.0.1 |
| 8000 | Kiro Gateway | 127.0.0.1 |

## Operação

```bash
scripts/start.sh         # sobe Kiro Gateway + docker compose up -d
scripts/status.sh        # status de tudo + conferência de binds
scripts/stop.sh          # para containers e o Kiro Gateway
scripts/test-gateway.sh  # valida /health, /v1/models, chat e stream do gateway
scripts/test-litellm.sh  # valida /v1/models, chat e stream do LiteLLM
```

Logs do gateway: `logs/kiro-gateway.log` · logs dos containers: `docker compose logs -f [open-webui|litellm]`

## Login do kiro-cli (renovação)

```bash
kiro-cli whoami    # verifica sessão
kiro-cli login     # se expirado — conclua o fluxo no browser
```
Após renovar, reinicie apenas o Kiro Gateway (`scripts/stop.sh && scripts/start.sh`).
Nunca extraia/copie tokens: a autenticação vive dentro do kiro-cli.

## Cadastro manual do LiteLLM no Open WebUI (Fase 7)

1. Abra http://localhost:3000 e crie o **primeiro usuário administrador** (fluxo da UI).
2. Vá em **Settings → Admin Settings → Connections → OpenAI API Connections → Add Connection**:
   - Nome: `LiteLLM Local`
   - Base URL: `http://litellm:4000/v1`
   - API Key: valor de `LITELLM_MASTER_KEY` do `.env` (não compartilhe em chat/prints)
   - Prefix ID: `lab`
   - Model IDs: `kiro/claude-haiku-4-5` (ou a lista de `scripts/test-litellm.sh`)
3. Salve a conexão. Dentro do Compose, `localhost` apontaria para o próprio container
   Open WebUI — por isso a URL correta é `http://litellm:4000/v1` (hostname do serviço).
   O `host.docker.internal` é usado só internamente pelo LiteLLM para alcançar o gateway no host.
4. No chat, selecione `kiro/claude-haiku-4-5` e envie:
   *"Responda somente: Open WebUI conectado ao Kiro CLI."*

## Descobrir modelos disponíveis

```bash
scripts/test-litellm.sh   # lista os modelos expostos pelo LiteLLM
```
O catálogo do kiro-cli muda com o tempo; o gateway lê ao vivo via `kiro-cli acp`.
Para expor outro modelo, edite `litellm_config.yaml` (adicione uma entrada em `model_list`)
e rode `docker compose restart litellm`.

## Adicionar futuros provedores (não ativados por padrão)

- **Ollama:** conexão OpenAI em `http://host.docker.internal:11434/v1`.
- **Anthropic API oficial:** nova entrada em `litellm_config.yaml` com `model: anthropic/...`
  e `api_key: os.environ/ANTHROPIC_API_KEY` (adicione a chave ao `.env`).
- **Amazon Bedrock:** LiteLLM suporta via credenciais AWS no ambiente do container
  (`aws/...` em `model_list`; considere `AWS_PROFILE`/roles, nunca chaves fixas versionadas).

## Segurança

- Todos os serviços escutam apenas em `127.0.0.1` — nada exposto à rede.
- Segredos somente em `.env` (permissão 600), nunca em Git, README, scripts ou logs.
- O gateway comunitário (ankitcharolia/kiro-gateway, AGPL-3.0) opera só pelo binário oficial
  `kiro-cli acp`, sem leitura de credenciais. Revise o código antes de confiar em versões novas.
- Assinatura do Kiro ≠ API ilimitada: respeite limites/creditos e os termos de uso.
- Ferramenta independente, sem afiliação com Amazon/AWS (Kiro).

## Backup do volume `open-webui-data`

```bash
docker run --rm -v openwebui-kiro_open-webui-data:/data -v "$PWD":/backup alpine \
  tar czf /backup/open-webui-data-backup.tgz -C /data .
```
(Nome real do volume: verifique com `docker volume ls | grep open-webui`.)
Restauração: extraia o tar dentro de um volume novo vazio. Backup só sob demanda.

## Remoção segura

```bash
scripts/stop.sh
docker compose down            # remove containers deste compose (dados do volume ficam)
docker compose down -v         # ATENÇÃO: apaga também o volume (conversas/usuários do Open WebUI)
```
Nunca use `docker system prune` como rotina — afeta recursos de outros projetos.
