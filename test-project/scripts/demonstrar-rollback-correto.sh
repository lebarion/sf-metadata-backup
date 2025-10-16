#!/bin/bash

################################################################
# Demonstração de Fluxo CORRETO de Backup/Rollback
# 
# Este script demonstra o uso correto do sistema de backup:
# 1. Criar backup ANTES de fazer mudanças
# 2. Fazer mudanças
# 3. Deploy das mudanças
# 4. Rollback (restaura o estado do backup)
################################################################

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ORG_ALIAS="backup-test"
TEST_FILE="force-app/main/default/classes/AccountService.cls"

echo "════════════════════════════════════════════════════════════"
echo "  Demonstração: Fluxo CORRETO de Backup/Rollback"
echo "════════════════════════════════════════════════════════════"
echo ""

################################################################
# PASSO 1: Verificar estado atual
################################################################
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PASSO 1: Verificando estado LIMPO (sem mudanças)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Arquivo atual (linhas 10-15):"
sed -n '10,15p' "$TEST_FILE"
echo ""
read -p "Pressione ENTER para criar backup do estado limpo..."
echo ""

################################################################
# PASSO 2: Criar backup ANTES de fazer mudanças
################################################################
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}PASSO 2: Criando BACKUP do estado LIMPO (SEM mudanças)${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
sf backup create --target-org "$ORG_ALIAS" --manifest manifest/package.xml

# Capturar o diretório do backup mais recente
BACKUP_DIR=$(ls -td backups/backup_* 2>/dev/null | head -1)
echo ""
echo -e "${GREEN}✅ Backup criado: $BACKUP_DIR${NC}"
echo ""
read -p "Pressione ENTER para fazer mudança no código..."
echo ""

################################################################
# PASSO 3: Fazer mudança no código
################################################################
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASSO 3: Fazendo MUDANÇA no código${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Adicionando System.debug() no getAllAccounts()..."

# Fazer a mudança: adicionar debug no método getAllAccounts
sed -i '' '/public static List<Account> getAllAccounts()/a\
        System.debug('\''getAllAccounts - TESTE DE ROLLBACK'\'');' "$TEST_FILE"

echo ""
echo "Arquivo modificado (linhas 10-15):"
sed -n '10,15p' "$TEST_FILE"
echo ""
read -p "Pressione ENTER para fazer deploy da mudança..."
echo ""

################################################################
# PASSO 4: Deploy da mudança
################################################################
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PASSO 4: Fazendo DEPLOY da mudança${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
sf project deploy start --manifest manifest/package.xml --target-org "$ORG_ALIAS" --wait 10

echo ""
echo -e "${GREEN}✅ Deploy concluído! Org agora tem a mudança (System.debug)${NC}"
echo ""
echo "Estado atual na ORG: COM mudança"
echo "Estado no BACKUP: SEM mudança (limpo)"
echo ""
read -p "Pressione ENTER para fazer ROLLBACK..."
echo ""

################################################################
# PASSO 5: Rollback usando o backup
################################################################
echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}PASSO 5: Fazendo ROLLBACK (restaurando estado limpo)${NC}"
echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Usando backup: $BACKUP_DIR"
echo ""
sf backup rollback --target-org "$ORG_ALIAS" --backup-dir "$BACKUP_DIR" --no-confirm

echo ""
echo -e "${GREEN}✅ Rollback concluído!${NC}"
echo ""
echo "A org deveria estar de volta ao estado LIMPO (sem System.debug)"
echo ""
read -p "Pressione ENTER para verificar o resultado..."
echo ""

################################################################
# PASSO 6: Verificar resultado
################################################################
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PASSO 6: Verificando resultado do rollback${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Recuperando AccountService da org..."
sf project retrieve start --metadata "ApexClass:AccountService" --target-org "$ORG_ALIAS" --wait 10

echo ""
echo "Arquivo recuperado da ORG (linhas 10-15):"
sed -n '10,15p' "$TEST_FILE"
echo ""

# Verificar se o System.debug foi removido
if grep -q "System.debug('getAllAccounts - TESTE DE ROLLBACK')" "$TEST_FILE"; then
    echo -e "${RED}❌ FALHA: System.debug ainda está presente! Rollback não funcionou.${NC}"
    echo ""
    echo "Possíveis causas:"
    echo "1. Backup foi criado DEPOIS da mudança (não ANTES)"
    echo "2. Recovery package estava vazio"
    echo "3. Erro no processo de rollback"
else
    echo -e "${GREEN}✅ SUCESSO: System.debug foi removido! Rollback funcionou perfeitamente!${NC}"
    echo ""
    echo "O arquivo está de volta ao estado LIMPO do backup."
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Demonstração Concluída!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Resumo do fluxo CORRETO:"
echo "1. ✅ Backup ANTES de mudanças"
echo "2. ✅ Fazer mudanças"
echo "3. ✅ Deploy das mudanças"
echo "4. ✅ Rollback quando necessário"
echo ""
echo "Backup usado: $BACKUP_DIR"
echo ""

