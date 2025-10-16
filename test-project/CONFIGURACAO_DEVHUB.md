# Configuração do DevHub - Guia em Português 🇧🇷

## ✅ Problema Resolvido!

Identifiquei que você **tem** um DevHub configurado:
- **Username:** `lbarion@salesforce.com.poc`
- **Status:** Conectado ✓

O problema era que o script anterior não estava detectando corretamente o DevHub devido à formatação do JSON.

---

## 🔧 Solução Aplicada

Corrigi o script `setup-test-org.sh` para:
1. ✅ Detectar corretamente DevHubs (mesmo com diferentes formatações JSON)
2. ✅ Configurar automaticamente o DevHub padrão se não estiver definido
3. ✅ Mostrar mensagens mais claras e informativas

---

## 🚀 Como Usar Agora

### Opção 1: Com Scratch Org (usando DevHub)

```bash
cd test-project
./scripts/setup-test-org.sh
```

O script agora irá:
1. Detectar seu DevHub (`lbarion@salesforce.com.poc`)
2. Configurá-lo como padrão automaticamente
3. Criar um scratch org
4. Fazer o deploy dos metadados

### Opção 2: Com Org Existente (sem precisar de DevHub)

Se preferir usar uma sandbox ou developer edition existente:

```bash
cd test-project
./scripts/setup-existing-org.sh [alias-da-org]
```

**Exemplos:**
```bash
# Usar uma das suas orgs existentes
./scripts/setup-existing-org.sh BradescoCockpitDev08

# Ou deixar o script perguntar qual org usar
./scripts/setup-existing-org.sh

# Ou autenticar uma nova org
./scripts/setup-existing-org.sh
```

---

## 🔍 Verificando sua Configuração

### Ver todas as orgs autorizadas:
```bash
sf org list
```

### Ver o DevHub padrão:
```bash
sf config get target-dev-hub
```

### Configurar DevHub padrão manualmente:
```bash
sf config set target-dev-hub=lbarion@salesforce.com.poc
```

---

## 📊 Suas Orgs Disponíveis

Detectei as seguintes orgs na sua configuração:

### DevHub ✓
- **lbarion@salesforce.com.poc** (Developer Edition)
  - 🟢 Pode criar scratch orgs

### Sandboxes
- **BradescoCockpitDev08**
- **CockpitBradescoMonitoring** 
- **BradescoCockpitPoC19**

Você pode usar **qualquer uma dessas** orgs para testar o plugin!

---

## 🎯 Próximos Passos

### Para Scratch Org (recomendado para testes):

```bash
# 1. Configurar DevHub como padrão
sf config set target-dev-hub=lbarion@salesforce.com.poc

# 2. Executar setup
cd test-project
./scripts/setup-test-org.sh

# 3. Testar backup
sf backup create --target-org backup-test --manifest manifest/package.xml
```

### Para Org Existente (mais rápido):

```bash
# 1. Usar org existente
cd test-project
./scripts/setup-existing-org.sh BradescoCockpitDev08

# 2. Testar backup
sf backup create --target-org BradescoCockpitDev08 --manifest manifest/package.xml
```

---

## ❓ Perguntas Frequentes

### P: Ainda recebo erro sobre DevHub?

**R:** Execute manualmente:
```bash
sf config set target-dev-hub=lbarion@salesforce.com.poc
```

Depois rode novamente o script.

---

### P: Posso testar sem criar scratch org?

**R:** Sim! Use o script alternativo:
```bash
./scripts/setup-existing-org.sh
```

Este script permite usar qualquer sandbox ou developer edition existente.

---

### P: Qual é a diferença entre as opções?

**R:**
- **Scratch Org** (via `setup-test-org.sh`):
  - ✅ Ambiente limpo e isolado
  - ✅ Ideal para testes
  - ❌ Requer DevHub
  - ❌ Expira em 7 dias

- **Org Existente** (via `setup-existing-org.sh`):
  - ✅ Não precisa de DevHub
  - ✅ Permanente
  - ❌ Pode ter metadados existentes
  - ⚠️ Cuidado para não sobrescrever dados importantes

---

### P: Como limpar depois dos testes?

**R:**
```bash
# Para scratch org
./scripts/cleanup-test.sh --delete-org backup-test

# Para org existente (apenas limpa arquivos locais, não deleta a org)
./scripts/cleanup-test.sh
```

---

## 🛠️ Troubleshooting

### Erro: "sf: command not found"
```bash
npm install -g @salesforce/cli
```

### Erro: "No default org set"
```bash
sf config set target-org=NOME_DA_SUA_ORG
```

### Erro: "Invalid client id"
```bash
# Re-autenticar a org
sf org login web --alias minha-org
```

### Ver logs detalhados
```bash
export SF_LOG_LEVEL=debug
sf org list
```

---

## 📚 Scripts Disponíveis

| Script | Uso | Requer DevHub? |
|--------|-----|----------------|
| `setup-test-org.sh` | Criar scratch org | ✅ Sim |
| `setup-existing-org.sh` | Usar org existente | ❌ Não |
| `run-full-test.sh` | Teste automatizado | ❌ Não |
| `cleanup-test.sh` | Limpar ambiente | ❌ Não |

---

## 🎉 Tudo Pronto!

Agora você tem **duas opções** para configurar o ambiente de testes:

1. **Com Scratch Org** → `./scripts/setup-test-org.sh`
2. **Com Org Existente** → `./scripts/setup-existing-org.sh`

Escolha a que preferir e comece a testar! 🚀

---

## 📞 Precisa de Ajuda?

**Erro no script?**
- Verifique se está no diretório `test-project/`
- Certifique-se que os scripts têm permissão de execução: `chmod +x scripts/*.sh`

**Dúvidas sobre o plugin?**
- Veja [QUICK_START.md](QUICK_START.md)
- Consulte [README.md](README.md)

**Problemas com Salesforce CLI?**
```bash
sf doctor
```

---

**Última atualização:** 16 de Outubro de 2025
**Versão do guia:** 1.0

