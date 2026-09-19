# Open WebUI + Kiro/Kilo/Claude (lab local)

Chat local (http://localhost:3000) usando a assinatura das suas ferramentas de IA
via CLIs oficiais (`kiro-cli`, `kilo`, `claude`), cada uma atrás de um gateway
comunitário ACP, unificadas pelo LiteLLM — sem leitura de credenciais.

```
Browser → Open WebUI :3000 → LiteLLM :4000 ─┬→ gateway :8000 → kiro-cli acp
                                            ├→ gateway :8001 → kilo acp
                                            └→ gateway :8002 → claude-agent-acp → Claude
```

Os modelos aparecem com prefixo do provedor: `kiro/…`, `kilo/…`, `claude/…`.

## Pré-requisitos

- Docker Desktop **em execução** (28+)
- Python 3.14+, `uv`, `git`, `curl`, `openssl`, Node 20+ (para adaptadores via npx)
- Pelo menos um CLI, autenticado: `kiro-cli login`, `kilo auth` e/ou `claude` (`/login`)
- Opcional: `PROVIDERS=kiro,kilo,claude` no `.env` (vazio = auto-detecta os instalados)

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

### Conexão com o LiteLLM

**Automática** — o container Open WebUI já sobe com `OPENAI_API_BASE_URL=http://litellm:4000/v1`
e `ENABLE_PERSISTENT_CONFIG=False`: ao criar o admin, os modelos `kiro/*`, `kilo/*`, `claude/*`
já aparecem no seletor. Para re-sincronizar modelos após mudanças: `./scripts/sync-providers.sh`.

Cadastro manual (alternativo): Settings → Admin Settings → Connections → OpenAI API → Add Connection
com Base URL `http://litellm:4000/v1`, API Key = `LITELLM_MASTER_KEY` do `.env`, Prefix ID `lab`.

## Operação

```bash
./scripts/start.sh                        # detecta provedores, sobe 1 gateway por CLI + Compose
./scripts/sync-providers.sh               # regenera litellm_config.yaml com os modelos ao vivo
./scripts/status.sh                       # status de tudo + conferência de binds
./scripts/stop.sh                         # para tudo
./scripts/test-gateway.sh [provedor...]   # valida gateways (default: todos habilitados)
./scripts/test-litellm.sh                 # valida LiteLLM (e lista modelos expostos)
```

## Notas

- Os ids de modelos do Kiro mudam com o tempo — consulte `./scripts/test-litellm.sh`
  para ver a lista atual e ajuste `litellm_config.yaml` se necessário.
- Se um login expirar (`kiro-cli login`, `kilo auth`, `claude` `/login`), depois
  `./scripts/stop.sh && ./scripts/start.sh`.
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
