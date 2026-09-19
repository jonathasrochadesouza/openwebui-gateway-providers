# Cenário de teste — Issue #4 (detecção automática e seleção via PROVIDERS)

**Teste (direto):**
```bash
# 1. Auto-detecção (PROVIDERS vazio no .env): habilita o que estiver instalado
PROVIDERS= bash -c 'source scripts/providers.sh && enabled_providers'
# esperado nesta máquina: kiro kilo claude

# 2. Seleção explícita (opt-in/out)
printf 'PROVIDERS=kiro\n' | cat - .env > /tmp/env && sed -i '' 's/^PROVIDERS=.*//' .env && printf 'PROVIDERS=kiro\n' >> .env
./scripts/start.sh && ./scripts/status.sh
# esperado: só gateway kiro em :8000; kilo/claude não iniciam

# 3. CLI habilitado mas ausente -> falha clara
# (remover kiro-cli do PATH simulando ausência) -> "AVISO: provedor 'kiro' habilitado mas kiro-cli não encontrado"

# 4. Voltar ao multi-provider
sed -i '' 's/^PROVIDERS=kiro/PROVIDERS=/' .env && ./scripts/start.sh && ./scripts/status.sh
# esperado: 3 gateways (8000/8001/8002) + 18 modelos no LiteLLM
```

**Esperado:** `PROVIDERS` vazio detecta os CLIs instalados; explícito respeita só o listado; CLI ausente/habilitado produz erro claro sem subir meia-stack; `status.sh` mostra uma linha por gateway; retrocompat: só kiro = comportamento idêntico ao anterior.
