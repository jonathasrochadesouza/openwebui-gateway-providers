# AGENTS.md — Instruções para agentes de IA

Arquivo exclusivo para IAs (Codex, Claude Code, Cursor, Gemini, Devin etc.) que
forem alterar este projeto. Leia-o inteiro antes de qualquer mudança.

## O que é este projeto

Stack local de chat: **Open WebUI (Docker) → LiteLLM Proxy (Docker) → gateways ACP
no host (1 por CLI) → CLI oficial do provedor**. Nada roda em cloud; tudo bind em
`127.0.0.1`. Os CLIs (`kiro-cli`, `kilo`, `claude`, `opencode`, `agy`, `codex`) são
binários oficiais autenticados pelos seus próprios logins — o gateway nunca lê
tokens, cookies ou credenciais.

## Comandos essenciais

```bash
./scripts/up.sh              # sobe TODO o stack (idempotente)
./scripts/status.sh          # estado de tudo + binds
./scripts/stop.sh            # para gateways e containers (dados preservados)
./scripts/sync-providers.sh  # regenera litellm_config.yaml com modelos validados
./scripts/test-gateway.sh [provedor...]   # valida gateways
./scripts/test-litellm.sh    # valida LiteLLM e lista modelos
bash -n scripts/*.sh         # valida sintaxe de TODOS os scripts antes de commitar
```

## Regras inegociáveis (hard rules)

- **Nenhum segredo** em código, logs, README, scripts, issues ou commits. Segredos
  vivem apenas em `.env` (permissão 600, ignorado pelo Git). Nunca imprima o valor
  de `KIRO_GATEWAY_API_KEY`, `LITELLM_MASTER_KEY`, `WEBUI_SECRET_KEY`.
- **Nunca leia, copie ou manipule credenciais/tokens/cookies** de nenhum CLI
  (`~/.aws/sso/cache`, `~/.codex/auth.json`, `~/.gemini/*`, keyring etc.).
- **Nada em `0.0.0.0`**: toda porta exposta no host é `127.0.0.1` (3000, 4000,
  8000–8005 fixos por provedor em `scripts/providers.sh`).
- **Não exponha rotas quebradas**: todo id de modelo listado em `litellm_config.yaml`
  precisa ter passado por 1 chat real (regra das issues #5/#7). Cache de validação
  em `logs/<provider>-validated.txt`.
- Operação **apenas pelo binário oficial** do provedor (nativo ACP ou adaptador
  canônico da org agentclientprotocol/Zed) — nunca APIs privadas, extração de
  tokens, pooling de contas ou bypass de quota/licenças.
- **Sem operações destrutivas fora do escopo**: nada de `docker system prune`,
  `rm -rf` fora da pasta, remoção de containers/volumes de outros projetos.
  `docker compose down -v` apaga dados do usuário — só com pedido explícito.
- Não altere o banco interno do Open WebUI (volume/SQLite). Configuração vai por env
  do container (`compose.yaml`). Modo decidido pelo usuário: **single-user sem login**
  (`WEBUI_AUTH=False`, irreversível — não reverter para multi-usuário sem aprovação,
  pois exige volume novo).
- Commits/push só quando o usuário pedir explicitamente.

## Estrutura (onde mexer)

| Área | Arquivo(s) |
|---|---|
| Portas/binários/detecção de provedores | `scripts/providers.sh` (fonte única de verdade; portável p/ bash 3.2 — macOS, **sem arrays associativos**) |
| Subir/parar instâncias | `scripts/start.sh`, `scripts/stop.sh`, `scripts/up.sh` |
| Wrappers de adaptadores ACP | `scripts/adapters/<provider>-acp.sh` (versão fixada, descartam flags kiro-específicas `acp --agent-engine v2`) |
| Catálogo/rotas de modelos | `scripts/sync-providers.sh` + validadores `scripts/validate-<provider>.sh` (cache em `logs/`) |
| Container infra | `compose.yaml` (name: openwebui-kiro — fixado; não renomear), `litellm_config.yaml` (gerado — não editar à mão) |
| Docs humanas | `README.md` (mínimo p/ rodar), `docs/providers-roadmap.md` (análise de provedores), `evidencias.md` (trilha), `docs/issues/issue-N-teste.md` (cenários) |

## Antes de mexer em cada área, leia

| Área | Leia |
|---|---|
| Novo provedor | `docs/providers-roadmap.md` + issues #2/#3/#6/#8/#9 (padrão consolidado: wrapper → providers.sh → instância → sync com validação → alias `<provider>/free` → testes) |
| Modelos/mapping | issues #5 (regra da validação), #7 (catálogo completo por conta do usuário) |
| Conectividade Docker | `compose.yaml` (host.docker.internal para gateways no host; hostname `litellm` para a rede interna) |

## Convenções

- Bash POSIX-portável (o ambiente é macOS com bash 3.2): sem `declare -A`,
  sem `mapfile`, sem `set -e` dentro de subshells de substituição de comando.
- Comentários curtos e só quando necessários; nomes de variáveis em inglês,
  docs em pt-BR.
- Ao mudar scripts: rode `bash -n scripts/*.sh` e o teste do provedor afetado.
- Issues/PRs: referencie a issue no corpo do commit; SDD no formato das issues
  #1–#11 (Objetivo/Contexto/Decisão/Requisitos/Fases/Critérios/Riscos).

## Armadilhas conhecidas (não repetir)

- Pidfiles podem apontar ao wrapper morto; pare instâncias pelo processo que
  **escuta na porta** (`lsof -ti :PORT`).
- `set_model` não é suportado por todos os adaptadores (Codex/Zed) — para esses,
  o modelo é o default do wrapper e expõe-se só `auto`.
- LiteLLM não aceita `model_name` com mais de um `/` — normalize barras internas
  para pontos (o id real vai em `litellm_params.model`).
- Catálogos dos CLIs mudam com o tempo: sempre valide ids por chat real antes de
  expor; ids antigos podem sumir (ex.: gemini CLI descontinuado).
- Desfazer startup falhado: reexecutar `./scripts/up.sh` (limpa órfãos e sobe).
