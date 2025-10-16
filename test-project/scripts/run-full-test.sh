#!/bin/bash

###############################################################################
# Full End-to-End Test for SF Backup Plugin
# 
# This script runs a complete test cycle:
# 1. Deploys initial metadata
# 2. Creates backup
# 3. Makes changes to metadata
# 4. Deploys changes
# 5. Rolls back changes
# 6. Verifies rollback success
#
# Usage: ./scripts/run-full-test.sh [org-alias]
# Default org alias: backup-test
###############################################################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ORG_ALIAS="${1:-backup-test}"
TEST_MODE="${2:-standard}"  # standard or orgdevmode

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  SF Backup Plugin - Full Test Cycle${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Org:${NC} $ORG_ALIAS"
echo -e "${BLUE}Mode:${NC} $TEST_MODE"
echo ""

# Verify org exists
echo -e "${YELLOW}[1/8] Verifying target org...${NC}"
if ! sf org display --target-org "$ORG_ALIAS" &> /dev/null; then
    echo -e "${RED}✗ Org '$ORG_ALIAS' not found${NC}"
    echo "Run: ./scripts/setup-test-org.sh $ORG_ALIAS"
    exit 1
fi
echo -e "${GREEN}✓ Org verified${NC}"
echo ""

# Set manifest path
if [ "$TEST_MODE" = "orgdevmode" ]; then
    MANIFEST="manifest/buildfile.json"
    echo -e "${YELLOW}Using OrgDevMode with buildfile.json${NC}"
    
    # Check if plugin installed
    if ! sf plugins | grep -q "sf-orgdevmode-builds"; then
        echo -e "${YELLOW}Installing sf-orgdevmode-builds plugin...${NC}"
        sf plugins install sf-orgdevmode-builds
    fi
else
    MANIFEST="manifest/package.xml"
    echo -e "${YELLOW}Using standard mode with package.xml${NC}"
fi
echo ""

# Deploy initial state
echo -e "${YELLOW}[2/8] Deploying initial metadata state...${NC}"
if [ "$TEST_MODE" = "orgdevmode" ]; then
    sf builds deploy -b "$MANIFEST" -u "$ORG_ALIAS"
else
    sf project deploy start --manifest "$MANIFEST" --target-org "$ORG_ALIAS"
fi
echo -e "${GREEN}✓ Initial deployment complete${NC}"
echo ""

# Create backup
echo -e "${YELLOW}[3/8] Creating backup...${NC}"
sf backup create --target-org "$ORG_ALIAS" --manifest "$MANIFEST"
BACKUP_DIR=$(ls -td backups/backup_* | head -1)
echo -e "${GREEN}✓ Backup created: $BACKUP_DIR${NC}"
echo ""

# Make changes
echo -e "${YELLOW}[4/8] Making test changes to metadata...${NC}"
echo "Backing up original files..."
cp force-app/main/default/classes/AccountService.cls force-app/main/default/classes/AccountService.cls.backup

echo "Copying modified version..."
cp test-scenarios/modified-files/AccountService_v2.cls force-app/main/default/classes/AccountService.cls
echo -e "${GREEN}✓ Changes prepared${NC}"
echo ""

# Deploy changes
echo -e "${YELLOW}[5/8] Deploying modified metadata...${NC}"
if [ "$TEST_MODE" = "orgdevmode" ]; then
    sf builds deploy -b "$MANIFEST" -u "$ORG_ALIAS"
else
    sf project deploy start --manifest "$MANIFEST" --target-org "$ORG_ALIAS"
fi
echo -e "${GREEN}✓ Changes deployed${NC}"
echo ""

# Verify changes deployed
echo -e "${YELLOW}[6/8] Verifying changes were deployed...${NC}"
echo "Retrieving AccountService from org..."
mkdir -p .test-retrieve
sf project retrieve start \
    --manifest manifest/phase1-classes.xml \
    --target-org "$ORG_ALIAS" \
    --target-metadata-dir .test-retrieve

if grep -q "getAccountsByIndustry" .test-retrieve/classes/AccountService.cls; then
    echo -e "${GREEN}✓ Changes confirmed in org${NC}"
else
    echo -e "${RED}✗ Changes not found in org${NC}"
    exit 1
fi
echo ""

# Rollback
echo -e "${YELLOW}[7/8] Rolling back to original state...${NC}"
sf backup rollback --target-org "$ORG_ALIAS" --backup-dir "$BACKUP_DIR" --no-confirm
echo -e "${GREEN}✓ Rollback executed${NC}"
echo ""

# Verify rollback
echo -e "${YELLOW}[8/8] Verifying rollback success...${NC}"
echo "Retrieving AccountService again..."
rm -rf .test-retrieve
mkdir -p .test-retrieve
sf project retrieve start \
    --manifest manifest/phase1-classes.xml \
    --target-org "$ORG_ALIAS" \
    --target-metadata-dir .test-retrieve

if grep -q "getAccountsByIndustry" .test-retrieve/classes/AccountService.cls; then
    echo -e "${RED}✗ Rollback FAILED - changes still present${NC}"
    ROLLBACK_SUCCESS=false
else
    echo -e "${GREEN}✓ Rollback SUCCESS - original state restored${NC}"
    ROLLBACK_SUCCESS=true
fi
echo ""

# Cleanup
echo -e "${YELLOW}Cleaning up test artifacts...${NC}"
mv force-app/main/default/classes/AccountService.cls.backup force-app/main/default/classes/AccountService.cls
rm -rf .test-retrieve
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Summary
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Test Summary${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Test Mode:${NC} $TEST_MODE"
echo -e "${BLUE}Backup Directory:${NC} $BACKUP_DIR"
echo ""
echo -e "${BLUE}Results:${NC}"
echo -e "  Initial Deploy:  ${GREEN}✓ Success${NC}"
echo -e "  Backup Created:  ${GREEN}✓ Success${NC}"
echo -e "  Changes Deploy:  ${GREEN}✓ Success${NC}"
echo -e "  Changes Verify:  ${GREEN}✓ Success${NC}"

if [ "$ROLLBACK_SUCCESS" = true ]; then
    echo -e "  Rollback:        ${GREEN}✓ SUCCESS${NC}"
else
    echo -e "  Rollback:        ${RED}✗ FAILED${NC}"
fi

echo ""
echo -e "${BLUE}Backup Contents:${NC}"
ls -lh "$BACKUP_DIR"
echo ""

if [ "$ROLLBACK_SUCCESS" = true ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Rollback test failed${NC}"
    echo "Check logs at: $BACKUP_DIR/backup.log"
    exit 1
fi

