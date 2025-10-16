# ⚠️ Limitação Crítica do Plugin de Backup

## 🔍 Problema Identificado

Durante os testes, descobrimos que o plugin **não está funcionando corretamente** para rollback de **modificações em metadata existente**.

---

## 📋 O Que Testamos

### Fluxo de Teste:
```
1. ✅ Estado Limpo - Arquivo sem System.debug
2. ✅ Criou Backup (backup_2025-10-16T16-44-33)
3. ✅ Modificou arquivo (adicionou System.debug)
4. ✅ Fez Deploy da modificação
5. ❌ Tentou Rollback → NÃO FUNCIONOU
```

### Resultado:
```bash
sf backup rollback --target-org backup-test --backup-dir backups/backup_2025-10-16T16-44-33

# Output:
[1/1] Remove new metadata...... ⊘ (skipped - no metadata to remove)
Rollback Completed Successfully!
```

**Mas nada foi revertido!** 😢

---

## 🐛 Causa Raiz

### 1. Recovery Package Vazio

```bash
$ cat backups/backup_2025-10-16T16-44-33/rollback/recovery-package.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <version>61.0</version>
</Package>
```

**Problema:** Não tem nenhum `<types>` ou `<members>`!

### 2. Metadata Não Salvo

```bash
$ ls -la backups/backup_2025-10-16T16-44-33/metadata/
total 0
drwxr-xr-x  2 lbarion  staff   64 Oct 16 13:44 .
drwxr-xr-x  5 lbarion  staff  160 Oct 16 13:44 ..
```

**Problema:** Diretório vazio! O plugin não salvou o metadata recuperado.

---

## 🤔 Por Que Acontece?

### Análise do Fluxo do Plugin:

1. **Backup Create** (`sf backup create`):
   ```
   - Lê package.xml ✅
   - Executa `sf project retrieve` para recuperar metadata da org ✅
   - Gera recovery-package.xml ❌ (fica vazio)
   - Gera destructive-changes.xml ✅
   - NÃO salva arquivos recuperados ❌
   ```

2. **Backup Rollback** (`sf backup rollback`):
   ```
   - Lê recovery-package.xml ❌ (está vazio)
   - Tenta deployar metadata antigo ❌ (não existe)
   - Tenta remover metadata novo ⚠️ (funciona só para metadata ADICIONADO)
   ```

### Problema Principal:

O plugin assume que você vai fazer rollback de **metadata ADICIONADO** (novo), não de **metadata MODIFICADO** (existente).

Para rollback de modificações, ele precisaria:
1. Salvar o metadata recuperado no diretório `metadata/`
2. Gerar recovery-package.xml com o metadata a restaurar
3. No rollback, fazer deploy desse metadata antigo

**Mas isso não está implementado!** 😢

---

## 📊 Cenários de Teste

| Cenário | Backup Funciona? | Rollback Funciona? | Notas |
|---------|------------------|-------------------|-------|
| **Adicionar novo metadata** | ✅ Sim | ⚠️ Parcial | Destructive changes tenta deletar (pode falhar) |
| **Modificar metadata existente** | ✅ Sim | ❌ **NÃO** | **Recovery package vazio!** |
| **Deletar metadata** | ✅ Sim | ⚠️ Parcial | Tentaria re-criar (se tivesse o arquivo) |

---

## 🔧 O Que Você Pode Fazer?

### Opção 1: Rollback Manual ✅ RECOMENDADO

```bash
# 1. Desfazer mudanças localmente (Git)
git checkout <commit-anterior>

# 2. Deploy da versão anterior
sf project deploy start --manifest manifest/package.xml --target-org backup-test
```

### Opção 2: Usar Git como Backup

```bash
# Antes de fazer mudanças:
git add .
git commit -m "Estado antes de mudanças"

# Depois das mudanças, se quiser voltar:
git revert HEAD
# ou
git reset --hard HEAD~1

# Deploy da versão anterior
sf project deploy start --manifest manifest/package.xml
```

### Opção 3: Backup Manual dos Arquivos

```bash
# ANTES de fazer mudanças:
mkdir -p manual-backup
cp -r force-app/main/default/classes manual-backup/

# Para restaurar:
cp -r manual-backup/classes force-app/main/default/
sf project deploy start --manifest manifest/package.xml
```

---

## 💡 Recomendação Para o Plugin

Para que o rollback funcione para modificações, o plugin deveria:

### 1. Durante o Backup (`create.ts`):

```typescript
// Após sf project retrieve
const retrieveResult = await retrieveCommand.run();

// ADICIONAR: Salvar arquivos recuperados
const sourcePath = '<temp-retrieve-dir>';
const backupMetadataPath = path.join(backupDir, 'metadata');
fs.cpSync(sourcePath, backupMetadataPath, { recursive: true });

// ADICIONAR: Gerar recovery package com metadata recuperado
const recoveryPackage = generatePackageFromFiles(backupMetadataPath);
fs.writeFileSync(recoveryPackagePath, recoveryPackage);
```

### 2. Durante o Rollback (`rollback.ts`):

```typescript
// Se recovery package não estiver vazio:
if (hasRecoveryMetadata) {
  // Deploy do metadata antigo (restaurar)
  await deployCommand.run([
    '--manifest', recoveryPackagePath,
    '--source-dir', backupMetadataPath,
    '--target-org', targetOrg
  ]);
}

// Depois, remover metadata novo (se houver)
if (hasDestructiveChanges) {
  await deployCommand.run([
    '--manifest', 'destructive/package.xml',
    '--post-destructive-changes', 'destructive/destructiveChanges.xml'
  ]);
}
```

---

## 📚 Documentação Adicional

- [ENTENDENDO_ROLLBACK.md](ENTENDENDO_ROLLBACK.md) - Como rollback deveria funcionar
- [ERRO_DIRNAME.md](ERRO_DIRNAME.md) - Erro resolvido no plugin
- [ROLLBACK_LIMITATIONS.md](../ROLLBACK_LIMITATIONS.md) - Limitações conhecidas

---

## ✅ Conclusão

### Para Seu Uso Atual:

1. **NÃO confie no rollback automático** do plugin para modificações
2. **Use Git** como sua principal ferramenta de backup
3. **Use o plugin** apenas para:
   - Documentar o estado da org
   - Gerar destructive changes (para metadata novo)
   - Backup de metadados complexos

### O Que Funciona:
- ✅ Criar backup (documentação)
- ✅ Listar backups
- ⚠️ Rollback de metadata **adicionado** (limitado)

### O Que NÃO Funciona:
- ❌ Rollback de metadata **modificado**
- ❌ Restaurar versões antigas de arquivos

---

## 🎯 Workflow Recomendado

```bash
# 1. ANTES de mudanças: Commit no Git
git add .
git commit -m "Before changes"

# 2. OPCIONAL: Criar backup para documentação
sf backup create --target-org my-org --manifest manifest/package.xml

# 3. Fazer mudanças e deploy
# ... modificar arquivos ...
sf project deploy start --manifest manifest/package.xml

# 4. Se der problema: Rollback via Git
git reset --hard HEAD~1
sf project deploy start --manifest manifest/package.xml
```

---

*Documento criado: 16 de Outubro de 2025*  
*Baseado em testes práticos do plugin*  
*Status: **LIMITAÇÃO CONFIRMADA***

