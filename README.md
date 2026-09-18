# Open WebUI + Kiro (lab local)

Chat local (http://localhost:3000) usando os modelos da sua conta Kiro,
intermediados por LiteLLM e um gateway comunitário que opera **somente pelo
binário oficial `kiro-cli`** (via ACP) — sem leitura de credenciais.

```
Browser → Open WebUI :3000 → LiteLLM :4000 → Kiro Gateway :8000 → kiro-cli → modelos Kiro
```

## Pré-requisitos

- Docker Desktop **em execução** (28+)
- Python 3.14+, `uv`, `git`, `curl`, `openssl`
- `kiro-cli` instalado e **autenticado** (`kiro-cli login` se necessário)

## Início rápido

Fluxo do novo usuário:

```bash
git clone https://github.com/jonathasrochadesouza/openwebui-gateway-providers.git
cd openwebui-gateway-providers
kiro-cli login            # se ainda não autenticou
./scripts/setup.sh        # gera .env, clona o gateway (v2.4.1), instala dependências
./scripts/start.sh        # sobe Kiro Gateway + Open WebUI + LiteLLM
# abra http://localhost:3000
```

Abra **http://localhost:3000** e crie o primeiro usuário administrador.

### Conectar ao LiteLLM (uma vez)

Settings → Admin Settings → Connections → OpenAI API Connections → Add Connection:

| Campo | Valor |
|---|---|
| Nome | LiteLLM Local |
| Base URL | `http://litellm:4000/v1` |
| API Key | valor de `LITELLM_MASTER_KEY` em `.env` |
| Prefix ID | `lab` |
| Model IDs | `kiro/claude-haiku-4-5` |

Depois selecione o modelo `kiro/claude-haiku-4-5` no chat e envie uma mensagem.

## Operação

```bash
./scripts/start.sh         # sobe tudo
./scripts/status.sh        # status + conferência de binds
./scripts/stop.sh          # para tudo
./scripts/test-gateway.sh  # valida Kiro Gateway
./scripts/test-litellm.sh  # valida LiteLLM (e lista modelos expostos)
```

## Notas

- Os ids de modelos do Kiro mudam com o tempo — consulte `./scripts/test-litellm.sh`
  para ver a lista atual e ajuste `litellm_config.yaml` se necessário.
- Se o login do kiro-cli expirar: `kiro-cli login`, depois `./scripts/stop.sh && ./scripts/start.sh`.
- Todos os serviços escutam **somente em 127.0.0.1**. Segredos ficam só no `.env`
  (gerado com permissão 600 e ignorado pelo Git).
- ACP_TRUST_TOOLS=true no `.env` do gateway permite que o kiro-cli execute suas
  ferramentas internas sem pedir confirmação. Para modo somente-resposta, troque
  para `false` em `kiro-gateway/.env` e reinicie (`./scripts/stop.sh && ./scripts/start.sh`).
- Assinatura do Kiro tem créditos limitados — respeite limites e termos de uso.
- Backup do volume (on demand): `docker run --rm -v openwebui-kiro_open-webui-data:/data \
  -v "$PWD":/backup alpine tar czf /backup/open-webui-data-backup.tgz -C /data .`
- Remoção: `./scripts/stop.sh` e `docker compose down` (use `down -v` apenas se
  quiser apagar dados — irreversível). Nunca use `docker system prune` como rotina.
