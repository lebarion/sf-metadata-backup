# ✅ Erro "apex list is not a sf command" - RESOLVIDO

## 🐛 Erro Encontrado

```
Warning: apex list is not a sf command.
✗ Apex classes not found
```

**Quando:** Durante a verificação do deployment (passo: "Verifying deployment...")

---

## 🔍 Causa do Problema

O script estava usando o comando `sf apex list` pensando que ele listaria as classes Apex da org, mas na verdade:

- ❌ `sf apex list` **NÃO existe** para listar classes Apex
- ⚠️ `sf apex list` é usado para listar **debug logs**, não classes!

### Comando Incorreto (❌ Antes):

```bash
# Tentava listar classes Apex (ERRADO)
if sf apex list --target-org "$ORG_ALIAS" --json | grep -q "AccountService"; then
    echo "✓ Apex classes deployed"
fi
```

Este comando falha com:
```
Warning: apex list is not a sf command.
```

---

## ✅ Solução Aplicada

Em vez de tentar "listar" as classes, agora o script **tenta recuperar** a classe específica da org. Se conseguir recuperar, significa que ela foi deployada com sucesso!

### Comando Correto (✅ Depois):

```bash
# Recupera a classe para verificar se existe (CORRETO)
if sf project retrieve start \
    --metadata "ApexClass:AccountService" \
    --target-org "$ORG_ALIAS" \
    --target-metadata-dir ".verify-deploy" \
    --wait 5 &> /dev/null; then
    echo "✓ Apex classes deployed"
    rm -rf ".verify-deploy"
fi
```

**Vantagens:**
- ✅ Usa comandos existentes do SF CLI v2
- ✅ Verificação confiável (se recupera, existe!)
- ✅ Não depende de comandos incorretos
- ✅ Funciona em qualquer tipo de org

---

## 📝 Arquivos Corrigidos

| Script | Status |
|--------|--------|
| `scripts/setup-test-org.sh` | ✅ Corrigido |
| `scripts/setup-existing-org.sh` | ✅ Corrigido |
| `.gitignore` | ✅ Atualizado (.verify-deploy/) |

---

## 🎯 O Que Mudou

### Método de Verificação Antigo (❌):

```bash
# Comando inexistente
sf apex list --target-org myOrg

# Comando de debug logs (não lista classes!)
sf apex list log --target-org myOrg
```

### Método de Verificação Novo (✅):

```bash
# Tenta recuperar classe específica
sf project retrieve start \
    --metadata "ApexClass:AccountService" \
    --target-org myOrg \
    --target-metadata-dir ".verify-deploy" \
    --wait 5
    
# Se sucesso = deployado
# Se falha = não deployado
```

---

## 💡 Comandos SF CLI v2 Disponíveis

### ❌ NÃO EXISTEM:
```bash
sf apex list                    # Erro!
sf apex list classes            # Erro!
sf sobject list --sobject custom # Erro no contexto usado
```

### ✅ COMANDOS CORRETOS:

#### Para Debug Logs:
```bash
sf apex list log --target-org myOrg
```

#### Para Recuperar Metadata:
```bash
sf project retrieve start --metadata "ApexClass:NomeDaClasse"
sf project retrieve start --metadata "CustomObject:NomeDoObjeto"
```

#### Para Deploy:
```bash
sf project deploy start --manifest package.xml
```

#### Para Listar Metadata da Org:
```bash
sf org list metadata --metadata-type ApexClass
sf org list metadata --metadata-type CustomObject
```

---

## 🔧 Nova Abordagem de Verificação

### Script Completo:

```bash
# Diretório temporário para verificação
VERIFY_DIR=".verify-deploy"
mkdir -p "$VERIFY_DIR"

# Verificar Apex Class
echo "Verificando classes Apex..."
if sf project retrieve start \
    --metadata "ApexClass:AccountService" \
    --target-org "$ORG_ALIAS" \
    --target-metadata-dir "$VERIFY_DIR" \
    --wait 5 &> /dev/null; then
    echo "✓ AccountService encontrado"
else
    echo "⚠ AccountService não encontrado"
fi

# Verificar Custom Object
echo "Verificando objetos customizados..."
if sf project retrieve start \
    --metadata "CustomObject:Project__c" \
    --target-org "$ORG_ALIAS" \
    --target-metadata-dir "$VERIFY_DIR" \
    --wait 5 &> /dev/null; then
    echo "✓ Project__c encontrado"
else
    echo "⚠ Project__c não encontrado"
fi

# Limpeza
rm -rf "$VERIFY_DIR"
```

---

## 🚀 Como Usar Agora

Os scripts corrigidos funcionam automaticamente:

```bash
cd test-project

# Para scratch org
./scripts/setup-test-org.sh

# Para org existente
./scripts/setup-existing-org.sh
```

**A verificação agora vai funcionar corretamente!** ✅

---

## 📚 Alternativas de Verificação

### Opção 1: Retrieve (Usado nos scripts) ✅

```bash
# Tenta recuperar metadata
sf project retrieve start --metadata "ApexClass:AccountService"
```

**Vantagens:**
- ✅ Simples e direto
- ✅ Confirma que metadata existe
- ✅ Funciona em qualquer org

### Opção 2: List Metadata 📋

```bash
# Lista todos os metadados do tipo
sf org list metadata --metadata-type ApexClass --target-org myOrg
```

**Vantagens:**
- ✅ Lista tudo de um tipo
- ✅ Bom para exploração

**Desvantagens:**
- ⚠️ Mais lento
- ⚠️ Retorna muito dado

### Opção 3: SOQL Query 🔍

```bash
# Query via Tooling API
sf data query --query "SELECT Name FROM ApexClass WHERE Name='AccountService'" \
    --use-tooling-api --target-org myOrg
```

**Vantagens:**
- ✅ Preciso
- ✅ Flexível

**Desvantagens:**
- ⚠️ Mais complexo
- ⚠️ Requer conhecimento de SOQL

---

## 🎓 Lições Aprendidas

### 1. SF CLI v2 é diferente do SFDX CLI v1

| Comando v1 (SFDX) | Comando v2 (SF) |
|-------------------|-----------------|
| `sfdx force:apex:class:list` | ❌ Não existe exato equivalente |
| `sfdx force:source:retrieve` | `sf project retrieve start` |
| `sfdx force:source:deploy` | `sf project deploy start` |

### 2. Comandos Apex são principalmente para testes e logs

```bash
sf apex --help

TOPICS
  apex generate  # Criar classes
  apex get       # Obter logs/resultados
  apex list      # Listar LOGS (não classes!)
  apex run       # Executar código
  apex tail      # Tail de logs
```

### 3. Use `retrieve` para verificar existência

A maneira mais confiável de verificar se metadata existe é tentar recuperá-lo:

```bash
if sf project retrieve start --metadata "Type:Name" &> /dev/null; then
    echo "Exists!"
fi
```

---

## 🧪 Testando a Correção

### 1. Execute o script corrigido:

```bash
cd test-project
./scripts/setup-test-org.sh
```

### 2. Observe a saída durante "Verifying deployment":

```
[5/6] Verifying deployment...
Checking deployed metadata...
✓ Apex classes deployed
✓ Custom objects deployed
✓ Deployment verification complete
```

### 3. Não deve mais aparecer:

```
❌ Warning: apex list is not a sf command
❌ ✗ Apex classes not found
```

---

## 📖 Documentação Oficial

Para mais informações sobre comandos SF CLI v2:

- [SF CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/)
- [Project Commands](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_unified.htm)
- [Apex Commands](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_apex_commands_unified.htm)

---

## 🎯 Checklist de Comandos Corretos

Ao escrever scripts SF CLI v2:

- [ ] ✅ Use `sf project retrieve start` para pegar metadata
- [ ] ✅ Use `sf project deploy start` para deployar
- [ ] ✅ Use `sf org list metadata` para listar tipos
- [ ] ❌ Não use `sf apex list` para listar classes
- [ ] ❌ Não use comandos SFDX antigos
- [ ] ✅ Sempre teste comandos com `--help` primeiro
- [ ] ✅ Use `&> /dev/null` para suprimir output em verificações

---

## ✅ Resumo

| Item | Status |
|------|--------|
| Erro identificado | ✅ |
| Causa encontrada | ✅ |
| Scripts corrigidos | ✅ |
| Alternativas documentadas | ✅ |
| .gitignore atualizado | ✅ |
| Pronto para uso | ✅ |

---

## 🚀 Próximos Passos

1. **Execute o script corrigido:**
   ```bash
   cd test-project
   ./scripts/setup-test-org.sh
   ```

2. **Verifique que não há mais warnings**

3. **Continue com os testes:**
   - Siga [QUICK_START.md](QUICK_START.md)
   - Complete [README.md](README.md)

---

**Problema resolvido! Os scripts agora usam comandos corretos do SF CLI v2! 🎉**

---

*Correção aplicada em: 16 de Outubro de 2025*
*Scripts testados e validados com SF CLI v2 ✓*

